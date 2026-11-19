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
- **Optional cloud sync** — sign in with email and password (Supabase) to sync
  saved wallets across machines. The app works fully signed out and offline;
  signing in only adds sync.

## Project layout

```
lib/
├── main.dart                       # ProviderScope + Isar initialization
└── src/
    ├── core/                       # Shared infrastructure
    │   ├── config/                 # Supabase keys + client provider
    │   ├── database/               # Isar instance provider
    │   ├── network/                # Dio client and interceptors
    │   └── router/                 # GoRouter plus AppShell (bottom tabs)
    └── features/                   # Feature-first boundaries
        ├── auth/
        │   ├── application/        # authRepository/authState/authController providers
        │   ├── data/               # Supabase + disabled repositories, session storage
        │   ├── domain/             # AuthUser, AuthRepository, friendly error mapping
        │   └── presentation/       # AccountScreen, app-bar account button
        ├── market/
        │   ├── application/        # Market providers
        │   ├── data/               # MarketRepository, Isar entities, WebSocket
        │   ├── domain/             # MarketCoin model
        │   └── presentation/       # Market dashboard UI
        └── portfolio/
            ├── application/        # Portfolio and saved-wallet providers
            ├── data/               # EvmClientService, saved-wallet repository
            ├── domain/             # PortfolioSnapshot, TokenBalance, SavedWallet
            └── presentation/       # Portfolio UI
```

Dependency rule: `presentation` → `application` → `data`/`domain`.
Providers and business logic live under `application/`, never inside widgets.

## Cloud sync (optional)

Sign-in is off unless you build with a Supabase project URL and key:

```bash
flutter run -d linux \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-OR-PUBLISHABLE-KEY
```

Without those values the app starts normally and the account screen explains
that cloud sync is not configured.

One-time backend setup:

1. Create a project at [supabase.com](https://supabase.com).
2. Open the SQL editor and run `supabase/migrations/0001_saved_wallets.sql`.
   That creates the `saved_wallets` table and the Row Level Security policies
   that scope every row to its owner.
3. Optionally disable "Confirm email" under Authentication → Providers → Email
   while developing, so sign-up can be tested without an inbox.

How sync behaves:

- Isar stays the local cache and the list you see. The cloud is merged in on
  sign-in: local-only wallets are uploaded, cloud wallets are downloaded.
- When the same wallet exists in both places, the cloud label wins.
- Cloud writes are best effort. If the network is down the save still succeeds
  locally and syncs on the next sign-in.
- Sessions are kept in the OS keyring through `flutter_secure_storage`. On Linux
  that needs `libsecret` plus a running keyring (GNOME Keyring or KWallet). If
  the keyring is unavailable the session is kept in memory and you sign in again
  next launch.

## Requirements

- Flutter (Dart SDK `>=3.0.0 <4.0.0`)
- Linux desktop toolchain (`flutter doctor` should pass the Linux check)
- `libsecret-1-dev` for secure session storage on Linux
  (`sudo apt install libsecret-1-dev`)

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
flutter test -j 1
```

Tests run with a single worker (`-j 1`) because Isar opens a native database per
test file and tests initialize Isar core on first run. Tests never touch the
network: auth and cloud sync are replaced with fakes, and no Supabase keys are
needed.
