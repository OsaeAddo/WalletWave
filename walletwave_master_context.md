# WalletWave — Project Context & Status

This document describes what the repository **actually contains today**. It is
corrected whenever a milestone lands. Anything not listed under "Implemented" does
not exist yet, even if it appears in older notes.

## 1. Purpose and scope

WalletWave is a Flutter crypto app with two working domains:

- **Markets** — fetch top coins from CoinGecko, cache them in Isar, stream live
  prices from Binance, search by name or symbol.
- **Portfolio** — query the native balance of an EVM address over JSON-RPC.
- **Auth + sync** — optional email/password sign-in through Supabase, syncing
  saved wallets to a Postgres table protected by Row Level Security.

**Supported target: Linux desktop only.** The Android/iOS/web/macOS/Windows folders
are Flutter scaffolding and are not built or tested.

Repository: `github.com/OsaeAddo/WalletWave` (branch `main`).

## 2. Status matrix

Each row names the file that proves the claim.

| Area | Status | Evidence |
|---|---|---|
| App bootstrap + Isar init | Done | `lib/main.dart`, `lib/src/core/database/isar_provider.dart` |
| Dio client + logging | Done | `lib/src/core/network/dio_provider.dart`, `logging_interceptor.dart` |
| Auth token interceptor | Scaffolding only | `lib/src/core/network/auth_interceptor.dart` (works, registered on no client; Supabase attaches its own header) |
| Market REST + Isar cache | Done | `lib/src/features/market/data/market_repository.dart` |
| Market live prices (WS) | Done, one known reconnect bug | `lib/src/features/market/data/market_price_ws_provider.dart` |
| Market search/filter | Done | `lib/src/features/market/presentation/market_dashboard_screen.dart` |
| EVM native balance | Done | `lib/src/features/portfolio/data/evm_client_service.dart` |
| EVM ERC-20 balance | Done | `evm_client_service.dart` `getErc20Balance`, `ethereum_token.dart` |
| Portfolio screen | Done (native + tracked ERC-20 balances) | `portfolio_screen.dart`, `portfolio_providers.dart` |
| Navigation shell (tabs) | Done | `lib/src/core/router/app_shell.dart`, `app_router.dart` |
| Auth domain | Done (Supabase email/password) | `features/auth/`, `supabase_auth_repository.dart`, `auth_providers.dart` |
| Saved wallets / nicknames | Done, local + optional cloud sync | `saved_wallet_repository.dart`, `saved_wallets_remote.dart`, `supabase_saved_wallets_remote.dart` |
| Account UI | Done | `features/auth/presentation/account_screen.dart` |
| Cloud schema + RLS | Done | `supabase/migrations/0001_saved_wallets.sql` |
| Multi-chain switching | **Missing** | single Ethereum mainnet RPC only |
| Custom tokens / user-added metadata | **Missing** | tokens come from the static `kEthereumErc20Tokens` list; no add-token UI |
| Portfolio fiat valuation | **Missing** | market and portfolio not joined |

There is **no** `EVMWalletEntity`, `EvmNetwork`, `AddCustomTokenDialog`, or
custom-token notifier in this repository. Saved wallets use
`SavedWalletEntity`; token metadata exists only as the static
`kEthereumErc20Tokens` list.

Auth covers email/password only: no OAuth, magic links, or deep-link handling on
Linux. `AuthInterceptor` is implemented and unit-testable but registered on no
client, because the Supabase SDK attaches the session header itself; it is kept
for the planned FastAPI client.

## 3. Architecture

Feature-first, three layers per feature:

