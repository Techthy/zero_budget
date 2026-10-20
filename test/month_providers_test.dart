import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/data/database_provider.dart';
import 'package:zero_budget/dates.dart';
import 'package:zero_budget/month/month_providers.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('current month providers expose income and budgets', () async {
    final now = DateTime.now();
    final month = await db.getOrCreateMonth(now.year, now.month);
    await db.addIncome(month.id, 'Salary', 300000);
    await db.addBudget(month.id, 'Rent', 120000);

    final container = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    container.listen(currentMonthProvider, (_, _) {});
    container.listen(currentBudgetsProvider, (_, _) {});

    expect(
      (await container.read(currentMonthProvider.future)).incomeCents,
      300000,
    );
    final budgets = await container.read(currentBudgetsProvider.future);
    expect(budgets.single.name, 'Rent');
  });

  test(
    'the app starts in today\'s month and remembers the chosen one',
    () async {
      final now = DateTime.now();
      final today = (year: now.year, month: now.month);
      final next = yearMonthOf(DateTime(now.year, now.month + 1));
      var container = ProviderContainer.test(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      container.listen(currentMonthProvider, (_, _) {});

      expect(await container.read(currentYearMonthProvider.future), today);
      expect(await db.watchSelectedYearMonth().first, today);

      await db.selectMonth(next, calendar: today);
      await pumpEventQueue();
      final month = await container.read(currentMonthProvider.future);
      expect((month.year, month.month), (next.year, next.month));

      // Opening the app again stays in the chosen month.
      container = ProviderContainer.test(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      container.listen(currentYearMonthProvider, (_, _) {});
      expect(await container.read(currentYearMonthProvider.future), next);
    },
  );

  test(
    'monthDetails loads a month with its incomes, budgets and expenses',
    () async {
      final container = ProviderContainer.test(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      final september = await db.getOrCreateMonth(2026, 9);
      await db.addIncome(september.id, 'Salary', 300000);
      final food = await db.addBudget(september.id, 'Food', 40000);
      await db.addExpense(food, 2500, title: 'Market');
      final provider = monthDetailsProvider(september.id);
      container.listen(provider, (_, _) {});

      expect(container.read(provider), isA<AsyncLoading<MonthDetails>>());
      await pumpEventQueue();
      final details = container.read(provider).value!;
      expect(details.month.id, september.id);
      expect(details.incomes.map((i) => i.name), ['Salary']);
      expect(details.budgets.map((b) => b.name), ['Food']);
      expect(details.expenses.map((e) => e.title), ['Market']);
    },
  );

  test('a new month is offered days before it starts, and only once', () async {
    final container = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    container.listen(monthToOfferProvider, (_, _) {});
    // Not the last day, whenever the test runs.
    container.read(dayOffsetProvider.notifier).shiftToMonthStart(0);
    final start = await container.read(currentYearMonthProvider.future);
    expect(await container.read(monthToOfferProvider.future), isNull);

    container.read(dayOffsetProvider.notifier)
      ..shiftToMonthStart(1)
      ..shiftDays(-planAheadDays - 1);
    expect(await container.read(monthToOfferProvider.future), isNull);
    container.read(dayOffsetProvider.notifier).shiftDays(1);
    final next = yearMonthOf(DateTime(start.year, start.month + 1));
    expect(await container.read(monthToOfferProvider.future), next);

    // Declining stays in the month before, also once the next one starts.
    await db.declineMonth(next);
    await pumpEventQueue();
    expect(await container.read(monthToOfferProvider.future), isNull);
    container.read(dayOffsetProvider.notifier).shiftToMonthStart(1);
    expect(await container.read(monthToOfferProvider.future), isNull);
    expect(await container.read(currentYearMonthProvider.future), start);

    // And so does going back to it after moving on.
    await db.selectMonth(next, calendar: next);
    await db.selectMonth(start, calendar: next);
    await pumpEventQueue();
    expect(await container.read(monthToOfferProvider.future), isNull);

    // The month after that is offered again.
    container.read(dayOffsetProvider.notifier).shiftToMonthStart(1);
    expect(
      await container.read(monthToOfferProvider.future),
      yearMonthOf(container.read(todayProvider)),
    );
  });

  test('the debug day offset moves today across years', () async {
    final container = ProviderContainer.test();
    final now = DateTime.now();
    final offset = container.read(dayOffsetProvider.notifier);

    for (var i = 0; i < now.month; i++) {
      offset.shiftToMonthStart(-1);
    }
    expect(container.read(todayProvider), DateTime(now.year - 1, 12));
    offset.shiftDays(31);
    expect(container.read(todayProvider), DateTime(now.year));

    offset.reset();
    expect(
      container.read(todayProvider),
      DateTime(now.year, now.month, now.day),
    );
  });
}
