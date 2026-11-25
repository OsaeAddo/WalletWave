# WalletWave — Project Context & Status

This document describes what the repository **actually contains today**. It is
corrected whenever a milestone lands. Anything not listed under "Implemented" does
not exist yet, even if it appears in older notes.

## 1. Purpose and scope

WalletWave is a Flutter crypto app with two working domains:

- **Markets** — fetch top coins from CoinGecko, cache them in Isar, stream live
  prices from Binance, search by name or symbol.
- **Portfolio** — query the native balance of an EVM address over JSON-RPC.
- **Auth + sync** — optional email/password sign-in through Neon Auth, syncing
  saved wallets to Postgres through the Data API, protected by Row Level
  Security, with a Realtime change feed and a private Object Storage backup.

**Supported target: Linux desktop only.** The Android/iOS/web/macOS/Windows folders
are Flutter scaffolding and are not built or tested.

Repository: `github.com/OsaeAddo/WalletWave` (branch `main`).

## 2. Status matrix

Each row names the file that proves the claim.

| Area | Status | Evidence |
|---|---|---|
| App bootstrap + Isar init | Done | `lib/main.dart`, `lib/src/core/database/isar_provider.dart` |
| Dio client + logging | Done | `lib/src/core/network/dio_provider.dart`, `logging_interceptor.dart` |
| Auth token interceptor | Done | `lib/src/core/network/auth_interceptor.dart` (registered on the Neon Data API client) |
| Market REST + Isar cache | Done | `lib/src/features/market/data/market_repository.dart` |
| Market live prices (WS) | Done, one known reconnect bug | `lib/src/features/market/data/market_price_ws_provider.dart` |
| Market search/filter | Done | `lib/src/features/market/presentation/market_dashboard_screen.dart` |
| EVM native balance | Done | `lib/src/features/portfolio/data/evm_client_service.dart` |
| EVM ERC-20 balance | Done | `evm_client_service.dart` `getErc20Balance`, `ethereum_token.dart` |
| Portfolio screen | Done (native + tracked ERC-20 balances) | `portfolio_screen.dart`, `portfolio_providers.dart` |
| Navigation shell (tabs) | Done | `lib/src/core/router/app_shell.dart`, `app_router.dart` |
| Auth domain | Done (Neon Auth email/password) | `features/auth/`, `neon_auth_repository.dart`, `auth_providers.dart` |
| Saved wallets / nicknames | Done, local + optional cloud sync | `saved_wallet_repository.dart`, `saved_wallets_remote.dart`, `neon_saved_wallets_remote.dart` |
| Account UI + backup/restore | Done | `features/auth/presentation/account_screen.dart` |
| Cloud schema + RLS | Done | `neon/migrations/0001_saved_wallets.sql` |
| Realtime change feed | Done (experimental Neon Realtime, hand-written Dart client) | `neon_realtime_client.dart`, `saved_wallets_realtime.dart` |
| Object Storage backup | Done (presigned upload/download) | `wallet_backup_service.dart`, `functions/api.ts` |
| Multi-chain switching | **Missing** | single Ethereum mainnet RPC only |
| Custom tokens / user-added metadata | **Missing** | tokens come from the static `kEthereumErc20Tokens` list; no add-token UI |
| Portfolio fiat valuation | **Missing** | market and portfolio not joined |

There is **no** `EVMWalletEntity`, `EvmNetwork`, `AddCustomTokenDialog`, or
custom-token notifier in this repository. Saved wallets use
`SavedWalletEntity`; token metadata exists only as the static
`kEthereumErc20Tokens` list.

Auth covers email/password only: no OAuth, magic links, or deep-link handling on
Linux. `AuthInterceptor` adds the Neon JWT to the Data API and function clients;
it is never registered on the public CoinGecko client.

## 3. Architecture

Feature-first, three layers per feature:

