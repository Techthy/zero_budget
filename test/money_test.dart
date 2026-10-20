import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/money.dart';

void main() {
  group('parseAmountToCents', () {
    test('accepts whole amounts and both decimal separators', () {
      expect(parseAmountToCents('1200'), 120000);
      expect(parseAmountToCents('1200.5'), 120050);
      expect(parseAmountToCents(' 1200,05 '), 120005);
    });

    test('rejects invalid input', () {
      expect(parseAmountToCents(''), isNull);
      expect(parseAmountToCents('12.345'), isNull);
      expect(parseAmountToCents('-5'), isNull);
      expect(parseAmountToCents('1.200,50'), isNull);
    });
  });

  test('formatCents', () {
    expect(formatCents(123450), '1234,50€');
    expect(formatCents(5), '0,05€');
    expect(formatCents(-2500), '-25,00€');
  });

  test('formatLeftCents says what is left, or how far it went over', () {
    expect(formatLeftCents(1250), '12,50€ left');
    expect(formatLeftCents(0), '0,00€ left');
    expect(formatLeftCents(-300), '3,00€ over');
  });

  test('formatCents follows the currency', () {
    addTearDown(() => useCurrency(Currency.eur));
    useCurrency(Currency.usd);
    expect(formatCents(123450), r'$1234.50');
    expect(formatCents(-2500), r'-$25.00');
    useCurrency(Currency.gbp);
    expect(formatCents(5), '£0.05');
    useCurrency(Currency.chf);
    expect(formatCents(123450), 'CHF 1234.50');
    expect(formatSignedCents(2500), '+CHF 25.00');
  });

  test('formatAmount is read back by parseAmountToCents', () {
    expect(formatAmount(123450), '1234.50');
    expect(formatAmount(5), '0.05');
    for (final cents in [0, 5, 100000, 123450]) {
      expect(parseAmountToCents(formatAmount(cents)), cents);
    }
  });
}
