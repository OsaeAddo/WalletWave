import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_wave/src/core/network/backoff.dart';

void main() {
  group('reconnectDelay', () {
    test('starts around the base delay', () {
      final delay = reconnectDelay(0, random: Random(1));
      expect(delay, greaterThanOrEqualTo(const Duration(seconds: 1)));
      expect(delay, lessThanOrEqualTo(const Duration(seconds: 2)));
    });

    test('grows exponentially', () {
      final attempt2 = reconnectDelay(2, random: Random(1));
      // Base 2s × 2² = 8s, so equal jitter lands in [4s, 8s].
      expect(attempt2, greaterThanOrEqualTo(const Duration(seconds: 4)));
      expect(attempt2, lessThanOrEqualTo(const Duration(seconds: 8)));
    });

    test('caps at the maximum delay', () {
      for (var attempt = 5; attempt < 40; attempt++) {
        final delay = reconnectDelay(attempt, random: Random(attempt));
        expect(
          delay,
          lessThanOrEqualTo(kReconnectMaxDelay),
          reason: 'attempt $attempt must stay under the cap',
        );
        expect(
          delay,
          greaterThanOrEqualTo(const Duration(seconds: 15)),
        );
      }
    });

    test('treats negative attempts as the first attempt', () {
      final negative = reconnectDelay(-3, random: Random(7));
      expect(negative, greaterThanOrEqualTo(const Duration(seconds: 1)));
      expect(negative, lessThanOrEqualTo(const Duration(seconds: 2)));
    });

    test('never returns a zero delay', () {
      for (var seed = 0; seed < 50; seed++) {
        expect(reconnectDelay(seed % 10, random: Random(seed)),
            isNot(Duration.zero));
      }
    });
  });
}