```
lib/
├── main.dart                     # ensureInitialized, initIsar, ProviderScope
└── src/
    ├── core/
    │   ├── config/               # NeonConfig (--dart-define), client provider
    │   ├── database/             # isarProvider (overridden in main)
    │   ├── network/              # dioProvider, interceptors, ApiException
    │   └── router/               # goRouterProvider, AppShell (bottom tabs)
    └── features/
        ├── auth/
        │   ├── application/      # authRepository/authState/authController providers
        │   ├── data/             # NeonAuthRepository, DisabledAuthRepository,
        │   │                     # NeonSessionStore (OS keyring, memory fallback)
        │   ├── domain/           # AuthUser, AuthRepository, AuthException
        │   └── presentation/     # AccountScreen, AuthActionButton
        ├── market/
        │   ├── application/      # marketCoinsProvider, search/filter providers
        │   ├── data/             # repository, Isar entity + mapper, WS provider
        │   ├── domain/           # MarketCoin (Freezed)
        │   └── presentation/     # MarketDashboardScreen
        └── portfolio/
            ├── application/      # portfolioProvider, savedWalletsProvider,
            │                     # realtime feed, backup provider
            ├── data/             # EvmClientService, saved-wallet repository + Isar
            │                     # entity, Neon Data API, Realtime client, backup
            ├── domain/           # PortfolioSnapshot, TokenBalance, SavedWallet, token list
            └── presentation/     # PortfolioScreen

functions/api.ts                  # server secrets only here: JWT verify, S3, sealing
neon/migrations/                  # schema, RLS, change feed, trigger
neon.ts                           # backend services declared as code
```

**Dependency rule:** `presentation → application → data/domain`. Providers live in
`application/`, never in widget files.

## 4. Dependencies and why

| Package | Role |
|---|---|
| `flutter_riverpod` | State management and DI |
| `go_router` | Declarative routing |
| `dio` | REST client for CoinGecko (also used by `MarketRepository`) |
| `http` | HTTP transport passed into `Web3Client` |
| `web_socket_channel` | Binance ticker stream and the Neon Realtime client |
| `isar_community` + `isar_community_flutter_libs` | Local persistence, native libs |
| `path_provider` | Isar directory |
| `web3dart` | EVM JSON-RPC client: `Web3Client`, contracts, ABI |
| `wallet` | `EtherAmount`, `EtherUnit`, `EthereumAddress` (web3dart 3.x value types) |
| `flutter_secure_storage` | Session storage: Neon Auth session cookie in the OS keyring |
| `jose` (npm) | Function-side JWT verification against Neon's JWKS |
| `@aws-sdk/client-s3` + presigner (npm) | Function-side presigned backup URLs |
| `@neon/realtime` (npm) | Server-side sealing of the filtered live query |
| `freezed` / `freezed_annotation` / `json_serializable` | Immutable models |
| `build_runner` / `isar_community_generator` | Code generation |
| `mocktail`, `http/testing.dart` | Test doubles |

**Freezed v3:** generated models use `@freezed abstract class X with _$X`.
Without `abstract`, the analyzer demands the mixin's abstract members on the outer
class.

## 5. Engineering decisions

- **Generated code is committed.** `*.g.dart` and `*.freezed.dart` are tracked so a
  fresh clone builds with only `flutter pub get`. Regenerate via `build_runner` and
  commit the result; never hand-edit generated files.
- **One Dio per upstream.** `dioProvider` is bound to CoinGecko's base URL and is
  public: it must not carry user credentials. Authenticated backend calls get
  their own client (`neonDataApiClientProvider`) with `AuthInterceptor`; that
  client is used only for the Neon Data API and functions.
- **Auth is an interface, not an import.** Screens and providers depend on
  `AuthRepository`, never on a vendor SDK. A FastAPI backend means one new
  repository implementation plus one override in `main.dart`.
- **Auth is optional at build time.** Missing `--dart-define` values select
  `DisabledAuthRepository`; the app starts and works fully offline.
