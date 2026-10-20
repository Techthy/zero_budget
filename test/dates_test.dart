import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/dates.dart';

void main() {
  group('monthsToChooseFrom', () {
    test('offers the next month three days before it starts', () {
      const october = (year: 2026, month: 10);
      const november = (year: 2026, month: 11);
      expect(monthsToChooseFrom([], DateTime(2026, 10, 28)), [october]);
      expect(monthsToChooseFrom([], DateTime(2026, 10, 29)), [
        november,
        october,
      ]);
      expect(monthsToChooseFrom([], DateTime(2026, 12, 29)), [
        (year: 2027, month: 1),
        (year: 2026, month: 12),
      ]);
    });

    test('includes planned months once, newest first', () {
      expect(
        monthsToChooseFrom([
          (year: 2026, month: 9),
          (year: 2025, month: 12),
          (year: 2026, month: 10),
        ], DateTime(2026, 10, 5)),
        [
          (year: 2026, month: 10),
          (year: 2026, month: 9),
          (year: 2025, month: 12),
        ],
      );
    });
  });

  test('newMonthToOffer', () {
    const september = (year: 2026, month: 9);
    const october = (year: 2026, month: 10);
    final inOctober = DateTime(2026, 10, 1);
    expect(
      newMonthToOffer(current: september, offered: null, today: inOctober),
      october,
    );
    expect(
      newMonthToOffer(current: september, offered: september, today: inOctober),
      october,
    );
    expect(
      newMonthToOffer(current: september, offered: october, today: inOctober),
      isNull,
    );
    expect(
      newMonthToOffer(current: october, offered: null, today: inOctober),
      isNull,
    );
    // From three days before the month starts, to plan ahead.
    const november = (year: 2026, month: 11);
    expect(
      newMonthToOffer(
        current: october,
        offered: null,
        today: DateTime(2026, 10, 28),
      ),
      isNull,
    );
    expect(
      newMonthToOffer(
        current: october,
        offered: null,
        today: DateTime(2026, 10, 29),
      ),
      november,
    );
    final lastDay = DateTime(2026, 10, 31);
    expect(
      newMonthToOffer(current: october, offered: null, today: lastDay),
      november,
    );
    expect(
      newMonthToOffer(current: october, offered: november, today: lastDay),
      isNull,
    );
    expect(
      newMonthToOffer(
        current: (year: 2026, month: 12),
        offered: null,
        today: DateTime(2026, 12, 31),
      ),
      (year: 2027, month: 1),
    );
  });
}
