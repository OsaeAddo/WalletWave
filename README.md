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
- **Portfolio** — look up the native balance of any EVM address via JSON-RPC.

## Project layout

```
lib/
├── main.dart                       # ProviderScope + Isar initialization
└── src/
    ├── core/                       # Shared infrastructure
    │   ├── database/               # Isar instance provider
    │   ├── network/                # Dio client and interceptors
    │   └── router/                 # GoRouter plus AppShell (bottom tabs)
    └── features/                   # Feature-first boundaries
        ├── market/
        │   ├── application/        # Market providers
        │   ├── data/               # MarketRepository, Isar entities, WebSocket
        │   ├── domain/             # MarketCoin model
        │   └── presentation/       # Market dashboard UI
        └── portfolio/
            ├── application/        # Portfolio providers
            ├── data/               # EvmClientService, EVM providers
            ├── domain/             # WalletBalance model
            └── presentation/       # Portfolio UI
```

Dependency rule: `presentation` → `application` → `data`/`domain`.
Providers and business logic live under `application/`, never inside widgets.

## Requirements

- Flutter (Dart SDK `>=3.0.0 <4.0.0`)
- Linux desktop toolchain (`flutter doctor` should pass the Linux check)

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
test file and tests initialize Isar core on first run.