- **Local data is the source of truth.** Saved wallets live in Isar first. Cloud
  merge runs on sign-in, and cloud writes are best effort so an offline save never
  fails because of the network.
- **Ownership is enforced by the database.** `saved_wallets` uses RLS with
  `auth.uid() = user_id`, and `user_id` defaults to `auth.uid()`, so client code
  cannot write rows for another user even if it tried.
- **Realtime is only a notification channel.** Neon Realtime refuses RLS tables,
  so `saved_wallets_events` is an RLS-free, trigger-written change feed. The
  function bakes `WHERE user_id = <verified sub>` into the sealed query before
  sending the capability. The app reacts by re-reading wallets through the Data
  API, where RLS still applies.
- **Secrets never enter the Flutter binary.** `tool/flutter-env.sh` copies only
  the four public URLs into `.env.flutter`. The realtime secret, `DATABASE_URL`
  and AWS keys exist only in `.env.local` and the deployed function.
- **The object key comes from the verified JWT subject.** A client cannot ask for
  a URL to someone else's backup because it never names the key.
- **Analyzer excludes generated and platform folders.** Keeps the signal on
  hand-written code. Stricter lints (`strict-casts`, `require_trailing_commas`,
  `unawaited_futures`) are intentionally deferred to milestones that touch the code.
- **Tests run serially** (`flutter test -j 1`) because Isar uses a native database.
  The default suite is offline; `tool/e2e/neon_sync_e2e_test.dart` is the explicit
  real-backend check.

## 6. Known issues

None of the original P0 issues remain: the market client no longer sends auth
tokens, market refresh no longer loops, and the WebSocket stops reconnecting after
disposal.

| Issue | Milestone |
|---|---|
| WS reconnect uses a fixed 5s delay instead of backoff | later |
| ERC-20 list is static; unknown tokens are not displayed | later (custom tokens) |
| Cloud sync merges labels with "cloud wins"; no per-row timestamps | later |
| Neon Realtime is an experimental service; the Dart client is hand-written | monitor |
| No fiat valuation joining market and portfolio | M6 |
| No password reset or email-reset UI beyond Neon Auth defaults | later |
| No OAuth / deep links (deliberate on Linux desktop) | later |
| `libsecret` and a keyring are required to stay signed in on Linux | documented in README |

## 7. How to run and verify

```bash
flutter pub get
flutter run -d linux               # dev run (signed out)
flutter analyze                    # must be clean
flutter test -j 1                  # serial because of Isar; no network needed
dart run build_runner build        # after changing generated models

npm install                        # first time only
npm run build                      # tsc --noEmit + flutter build linux --debug
npm run build:sync                 # same, with the public Neon URLs compiled in
```

Cloud sync needs `.env.flutter` from `tool/flutter-env.sh`, the Neon services in
`neon.ts`, and the schema in `neon/migrations/0001_saved_wallets.sql`; see README
"Cloud sync (optional)". The real end-to-end check is:

```bash
NEON_E2E_EMAIL=... NEON_E2E_PASSWORD=... \
  flutter test tool/e2e/neon_sync_e2e_test.dart
```

## 8. Roadmap

| Milestone | Goal |
|---|---|
| **M0** | ✅ Green build, committed generated code, analyzer scope, docs |
| **M1** | ✅ Bottom-navigation shell (Markets / Portfolio), providers moved to `application/` |
| **M2** | ✅ Fixed P0 bugs: token leak, refresh loop, WS reconnect |
| **M3** | ✅ Portfolio shows native balance plus tracked ERC-20 holdings |
| **M4** | ✅ Saved wallets persisted in Isar, selectable from the portfolio screen |
| **M5** | ✅ Optional Neon auth; RLS-scoped sync, live change feed, private Object Storage backup |
| **M6** | Portfolio valuation, hardening, strict lints |
