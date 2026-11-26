/// Formats a US dollar value with a predictable number of decimals.
///
/// Kept as a plain function so it can be unit tested without a widget tree and
/// reused by any screen that shows money.
///
/// Rules:
/// - `0` and normal amounts keep two decimals: `$1,234.56`.
/// - Amounts below `$1` get four decimals, and below one cent six decimals, so
///   small token values do not all collapse into `$0.00`.
/// - Values that round to less than a millionth of a dollar show `< $0.000001`
///   instead of pretending to be zero.
String formatUsd(double value) {
  final isNegative = value < 0;
  final magnitude = value.abs();
  final sign = isNegative ? '-' : '';

  if (magnitude == 0) return '\$0.00';
  if (magnitude < 0.000001) return '<$sign\$0.000001';

  final decimals = magnitude >= 1 ? 2 : (magnitude >= 0.01 ? 4 : 6);
  final text = magnitude.toStringAsFixed(decimals);
  final grouped = magnitude >= 1000 ? _groupThousands(text) : text;

  return '$sign\$$grouped';
}

/// Inserts `,` every three digits in the whole-dollar part only.
String _groupThousands(String fixed) {
  final dot = fixed.indexOf('.');
  final whole = dot == -1 ? fixed : fixed.substring(0, dot);
  final fraction = dot == -1 ? '' : fixed.substring(dot);

  final grouped = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
    grouped.write(whole[i]);
  }
  return '$grouped$fraction';
}
