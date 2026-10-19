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

/// A currency amounts can be shown in, chosen in the settings.
enum Currency {
  eur(label: 'Euro', symbol: '€', unitName: 'euro', decimalSeparator: ','),
  usd(
    label: 'US Dollar',
    symbol: r'$',
    unitName: 'dollar',
    isSymbolFirst: true,
  ),
  gbp(
    label: 'British Pound',
    symbol: '£',
    unitName: 'pound',
    isSymbolFirst: true,
  ),
  chf(
    label: 'Swiss Franc',
    symbol: 'CHF',
    unitName: 'franc',
    isSymbolFirst: true,
    coinSymbol: 'Fr',
  );

  const Currency({
    required this.label,
    required this.symbol,
    required this.unitName,
    this.isSymbolFirst = false,
    this.decimalSeparator = '.',
    String? coinSymbol,
  }) : coinSymbol = coinSymbol ?? symbol;

  /// What it's called in the settings.
  final String label;
  final String symbol;

  /// One of it in a sentence, like "every euro has a job".
  final String unitName;

  /// Whether the symbol comes before the amount, like $12.50, or after it,
  /// like 12,50€.
  final bool isSymbolFirst;

  final String decimalSeparator;

  /// The symbol on a coin, short enough to fit.
  final String coinSymbol;

  /// Put between the symbol and the amount, for symbols made of letters.
  String get _gap => symbol.length > 1 ? ' ' : '';
}

/// The currency [formatCents] shows amounts in. The app keeps it in sync
/// with the settings.
Currency currency = Currency.eur;

/// Formats cents with two decimals in [currency], e.g. 123450 -> "1234,50€".
String formatCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  final amount =
      '${abs ~/ 100}${currency.decimalSeparator}'
      '${(abs % 100).toString().padLeft(2, '0')}';
  final gap = currency._gap;
  return currency.isSymbolFirst
      ? '$sign${currency.symbol}$gap$amount'
      : '$sign$amount$gap${currency.symbol}';
}

/// Like [formatCents], with a plus sign for positive amounts.
String formatSignedCents(int cents) =>
    '${cents > 0 ? '+' : ''}${formatCents(cents)}';

/// Formats cents as plain input for an amount field, e.g. 123450 -> "1234.50",
/// which [parseAmountToCents] reads back.
String formatAmount(int cents) =>
    '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
