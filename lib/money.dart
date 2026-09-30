final _amountPattern = RegExp(r'^(\d{1,9})(?:\.(\d{1,2}))?$');

/// Parses user input like "1200", "1200.5" or "1200,50" into cents.
///
/// Returns null if the input isn't a valid non-negative amount.
int? parseAmountToCents(String input) {
  final match = _amountPattern.firstMatch(input.trim().replaceAll(',', '.'));
  if (match == null) return null;
  final whole = int.parse(match.group(1)!);
  final fraction = int.parse((match.group(2) ?? '').padRight(2, '0'));
  return whole * 100 + fraction;
}

/// Formats cents as a plain amount with two decimals, e.g. 123450 -> "1234.50".
String formatCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  return '$sign${abs ~/ 100},${(abs % 100).toString().padLeft(2, '0')}€';
}
