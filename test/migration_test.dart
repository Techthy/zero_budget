import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/money.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Seeds a database file with [seed], rolls today's schema back to what
  /// [version] looked like, then reopens it so the migrations run.
  Future<AppDatabase> openUpgradedFrom(
    int version,
    Future<void> Function(AppDatabase db) seed,
  ) async {
    final dir = await Directory.systemTemp.createTemp('zero_budget_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    final old = AppDatabase(NativeDatabase(file));
    await seed(old);
    if (version < 19) {
      await old.customStatement('ALTER TABLE months DROP COLUMN needs_set_up');
    }
    if (version >= 14 && version < 18) {
      await old.customStatement(
        'ALTER TABLE budgets ADD COLUMN is_savings INTEGER NOT NULL '
        'DEFAULT 0 CHECK (is_savings IN (0, 1))',
      );
      await old.customStatement(
        "UPDATE budgets SET is_savings = category = 'savings'",
      );
    }
    if (version < 18) {
      await old.customStatement('ALTER TABLE budgets DROP COLUMN category');
    }
    if (version < 17) {
      await old.customStatement('ALTER TABLE budgets DROP COLUMN position');
    }
    if (version >= 10 && version < 20) {
      await old.customStatement('ALTER TABLE settings DROP COLUMN currency');
    }
    if (version >= 10 && version < 16) {
      await old.customStatement(
        'ALTER TABLE settings DROP COLUMN budget_order',
      );
    }
    if (version >= 10 && version < 15) {
      await old.customStatement('ALTER TABLE settings DROP COLUMN appearance');
    }
    if (version >= 10 && version < 14) {
      await old.customStatement(
        'ALTER TABLE settings DROP COLUMN savings_goal_cents',
      );
      await old.customStatement(
        'ALTER TABLE settings DROP COLUMN savings_goal_period',
      );
    }
    if (version < 12) {
      await old.customStatement(
        'ALTER TABLE months DROP COLUMN carry_over_adjustment_cents',
      );
    }
    if (version >= 10 && version < 13) {
      await old.customStatement(
        'ALTER TABLE settings DROP COLUMN show_debug_bar',
      );
    }
    if (version == 10) {
      await old.customStatement(
        'ALTER TABLE settings DROP COLUMN selected_year_month',
      );
      await old.customStatement(
        'ALTER TABLE settings DROP COLUMN offered_year_month',
      );
    }
    if (version < 10) await old.customStatement('DROP TABLE settings');
    if (version < 9) {
      await old.customStatement('ALTER TABLE months DROP COLUMN notes');
    }
    if (version < 8 && version >= 2) {
      await old.customStatement('ALTER TABLE expenses DROP COLUMN title');
    }
    if (version < 7) {
      await old.customStatement(
        'ALTER TABLE budgets DROP COLUMN is_sinking_fund',
      );
      await old.customStatement('ALTER TABLE budgets DROP COLUMN saved_cents');
    }
    if (version < 6) await old.customStatement('DROP TABLE incomes');
    if (version < 5) {
      await old.customStatement(
        'ALTER TABLE months DROP COLUMN carry_over_cents',
      );
    }
    if (version < 4) {
      await old.customStatement('ALTER TABLE budgets DROP COLUMN is_fixed');
      await old.customStatement('ALTER TABLE expenses DROP COLUMN is_fixed');
    }
    if (version < 3) {
      await old.customStatement('ALTER TABLE months DROP COLUMN locked_at');
    }
    if (version < 2) await old.customStatement('DROP TABLE expenses');
    await old.customStatement('PRAGMA user_version = $version');
    await old.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    return upgraded;
  }

  for (final version in [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, //
  ]) {
    test('upgrading from schema $version keeps the plan', () async {
      late int monthId;
      late int rent;
      final upgraded = await openUpgradedFrom(version, (old) async {
        monthId = (await old.getOrCreateMonth(2026, 9)).id;
        rent = await old.addBudget(monthId, 'Rent', 120000);
      });

      await upgraded.addExpense(rent, 5000);
      await upgraded.lockMonth(monthId);

      expect((await upgraded.watchBudgets(monthId).first).single.name, 'Rent');
      expect(await upgraded.watchExpenses(monthId).first, hasLength(1));
      expect((await upgraded.watchMonth(monthId).first).lockedAt, isNotNull);
      await upgraded.setBufferCents(50000);
      expect(await upgraded.watchBufferCents().first, 50000);
      await upgraded.selectMonth(
        (year: 2026, month: 9),
        calendar: (year: 2026, month: 9),
      );
      expect(await upgraded.watchSelectedYearMonth().first, (
        year: 2026,
        month: 9,
      ));
      expect((await upgraded.watchSettings().first).showDebugBar, isTrue);
      // Recognized as an essential by its name, before there were
      // categories.
      expect(
        (await upgraded.watchBudgets(monthId).first).single.category,
        version < 18 ? BudgetCategory.essential : BudgetCategory.other,
      );
      await upgraded.setSavingsGoal(100000, SavingsPeriod.quarter);
      expect((await upgraded.watchSettings().first).savingsGoalCents, 100000);
      expect(
        (await upgraded.watchSettings().first).appearance,
        Appearance.system,
      );
      await upgraded.setAppearance(Appearance.dark);
      expect(
        (await upgraded.watchSettings().first).appearance,
        Appearance.dark,
      );
      expect(
        (await upgraded.watchSettings().first).budgetOrder,
        BudgetOrder.category,
      );
      await upgraded.setBudgetOrder(BudgetOrder.alphabetical);
      expect(
        (await upgraded.watchSettings().first).budgetOrder,
        BudgetOrder.alphabetical,
      );
      expect((await upgraded.watchSettings().first).currency, Currency.eur);
      await upgraded.setCurrency(Currency.chf);
      expect((await upgraded.watchSettings().first).currency, Currency.chf);
    });
  }

  test('upgrading from schema 11 keeps carryovers, then syncs them', () async {
    late int september;
    late int october;
    late int food;
    final upgraded = await openUpgradedFrom(11, (old) async {
      september = (await old.getOrCreateMonth(2026, 9)).id;
      await old.addIncome(september, 'Salary', 300000);
      food = await old.addBudget(september, 'Food', 40000);
      october = (await old.getOrCreateMonth(2026, 10)).id;
      // Corrected by hand, or out of date.
      await old.customStatement(
        'UPDATE months SET carry_over_cents = 250000 WHERE id = $october',
      );
    });
    Future<Month> octoberNow() => upgraded.watchMonth(october).first;

    expect((await octoberNow()).carryOverCents, 250000);
    expect((await octoberNow()).carryOverAdjustmentCents, -50000);

    await upgraded.addExpense(food, 5000);
    expect((await octoberNow()).carryOverCents, 245000);
  });

  test('upgrading from schema 7 turns notes into titles', () async {
    late int monthId;
    final upgraded = await openUpgradedFrom(7, (old) async {
      monthId = (await old.getOrCreateMonth(2026, 9)).id;
      final food = await old.addBudget(monthId, 'Food', 40000);
      await old.addExpense(food, 5000, note: 'Groceries');
      await old.addExpense(food, 2500);
    });

    final expenses = await upgraded.watchExpenses(monthId).first;
    expect(
      expenses.map((e) => (e.title, e.note)),
      unorderedEquals([('Groceries', null), (null, null)]),
    );
  });

  test('upgrading from schema 5 turns the income into an income', () async {
    late int monthId;
    final upgraded = await openUpgradedFrom(5, (old) async {
      monthId = (await old.getOrCreateMonth(2026, 9)).id;
      await old.addIncome(monthId, 'Salary', 300000);
      await old.getOrCreateMonth(2026, 10);
      await old.customStatement(
        'UPDATE months SET income_cents = 0 WHERE year = 2026 AND month = 10',
      );
    });

    final incomes = await upgraded.select(upgraded.incomes).get();
    expect(incomes.map((i) => (i.monthId, i.name, i.amountCents)), [
      (monthId, 'Income', 300000),
    ]);
    expect((await upgraded.watchMonth(monthId).first).incomeCents, 300000);
  });

  test(
    'upgrading turns savings and the guided budgets into categories',
    () async {
      late int monthId;
      final upgraded = await openUpgradedFrom(17, (old) async {
        monthId = (await old.getOrCreateMonth(2026, 9)).id;
        await old.addBudget(monthId, 'giving', 5000);
        await old.addBudget(monthId, 'Groceries', 40000);
        await old.addBudget(monthId, 'Transportation', 8000);
        await old.addBudget(monthId, 'Fun', 10000);
        await old.addBudget(
          monthId,
          'ETF',
          20000,
          category: BudgetCategory.savings,
        );
        // Savings first, whatever it's called.
        await old.addBudget(
          monthId,
          'Rent',
          1000,
          category: BudgetCategory.savings,
        );
      });

      final budgets = await upgraded.watchBudgets(monthId).first;
      expect(budgets.map((b) => (b.name, b.category)), [
        ('giving', BudgetCategory.giving),
        ('Groceries', BudgetCategory.essential),
        ('Transportation', BudgetCategory.essential),
        ('Fun', BudgetCategory.other),
        ('ETF', BudgetCategory.savings),
        ('Rent', BudgetCategory.savings),
      ]);
    },
  );

  test('upgrading keeps the order budgets were added in', () async {
    late int monthId;
    final upgraded = await openUpgradedFrom(16, (old) async {
      monthId = (await old.getOrCreateMonth(2026, 9)).id;
      await old.addBudget(monthId, 'Rent', 90000);
      await old.addBudget(monthId, 'Food', 40000);
    });

    final budgets = await upgraded.watchBudgets(monthId).first;
    expect(budgets.map((b) => (b.name, b.position)), [
      ('Rent', budgets.first.id),
      ('Food', budgets.last.id),
    ]);
    expect(budgets.first.position, lessThan(budgets.last.position));
  });
}
