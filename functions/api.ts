// WalletWave backend.
//
// This is the only place that holds server secrets. Neon injects DATABASE_URL,
// NEON_AUTH_*, AWS_* (and the realtime values) into the function at runtime, so
// nothing here is ever shipped to the desktop app.
//
// Routes:
//   GET  /health                  which capabilities exist (no secrets)
//   POST /storage/upload-url      presigned PUT for backups/<user id>.json
//   POST /storage/download-url    presigned GET for the same key
//   POST /realtime/ticket         sealed live query scoped to the caller
//
// Every non-health route requires `Authorization: Bearer <Neon Auth JWT>`.

import { GetObjectCommand, PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { createRealtime, pgParam, rawSql } from "@neon/realtime/server";
import { createRemoteJWKSet, jwtVerify } from "jose";

const BUCKET = process.env.BACKUP_BUCKET ?? "uploads";
const SIGNED_URL_SECONDS = 300;

class HttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function databaseName(): string {
  const url = process.env.DATABASE_URL;
  if (!url) throw new HttpError(503, "DATABASE_URL is not configured.");
  return new URL(url).pathname.replace(/^\//, "") || "neondb";
}

// Clients created once per isolate and reused across requests.
let s3Client: S3Client | undefined;
function s3(): S3Client {
  if (!s3Client) {
    if (!process.env.AWS_ENDPOINT_URL_S3) {
      throw new HttpError(503, "Object Storage is not configured on the server.");
    }
    s3Client = new S3Client({
      // Neon Object Storage speaks path-style S3 addressing; without this the
      // client builds https://<bucket>.<endpoint>, which does not exist.
      forcePathStyle: true,
      region: process.env.AWS_REGION,
      endpoint: process.env.AWS_ENDPOINT_URL_S3,
    });
  }
  return s3Client;
}

let jwks: ReturnType<typeof createRemoteJWKSet> | undefined;
let issuer: string | undefined;
function authVerifier(): { jwks: ReturnType<typeof createRemoteJWKSet>; issuer: string } {
  if (!jwks || !issuer) {
    const base = process.env.NEON_AUTH_BASE_URL;
    const jwksUrl = process.env.NEON_AUTH_JWKS_URL;
    if (!base || !jwksUrl) {
      throw new HttpError(503, "Neon Auth is not configured on the server.");
    }
    // Tokens are issued with the origin as both `iss` and `aud`.
    issuer = new URL(base).origin;
    jwks = createRemoteJWKSet(new URL(jwksUrl));
  }
  return { jwks, issuer };
}

async function requireUserId(request: Request): Promise<string> {
  const header = request.headers.get("authorization");
  const token = header?.toLowerCase().startsWith("bearer ")
    ? header.slice("bearer ".length)
    : undefined;
  if (!token) throw new HttpError(401, "Missing bearer token.");

  try {
    const verifier = authVerifier();
    const { payload } = await jwtVerify(token, verifier.jwks, {
      issuer: verifier.issuer,
      audience: verifier.issuer,
    });
    if (!payload.sub) throw new Error("token has no subject");
    return payload.sub;
  } catch {
    throw new HttpError(401, "Invalid or expired token.");
  }
}

let realtimeServer: ReturnType<typeof createRealtime> | undefined;
function realtime(): ReturnType<typeof createRealtime> {
  if (!realtimeServer) {
    const secret = process.env.WALLETWAVE_REALTIME_SECRET;
    if (!secret) {
      throw new HttpError(503, "Realtime is not configured on the server.");
    }
    realtimeServer = createRealtime({ secret, db: databaseName() });
  }
  return realtimeServer;
}

async function handle(request: Request): Promise<Response> {
  const url = new URL(request.url);
  const path = url.pathname;

  if (request.method === "GET" && path.endsWith("/health")) {
    return json({
      ok: true,
      database: Boolean(process.env.DATABASE_URL),
      auth: Boolean(process.env.NEON_AUTH_BASE_URL && process.env.NEON_AUTH_JWKS_URL),
      storage: Boolean(process.env.AWS_ENDPOINT_URL_S3 && process.env.AWS_ACCESS_KEY_ID),
      realtimeSecret: Boolean(process.env.WALLETWAVE_REALTIME_SECRET),
      bucket: BUCKET,
    });
  }

  if (request.method !== "POST") {
    throw new HttpError(405, "Use POST for this endpoint.");
  }

  const userId = await requireUserId(request);
  // The object key never comes from the client, so a user cannot ask to read or
  // overwrite someone else's backup.
  const key = `backups/${userId}.json`;

  if (path.endsWith("/storage/upload-url")) {
    const command = new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      ContentType: "application/json",
    });
    return json({
      url: await getSignedUrl(s3(), command, { expiresIn: SIGNED_URL_SECONDS }),
      key,
      expiresIn: SIGNED_URL_SECONDS,
    });
  }

  if (path.endsWith("/storage/download-url")) {
    const command = new GetObjectCommand({ Bucket: BUCKET, Key: key });
    return json({
      url: await getSignedUrl(s3(), command, { expiresIn: SIGNED_URL_SECONDS }),
      key,
      expiresIn: SIGNED_URL_SECONDS,
    });
  }

  if (path.endsWith("/realtime/ticket")) {
    // Realtime refuses tables with RLS. `saved_wallets_events` has none, and
    // this query is filtered to the verified user id before sealing, so the
    // capability can only ever see the caller's own change rows.
    const query = rawSql(
      `SELECT id, op, changed_at FROM public.saved_wallets_events
       WHERE user_id = $1 ORDER BY id DESC LIMIT 20`,
      [pgParam.text("uuid", userId)],
    );
    const sealed = await realtime().seal({ query });
    return json(sealed);
  }

  throw new HttpError(404, "Unknown endpoint.");
}

export default {
  async fetch(request: Request): Promise<Response> {
    try {
      return await handle(request);
    } catch (error) {
      if (error instanceof HttpError) {
        return json({ error: error.message }, error.status);
      }
      console.error("[api]", error);
      return json({ error: "Unexpected server error." }, 500);
    }
  },
};
