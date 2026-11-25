import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_wave/src/core/format/usd.dart';

void main() {
  group('formatUsd', () {
    test('keeps two decimals for normal amounts', () {
      expect(formatUsd(0), '\$0.00');
      expect(formatUsd(1), '\$1.00');
      expect(formatUsd(12.5), '\$12.50');
    });

    test('groups thousands', () {
      expect(formatUsd(1234.5), '\$1,234.50');
      expect(formatUsd(1234567.891), '\$1,234,567.89');
    });

    test('shows more precision below one dollar', () {
      expect(formatUsd(0.125), '\$0.1250');
      expect(formatUsd(0.00125), '\$0.001250');
    });

    test('does not round dust down to zero', () {
      expect(formatUsd(0.0000001), '<\$0.000001');
    });

    test('puts the sign before the dollar mark', () {
      expect(formatUsd(-5), '-\$5.00');
    });
  });
}
