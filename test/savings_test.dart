import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/data/database_provider.dart';
import 'package:zero_budget/savings/savings_providers.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('savings budgets count towards the goal month by month', () async {
    final september = await db.getOrCreateMonth(2026, 9);
    await db.addIncome(september.id, 'Salary', 300000);
    await db.addBudget(
      september.id,
      'ETF',
      20000,
      isFixed: true,
      category: BudgetCategory.savings,
    );
    final savings = await db.addBudget(
      september.id,
      'Savings',
      30000,
      category: BudgetCategory.savings,
    );
    final food = await db.addBudget(september.id, 'Food', 40000);
    await db.addBudget(september.id, 'Holiday', 10000, isSinkingFund: true);
    Future<List<MonthSavings>> savedIn(int from, int to) => db
        .watchSavingsByMonth((year: 2026, month: from), (year: 2026, month: to))
        .first;

    // Only what's spent counts: fixed savings once the plan is locked in.
    expect(await savedIn(1, 12), isEmpty);
    await db.lockMonth(september.id);
    await db.addExpense(savings, 10000);
    await db.addExpense(food, 5000);
    expect(await savedIn(1, 12), [
      (month: (year: 2026, month: 9), savedCents: 30000),
    ]);

    // New months keep their budgets' categories.
    final october = await db.getOrCreateMonth(2026, 10);
    final octoberBudgets = await db.watchBudgets(october.id).first;
    expect(
      octoberBudgets
          .where((b) => b.category == BudgetCategory.savings)
          .map((b) => b.name),
      ['ETF', 'Savings'],
    );
    await db.lockMonth(october.id);
    expect((await savedIn(1, 12)).map((m) => m.savedCents), [30000, 20000]);
    // Only months in the period count.
    expect((await savedIn(10, 12)).map((m) => m.savedCents), [20000]);
  });

  test('the savings goal starts unset, per year, and can be changed', () async {
    var settings = await db.watchSettings().first;
    expect(settings.savingsGoalCents, isNull);
    expect(settings.savingsGoalPeriod, SavingsPeriod.year);

    await db.setSavingsGoal(150000, SavingsPeriod.quarter);
    settings = await db.watchSettings().first;
    expect(settings.savingsGoalCents, 150000);
    expect(settings.savingsGoalPeriod, SavingsPeriod.quarter);

    await db.setSavingsGoal(null, SavingsPeriod.quarter);
    expect((await db.watchSettings().first).savingsGoalCents, isNull);
  });

  test('savingsProgress follows the period of the current month', () async {
    final container = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    await db.selectMonth(
      (year: 2026, month: 11),
      calendar: (year: 2026, month: 11),
    );
    final august = await db.getOrCreateMonth(2026, 8);
    await db.addBudget(
      august.id,
      'Savings',
      50000,
      isFixed: true,
      category: BudgetCategory.savings,
    );
    await db.lockMonth(august.id);
    final november = await db.getOrCreateMonth(2026, 11);
    await db.lockMonth(november.id);
    container.listen(savingsProgressProvider, (_, _) {});
    Future<SavingsProgress> progress() async {
      await pumpEventQueue();
      return container.read(savingsProgressProvider.future);
    }

    // August is in the year, but not in the fourth quarter.
    await db.setSavingsGoal(200000, SavingsPeriod.year);
    var now = await progress();
    expect(now.periodName, '2026');
    expect(now.savedCents, 100000);
    expect(now.fraction, 0.5);

    await db.setSavingsGoal(40000, SavingsPeriod.quarter);
    now = await progress();
    expect(now.periodName, 'Q4 2026');
    expect(now.savedCents, 50000);
    expect(now.fraction, 1);
  });

  group('suggestMonthlySavings', () {
    SavingsProgress progress({int? goalCents = 600000}) => SavingsProgress(
      goalCents: goalCents,
      period: SavingsPeriod.year,
      month: (year: 2026, month: 10),
      months: [
        (month: (year: 2026, month: 9), savedCents: 100000),
        // What's being planned doesn't count as saved before.
        (month: (year: 2026, month: 10), savedCents: 50000),
      ],
    );

    test('spreads what is still needed over the months left', () {
      // 5000,00€ still needed over October to December, rounded up to
      // whole euros.
      expect(suggestMonthlySavings(progress(), (year: 2026, month: 10)), (
        savedBeforeCents: 100000,
        perMonthCents: 166700,
        monthsLeft: 3,
      ));
    });

    test('counts the months left in a quarter', () {
      final quarter = SavingsProgress(
        goalCents: 300000,
        period: SavingsPeriod.quarter,
        month: (year: 2026, month: 11),
        months: [(month: (year: 2026, month: 10), savedCents: 100000)],
      );
      // 2000,00€ still needed over November and December.
      expect(suggestMonthlySavings(quarter, (year: 2026, month: 11)), (
        savedBeforeCents: 100000,
        perMonthCents: 100000,
        monthsLeft: 2,
      ));
    });

    test('suggests nothing more once the goal is reached', () {
      expect(
        suggestMonthlySavings(progress(goalCents: 80000), (
          year: 2026,
          month: 10,
        ))?.perMonthCents,
        0,
      );
    });

    test('has nothing to suggest without a goal', () {
      expect(
        suggestMonthlySavings(progress(goalCents: null), (
          year: 2026,
          month: 10,
        )),
        isNull,
      );
    });
  });

  test('savingsPeriodOf', () {
    expect(savingsPeriodOf((year: 2026, month: 11), SavingsPeriod.quarter), (
      first: (year: 2026, month: 10),
      last: (year: 2026, month: 12),
    ));
    expect(savingsPeriodOf((year: 2026, month: 1), SavingsPeriod.quarter), (
      first: (year: 2026, month: 1),
      last: (year: 2026, month: 3),
    ));
    expect(savingsPeriodOf((year: 2026, month: 5), SavingsPeriod.year), (
      first: (year: 2026, month: 1),
      last: (year: 2026, month: 12),
    ));
  });
}
