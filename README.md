# WalletWave

An offline-first crypto market tracker and EVM portfolio viewer built with Flutter.

WalletWave fetches live market data, caches it locally so the app works without a
network, streams live prices over a WebSocket, and reads on-chain wallet balances
through a raw EVM JSON-RPC client.

**Current target:** Linux desktop. Android/iOS/web are scaffolded but not supported yet.

## Features

- **Markets** — top coins from CoinGecko, cached in Isar, refreshed in the background,
  searchable by name or symbol.
- **Live prices** — Binance mini-ticker WebSocket stream with row-level rebuilds.
- **Portfolio** — look up an EVM address and see its native ETH balance plus
  tracked ERC-20 holdings (USDC, USDT, DAI, LINK), all via JSON-RPC. Save wallets
  locally (Isar) and reload them with one tap.
- **Optional cloud sync** — sign in with email and password (Neon Auth) to sync
  saved wallets across machines. The app works fully signed out and offline;
  signing in only adds sync.
- **Cloud backup** — upload or restore a JSON copy of your wallet list through a
  private object-storage bucket, with links signed by a server function.

## Project layout

```
lib/
├── main.dart                       # ProviderScope + Isar initialization
└── src/
    ├── core/                       # Shared infrastructure
    │   ├── config/                 # Public Neon URLs (--dart-define)
    │   ├── database/               # Isar instance provider
    │   ├── network/                # Dio clients and interceptors
    │   └── router/                 # GoRouter plus AppShell (bottom tabs)
    └── features/                   # Feature-first boundaries
        ├── auth/
        │   ├── application/        # authRepository/authState/authController providers
        │   ├── data/               # Neon + disabled repositories, session storage
        │   ├── domain/             # AuthUser, AuthRepository, friendly error mapping
        │   └── presentation/       # AccountScreen, app-bar account button
        ├── market/
        │   ├── application/        # Market providers
        │   ├── data/               # MarketRepository, Isar entities, WebSocket
        │   ├── domain/             # MarketCoin model
        │   └── presentation/       # Market dashboard UI
        └── portfolio/
            ├── application/        # Portfolio, saved-wallet, realtime and backup providers
            ├── data/               # EVM client, Isar repository, Neon Data API,
            │                       # Realtime client, backup service
            ├── domain/             # PortfolioSnapshot, TokenBalance, SavedWallet
            └── presentation/       # Portfolio UI

functions/
└── api.ts                          # JWT-guarded function: storage URLs, realtime ticket

neon/
├── migrations/0001_saved_wallets.sql
└── (schema applied with `neon psql production -- -f …`)
```

The backend is declared as code in `neon.ts`: Neon Auth, the Data API, the
`uploads` bucket, Realtime, and the `api` function.

Dependency rule: `presentation` → `application` → `data`/`domain`.
Providers and business logic live under `application/`, never inside widgets.

## Cloud sync (optional)

The backend runs on [Neon](https://neon.com): Postgres, Neon Auth, a
PostgREST-compatible Data API, private Object Storage, experimental Realtime, and
one serverless function. Nothing secret ships in the app; the binary only gets
public URLs.

### Build with sync

```bash
bash tool/flutter-env.sh        # writes gitignored .env.flutter (4 public URLs)
flutter run -d linux --dart-define-from-file=.env.flutter
```

Without those values the app starts normally and the account screen explains
that cloud sync is not configured. `flutter build linux --debug` (no defines)
still produces a working offline app.

### Backend setup

Requires Node.js 20+ and the Neon CLI (`npx -y neon@latest`).

```bash
npx neon login
npx neon init                     # link or create the project
npx neon deploy -y --allow-protected --update-existing --env .env.local
npx neon psql production -- -f neon/migrations/0001_saved_wallets.sql
```

`neon deploy` provisions Auth, the Data API, the private `uploads` bucket, the
`api` function and the `saved_wallets` schema pieces declared in `neon.ts`; the
migration applies the tables, RLS policies and the change-feed trigger. The
function reads its secrets (`DATABASE_URL`, `AWS_*`, `WALLETWAVE_REALTIME_SECRET`)
from Neon's environment, never from Flutter.

### What the app does with it

| Path | Purpose |
|---|---|
| `features/auth/data/neon_auth_repository.dart` | Cookie session + cached 15-minute JWT |
| `features/portfolio/data/neon_saved_wallets_remote.dart` | Data API CRUD; RLS scopes rows by `auth.uid()` |
| `features/portfolio/data/neon_realtime_client.dart` | Hand-written Realtime protocol v2 client |
| `features/portfolio/data/wallet_backup_service.dart` | Presigned upload/download of `backups/<user id>.json` |

How sync behaves:

- Isar stays the local cache and the list you see. The cloud is merged in on
  sign-in: local-only wallets are uploaded, cloud wallets are downloaded.
- When the same wallet exists in both places, the cloud label wins.
- Cloud writes are best effort. If the network is down the save still succeeds
  locally and syncs on the next sign-in.
- A live feed notifies the app when another machine changes the wallet list. The
  change feed is RLS-free by design, so the function seals a query already
  filtered to the verified user id; the app never reads wallets through
  Realtime, it re-reads them through the Data API.
- **Backup** writes a versioned JSON file to the private bucket through a
  five-minute presigned URL. **Restore** merges it into this device and the cloud
  copy; it never deletes newer wallets.
- Sessions are kept in the OS keyring through `flutter_secure_storage`. On Linux
  that needs `libsecret` plus a running keyring (GNOME Keyring or KWallet). If
  the keyring is unavailable the session is kept in memory and you sign in again
  next launch.

### Secrets rule

`NEON_REALTIME_SECRET`, `DATABASE_URL`, AWS keys and the database password stay
in `.env.local` and the deployed function. `tool/flutter-env.sh` copies only the
four public URLs into `.env.flutter`, which is gitignored.

## Requirements

- Flutter (Dart SDK `>=3.0.0 <4.0.0`)
- Linux desktop toolchain (`flutter doctor` should pass the Linux check)
- `libsecret-1-dev` for secure session storage on Linux
  (`sudo apt install libsecret-1-dev`)
- Node.js 20+ only if you deploy the optional Neon backend

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d linux
```

Generated code (`*.g.dart`, `*.freezed.dart`) is committed, so a fresh clone builds
without running `build_runner`. Re-run it only after changing a `@freezed`,
`@JsonSerializable`, or Isar collection.

## Quality checks

```bash
flutter analyze
flutter test -j 1          # serial because of Isar
npm install                # once, for the backend typecheck
npm run build              # tsc --noEmit + flutter build linux --debug
npm run build:sync         # same, with the public Neon URLs compiled in
```

Tests run with a single worker (`-j 1`) because Isar opens a native database per
test file and tests initialize Isar core on first run. The default suite never
touches the network: auth, cloud sync, realtime and backup are replaced with
fakes.

The real backend is exercised separately:

```bash
bash tool/flutter-env.sh
NEON_E2E_EMAIL=... NEON_E2E_PASSWORD=... \
  flutter test tool/e2e/neon_sync_e2e_test.dart
```

It signs in with the real auth server, writes through the Data API, uploads and
downloads a backup, and waits for a Realtime event caused by its own insert. Use
a dedicated test account: the backup file is replaced with the test wallet list.
