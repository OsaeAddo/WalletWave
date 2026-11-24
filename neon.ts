import { defineConfig } from "@neon/config/v1";

export default defineConfig({
  dataApi: true,
  functions: {
    api: {
      name: "api",
      source: "./functions/api.ts",
      env: {
        // Neon does not inject the Realtime secret into functions, so it is
        // passed explicitly at deploy time from .env.local. `NEON_` names are
        // reserved, hence the project-specific name.
        WALLETWAVE_REALTIME_SECRET: {
          value: process.env.NEON_REALTIME_SECRET,
          required: true,
        },
      },
    },
  },
  // Declare your Neon services here
  preview: {
    realtime: true,
  },
  auth: true,
  buckets: {
    // Wallet backup JSON per user. Private: only presigned URLs from the
    // `api` function can read or write. The branch already has this bucket.
    uploads: { access: "private" },
  },
  // Branch policy: per-branch tuning
  branch: (branch) => {
    if (branch.isDefault) {
      // Default branch: no overrides, uses project defaults
      return {};
    }
    if (!branch.exists) {
      // New non-default branches: auto-expire
      // Run `neon checkout <name>` to create a new branch with these settings
      return { ttl: "7d" };
    }
    // Existing branch: no changes
    return {};
  },
});
