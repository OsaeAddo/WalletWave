import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_wave/main.dart';
import 'package:wallet_wave/src/features/market/application/market_providers.dart';
import 'package:wallet_wave/src/features/market/domain/market_coin.dart';

void main() {
  testWidgets('shell switches tabs and keeps branch state alive',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Avoid Isar, HTTP and WebSocket: the market list is simply empty.
          marketCoinsProvider
              .overrideWith(() => _EmptyMarketCoinsNotifier()),
        ],
        child: const WalletWaveApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Markets is the initial branch.
    expect(find.text('Live Markets'), findsOneWidget);

    // Switch to Portfolio.
    await tester.tap(find.text('Portfolio'));
    await tester.pumpAndSettle();
    expect(find.text('EVM Portfolio'), findsOneWidget);

    // Type into the address field, then leave and come back.
    await tester.enterText(find.byType(TextField), '0xabc123');
    await tester.tap(find.text('Markets'));
    await tester.pumpAndSettle();
    expect(find.text('Live Markets'), findsOneWidget);

    await tester.tap(find.text('Portfolio'));
    await tester.pumpAndSettle();

    // The text survives because indexedStack keeps the branch mounted.
    expect(find.text('0xabc123'), findsOneWidget);
  });
}

class _EmptyMarketCoinsNotifier extends MarketCoinsNotifier {
  @override
  Future<List<MarketCoin>> build() async => <MarketCoin>[];
}