```
lib/
├── main.dart                     # ensureInitialized, initIsar, ProviderScope
└── src/
    ├── core/
    │   ├── config/               # SupabaseConfig (--dart-define), client provider
    │   ├── database/             # isarProvider (overridden in main)
    │   ├── network/              # dioProvider, interceptors, ApiException
    │   └── router/               # goRouterProvider, AppShell (bottom tabs)
    └── features/
        ├── auth/
        │   ├── application/      # authRepository/authState/authController providers
        │   ├── data/             # SupabaseAuthRepository, DisabledAuthRepository,
        │   │                     # SecureSessionStorage (LocalStorage)
        │   ├── domain/           # AuthUser, AuthRepository, AuthException
        │   └── presentation/     # AccountScreen, AuthActionButton
        ├── market/
        │   ├── application/      # marketCoinsProvider, search/filter providers
        │   ├── data/             # repository, Isar entity + mapper, WS provider
        │   ├── domain/           # MarketCoin (Freezed)
        │   └── presentation/     # MarketDashboardScreen
        └── portfolio/
            ├── application/      # portfolioProvider, savedWalletsProvider
            ├── data/             # EvmClientService, saved-wallet repository + Isar
            │                     # entity, SavedWalletsRemote + Supabase impl
            ├── domain/           # PortfolioSnapshot, TokenBalance, SavedWallet, token list
            └── presentation/     # PortfolioScreen
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
| `web_socket_channel` | Binance ticker stream |
| `isar_community` + `isar_community_flutter_libs` | Local persistence, native libs |
| `path_provider` | Isar directory |
| `web3dart` | EVM JSON-RPC client: `Web3Client`, contracts, ABI |
| `wallet` | `EtherAmount`, `EtherUnit`, `EthereumAddress` (web3dart 3.x value types) |
| `flutter_secure_storage` | Session storage: Supabase refresh token in the OS keyring |
| `supabase_flutter` | Auth (GoTrue) and Postgres/PostgREST access for cloud sync |
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
  public: it must not carry user credentials. Authenticated backend calls get their
  own client with `AuthInterceptor`; that client does not exist yet because the
  Supabase SDK handles its own auth headers.
- **Auth is an interface, not an import.** Screens and providers depend on
  `AuthRepository`, never on `supabase_flutter`. A FastAPI backend means one new
  repository implementation plus one override in `main.dart`.
- **Auth is optional at build time.** Missing `--dart-define` keys select
  `DisabledAuthRepository`; the app starts and works fully offline. A failed
  Supabase init logs and degrades the same way instead of crashing.
- **Local data is the source of truth.** Saved wallets live in Isar first. Cloud
  merge runs on sign-in, and cloud writes are best effort so an offline save never
  fails because of the network.
- **Ownership is enforced by the database.** `saved_wallets` uses RLS with
  `auth.uid() = user_id`, and `user_id` defaults to `auth.uid()`, so client code
  cannot write rows for another user even if it tried.
- **Analyzer excludes generated and platform folders.** Keeps the signal on
  hand-written code. Stricter lints (`strict-casts`, `require_trailing_commas`,
  `unawaited_futures`) are intentionally deferred to milestones that touch the code.
- **Tests run serially** (`flutter test -j 1`) because Isar uses a native database.

## 6. Known issues

None of the original P0 issues remain: the market client no longer sends auth
tokens, market refresh no longer loops, and the WebSocket stops reconnecting after
disposal.

| Issue | Milestone |
|---|---|
| WS reconnect uses a fixed 5s delay instead of backoff | later |
| ERC-20 list is static; unknown tokens are not displayed | later (custom tokens) |
| Cloud sync merges labels with "cloud wins"; no per-row timestamps | later |
| No password reset or email-verification UI beyond Supabase defaults | later |
| No OAuth / deep links (deliberate on Linux desktop) | later |
| `libsecret` and a keyring are required to stay signed in on Linux | documented in README |

## 7. How to run and verify

```bash
flutter pub get
flutter run -d linux               # dev run (signed out)
flutter analyze                    # must be clean
flutter test -j 1                  # serial because of Isar; no network needed
dart run build_runner build        # after changing generated models
```

Cloud sync additionally needs the two `--dart-define` values and the SQL in
`supabase/migrations/0001_saved_wallets.sql`; see README "Cloud sync (optional)".

## 8. Roadmap

| Milestone | Goal |
|---|---|
| **M0** | ✅ Green build, committed generated code, analyzer scope, docs |
| **M1** | ✅ Bottom-navigation shell (Markets / Portfolio), providers moved to `application/` |
| **M2** | ✅ Fixed P0 bugs: token leak, refresh loop, WS reconnect |
| **M3** | ✅ Portfolio shows native balance plus tracked ERC-20 holdings |
| **M4** | ✅ Saved wallets persisted in Isar, selectable from the portfolio screen |
| **M5** | ✅ Optional Supabase email/password auth; saved wallets sync with RLS, local-first |
| **M6** | Portfolio valuation, hardening, strict lints |
