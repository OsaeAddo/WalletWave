import 'dart:math';

/// Base delay before the first reconnect attempt.
const kReconnectBaseDelay = Duration(seconds: 2);

/// Upper bound, so a long outage never backs off forever.
const kReconnectMaxDelay = Duration(seconds: 30);

/// Delay before reconnect attempt [attempt] (zero-based).
///
/// Uses exponential backoff capped at [kReconnectMaxDelay], with "equal
/// jitter": half the delay is fixed, half is random. The randomness stops a
/// fleet of clients from reconnecting in lockstep after a server restart, and
/// the fixed half guarantees a non-zero wait.
///
/// Pass [random] with a seed to make tests deterministic.
Duration reconnectDelay(int attempt, {Random? random}) {
  final randomValue = random ?? Random();
  final exponent = attempt < 0 ? 0 : attempt;

  // Shifting by more than this overflows long before the cap matters.
  final safeExponent = min(exponent, 16);
  final exponentialMs =
      kReconnectBaseDelay.inMilliseconds * (1 << safeExponent);
  final cappedMs = min(exponentialMs, kReconnectMaxDelay.inMilliseconds);

  final half = cappedMs ~/ 2;
  return Duration(milliseconds: half + randomValue.nextInt(half + 1));
}
