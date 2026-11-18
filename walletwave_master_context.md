# WalletWave — Project Context & Status

This document describes what the repository **actually contains today**. It is
corrected whenever a milestone lands. Anything not listed under "Implemented" does
not exist yet, even if it appears in older notes.

## 1. Purpose and scope

WalletWave is a Flutter crypto app with two working domains:

- **Markets** — fetch top coins from CoinGecko, cache them in Isar, stream live
  prices from Binance, search by name or symbol.
- **Portfolio** — query the native balance of an EVM address over JSON-RPC.

**Supported target: Linux desktop only.** The Android/iOS/web/macOS/Windows folders
are Flutter scaffolding and are not built or tested.

Repository: `github.com/OsaeAddo/WalletWave` (branch `main`).

## 2. Status matrix

Each row names the file that proves the claim.

| Area | Status | Evidence |
|---|---|---|
| App bootstrap + Isar init | Done | `lib/main.dart`, `lib/src/core/database/isar_provider.dart` |
| Dio client + logging | Done | `lib/src/core/network/dio_provider.dart`, `logging_interceptor.dart` |
| Auth token interceptor | Partial | `lib/src/core/network/auth_interceptor.dart` (adds header; no auth domain yet) |
| Market REST + Isar cache | Done | `lib/src/features/market/data/market_repository.dart` |
| Market live prices (WS) | Done, one known reconnect bug | `lib/src/features/market/data/market_price_ws_provider.dart` |
| Market search/filter | Done | `lib/src/features/market/presentation/market_dashboard_screen.dart` |
| EVM native balance | Done | `lib/src/features/portfolio/data/evm_client_service.dart` |
| EVM ERC-20 balance | Done (service), no UI | `evm_client_service.dart` `getErc20Balance` |
| Portfolio screen | Done (native balance lookup) | `lib/src/features/portfolio/presentation/portfolio_screen.dart` |
| Navigation shell (tabs) | Done | `lib/src/core/router/app_shell.dart`, `app_router.dart` |
| Auth domain (login, sessions, guards) | **Missing** | no `features/auth/` directory |
| Saved wallets / nicknames | **Missing** | no wallet repository or entity |
| Multi-chain switching | **Missing** | single Ethereum mainnet RPC only |
| ERC-20 metadata / custom tokens | **Missing** | no UI or notifier |
| Portfolio fiat valuation | **Missing** | market and portfolio not joined |

There are **no** `WalletRepository`, `EVMWalletEntity`, `EvmNetwork`,
`kChainErc20Tokens`, `AddCustomTokenDialog`, custom-token notifier, or ERC-20
metadata features in this repository.

## 3. Architecture

Feature-first, three layers per feature:

```
lib/
├── main.dart                     # ensureInitialized, initIsar, ProviderScope
└── src/
    ├── core/
    │   ├── database/             # isarProvider (overridden in main)
    │   ├── network/              # dioProvider, interceptors, ApiException
    │   └── router/               # goRouterProvider, AppShell (bottom tabs)
    └── features/
        ├── market/
        │   ├── application/      # marketCoinsProvider, search/filter providers
        │   ├── data/             # repository, Isar entity + mapper, WS provider
        │   ├── domain/           # MarketCoin (Freezed)
        │   └── presentation/     # MarketDashboardScreen
        └── portfolio/
            ├── application/      # selectedAddressProvider, walletBalanceProvider
            ├── data/             # EvmClientService, evmClientServiceProvider
            ├── domain/           # WalletBalance (Freezed)
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
| `flutter_secure_storage` | Token storage for the future auth domain |
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
  own client with `AuthInterceptor` (M5).
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
| `EvmClientService` never disposed by `evmClientServiceProvider` | later |

## 7. How to run and verify

```bash
flutter pub get
flutter run -d linux               # dev run
flutter analyze                    # must be clean
flutter test -j 1                  # serial because of Isar
dart run build_runner build        # after changing generated models
```

## 8. Roadmap

| Milestone | Goal |
|---|---|
| **M0** | ✅ Green build, committed generated code, analyzer scope, docs |
| **M1** | ✅ Bottom-navigation shell (Markets / Portfolio), providers moved to `application/` |
| **M2** | ✅ Fixed P0 bugs: token leak, refresh loop, WS reconnect |
| **M3** | Portfolio forms and ERC-20 balances in the UI |
| **M4** | Saved wallets and persistence |
| **M5** | Auth domain (backend choice documented at that point) |
| **M6** | Portfolio valuation, hardening, strict lints |
