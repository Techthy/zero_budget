import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/data/database_provider.dart';
import 'package:zero_budget/dates.dart';
import 'package:zero_budget/money.dart';
import 'package:zero_budget/month/month_providers.dart';
import 'package:zero_budget/savings/savings_providers.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('updateBudget changes only that budget', () async {
    final month = await db.getOrCreateMonth(2026, 9);
    final rent = await db.addBudget(month.id, 'Rent', 120000);
    await db.addBudget(month.id, 'Food', 40000);

    await db.updateBudget(
      rent,
      name: 'Rent & bills',
      amountCents: 125000,
      isFixed: true,
    );

    final budgets = await db.watchBudgets(month.id).first;
    expect(budgets.map((b) => (b.name, b.amountCents, b.isFixed)), [
      ('Rent & bills', 125000, true),
      ('Food', 40000, false),
    ]);
  });

  test('a new month starts from the latest earlier month', () async {
    final july = await db.getOrCreateMonth(2026, 7);
    await db.addBudget(july.id, 'Old budget', 1000);
    final august = await db.getOrCreateMonth(2026, 8);
    await db.addIncome(august.id, 'Salary', 250000);
    await db.addIncome(august.id, 'Side job', 50000);
    await db.updateBudget(
      (await db.watchBudgets(august.id).first).single.id,
      name: 'Rent',
      amountCents: 120000,
      isFixed: true,
    );
    final food = await db.addBudget(august.id, 'Food', 40000);
    await db.lockMonth(august.id);
    await db.addExpense(food, 5000);

    final september = await db.getOrCreateMonth(2026, 9);

    expect(september.incomeCents, 300000);
    final incomes = await db.watchIncomes(september.id).first;
    expect(incomes.map((i) => (i.name, i.amountCents)), [
      ('Salary', 250000),
      ('Side job', 50000),
    ]);
    // 3000.00 income - 1200.00 fixed rent - 50.00 food.
    expect(september.carryOverCents, 175000);
    expect(september.lockedAt, isNull);
    final budgets = await db.watchBudgets(september.id).first;
    expect(budgets.map((b) => (b.name, b.amountCents, b.isFixed)), [
      ('Rent', 120000, true),
      ('Food', 40000, false),
    ]);
    expect(await db.watchExpenses(september.id).first, isEmpty);
    // Opening it again doesn't copy the template twice.
    await db.getOrCreateMonth(2026, 9);
    expect(await db.watchBudgets(september.id).first, hasLength(2));
    expect(await db.watchIncomes(september.id).first, hasLength(2));
  });

  test('the month income is the total of its incomes', () async {
    final month = await db.getOrCreateMonth(2026, 9);
    Future<int> incomeCents() async =>
        (await db.watchMonth(month.id).first).incomeCents;

    final salary = await db.addIncome(month.id, 'Salary', 250000);
    final side = await db.addIncome(month.id, 'Side job', 30000);
    expect(await incomeCents(), 280000);

    await db.updateIncome(side, name: 'Freelance', amountCents: 45000);
    expect(await incomeCents(), 295000);

    await db.deleteIncome(salary);
    expect(await incomeCents(), 45000);
    expect((await db.watchIncomes(month.id).first).single.name, 'Freelance');

    await db.deleteIncome(side);
    expect(await incomeCents(), 0);
  });

  test('each new month carries over the balance of the one before', () async {
    final july = await db.getOrCreateMonth(2026, 7);
    await db.addIncome(july.id, 'Salary', 100000);
    final julyRent = await db.addBudget(july.id, 'Rent', 100000);
    await db.addExpense(julyRent, 90000);

    final august = await db.getOrCreateMonth(2026, 8);
    expect(august.carryOverCents, 10000);
    final augustRent = (await db.watchBudgets(august.id).first).single.id;
    await db.addExpense(augustRent, 105000);

    // 1000.00 income + 100.00 carried over - 1050.00 spent.
    final september = await db.getOrCreateMonth(2026, 9);
    expect(september.carryOverCents, 5000);
    expect(september.incomeCents, 100000);
  });

  test('locking in spends fixed budgets in full, once', () async {
    final month = await db.getOrCreateMonth(2026, 9);
    final rent = await db.addBudget(month.id, 'Rent', 120000, isFixed: true);
    await db.addBudget(month.id, 'Food', 40000);

    await db.lockMonth(month.id);
    final fixed = (await db.watchExpenses(month.id).first).single;
    expect(
      (fixed.budgetId, fixed.amountCents, fixed.isFixed),
      (rent, 120000, true),
    );

    // Locking in again after an edit updates instead of duplicating.
    await db.unlockMonth(month.id);
    await db.updateBudget(
      rent,
      name: 'Rent',
      amountCents: 125000,
      isFixed: true,
    );
    await db.lockMonth(month.id);
    expect((await db.watchExpenses(month.id).first).single.amountCents, 125000);

    // A budget that's no longer fixed loses its fixed expense.
    await db.unlockMonth(month.id);
    await db.updateBudget(
      rent,
      name: 'Rent',
      amountCents: 125000,
      isFixed: false,
    );
    await db.lockMonth(month.id);
    expect(await db.watchExpenses(month.id).first, isEmpty);
  });

  test('watchExpenses only returns expenses from that month', () async {
    final september = await db.getOrCreateMonth(2026, 9);
    final october = await db.getOrCreateMonth(2026, 10);
    final rent = await db.addBudget(september.id, 'Rent', 120000);
    final food = await db.addBudget(october.id, 'Food', 40000);
    await db.addExpense(rent, 120000);
    await db.addExpense(food, 5000, title: 'Groceries', note: 'Paid in cash');

    final expenses = await db.watchExpenses(september.id).first;
    expect(expenses.single.budgetId, rent);
    expect(expenses.single.title, isNull);
    expect(expenses.single.note, isNull);

    final octoberExpense = (await db.watchExpenses(october.id).first).single;
    expect(octoberExpense.title, 'Groceries');
    expect(octoberExpense.note, 'Paid in cash');
  });

  test('watchMonthSummaries totals each month, newest first', () async {
    final august = await db.getOrCreateMonth(2026, 8);
    final september = await db.getOrCreateMonth(2026, 9);
    final rent = await db.addBudget(august.id, 'Rent', 120000);
    await db.addBudget(august.id, 'Food', 40000);
    await db.addExpense(rent, 120000);
    await db.addExpense(rent, 2500);

    final summaries = await db.watchMonthSummaries().first;

    expect(summaries.map((s) => s.month.id), [september.id, august.id]);
    expect(summaries.first.plannedCents, 0);
    expect(summaries.first.spentCents, 0);
    expect(summaries.last.plannedCents, 160000);
    expect(summaries.last.spentCents, 122500);
  });

  test('locking and unlocking a month keeps its expenses', () async {
    final month = await db.getOrCreateMonth(2026, 9);
    final rent = await db.addBudget(month.id, 'Rent', 120000);
    expect(month.lockedAt, isNull);

    await db.lockMonth(month.id);
    await db.addExpense(rent, 120000);
    expect((await db.watchMonth(month.id).first).lockedAt, isNotNull);

    await db.unlockMonth(month.id);
    expect((await db.watchMonth(month.id).first).lockedAt, isNull);
    expect(await db.watchExpenses(month.id).first, hasLength(1));
  });

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

  test('sinking funds save up over the months', () async {
    final july = await db.getOrCreateMonth(2026, 7);
    await db.addIncome(july.id, 'Salary', 100000);
    final julyFood = await db.addBudget(july.id, 'Food', 90000);
    final julyInsurance = await db.addBudget(
      july.id,
      'Insurance',
      10000,
      isSinkingFund: true,
    );
    await db.addExpense(julyFood, 80000);
    await db.addExpense(julyInsurance, 2500);

    final august = await db.getOrCreateMonth(2026, 8);
    // The fund's 100.00 is paid in full, so only food's 100.00 carries over.
    expect(august.carryOverCents, 10000);
    final augustBudgets = await db.watchBudgets(august.id).first;
    final augustInsurance = augustBudgets.last;
    expect(augustInsurance.isSinkingFund, isTrue);
    expect(augustInsurance.savedCents, 7500);
    expect(augustBudgets.first.savedCents, 0);

    // Spending more than this month's share uses the savings, not the month.
    await db.addExpense(augustInsurance.id, 15000);
    await db.addExpense(augustBudgets.first.id, 90000);
    final september = await db.getOrCreateMonth(2026, 9);
    // 1000.00 income + 100.00 carried over - 900.00 food - 100.00 fund.
    expect(september.carryOverCents, 10000);
    expect((await db.watchBudgets(september.id).first).last.savedCents, 2500);
  });

  test('a copied month is set up by picking the budgets to keep', () async {
    final august = await db.getOrCreateMonth(2026, 8);
    expect(august.needsSetUp, isFalse);
    await db.addIncome(august.id, 'Salary', 100000);
    await db.addBudget(august.id, 'Food', 40000);
    await db.addBudget(august.id, 'Gym', 3000);
    await db.addBudget(august.id, 'Insurance', 10000, isSinkingFund: true);

    final september = await db.getOrCreateMonth(2026, 9);
    expect(september.needsSetUp, isTrue);
    // Nothing spent in August: the food and the gym carry over.
    expect(september.carryOverCents, 43000 + 100000 - 53000);
    final budgets = await db.watchBudgets(september.id).first;
    final food = budgets.firstWhere((b) => b.name == 'Food');

    await db.setUpMonth(september.id, {food.id});

    final setUp = await db.watchMonth(september.id).first;
    expect(setUp.needsSetUp, isFalse);
    expect((await db.watchBudgets(september.id).first).map((b) => b.name), [
      'Food',
    ]);
    // The fund's 100.00 saved in August goes back into September.
    expect(setUp.carryOverCents, 90000 + 10000);
    expect(await db.watchIncomes(september.id).first, hasLength(1));
  });

  test('a sinking fund that stops being one releases its savings', () async {
    final august = await db.getOrCreateMonth(2026, 8);
    await db.addBudget(august.id, 'Insurance', 10000, isSinkingFund: true);
    final september = await db.getOrCreateMonth(2026, 9);
    final insurance = (await db.watchBudgets(september.id).first).single;
    expect(insurance.savedCents, 10000);
    expect(september.carryOverCents, -10000);

    await db.updateBudget(
      insurance.id,
      name: 'Insurance',
      amountCents: 10000,
      isFixed: false,
    );

    final budget = (await db.watchBudgets(september.id).first).single;
    expect((budget.isSinkingFund, budget.savedCents), (false, 0));
    expect((await db.watchMonth(september.id).first).carryOverCents, 0);
  });

  test('deleting a sinking fund releases its savings', () async {
    final august = await db.getOrCreateMonth(2026, 8);
    await db.addIncome(august.id, 'Salary', 10000);
    await db.addBudget(august.id, 'Insurance', 10000, isSinkingFund: true);
    final september = await db.getOrCreateMonth(2026, 9);
    expect(september.carryOverCents, 0);

    final insurance = (await db.watchBudgets(september.id).first).single;
    await db.deleteBudget(insurance.id);

    expect((await db.watchMonth(september.id).first).carryOverCents, 10000);
  });

  test('month notes are saved trimmed and removed when blank', () async {
    final month = await db.getOrCreateMonth(2026, 9);
    Future<String?> notes() async =>
        (await db.watchMonth(month.id).first).notes;
    expect(await notes(), isNull);

    await db.updateMonthNotes(month.id, '  Save for the holiday\n');
    expect(await notes(), 'Save for the holiday');

    // A new month starts with notes of its own.
    expect((await db.getOrCreateMonth(2026, 10)).notes, isNull);

    await db.updateMonthNotes(month.id, '   ');
    expect(await notes(), isNull);
  });

  test('the debug bar shows until it is turned off', () async {
    expect((await db.watchSettings().first).showDebugBar, isTrue);

    await db.setShowDebugBar(false);
    final settings = await db.watchSettings().first;
    expect(settings.showDebugBar, isFalse);
    // Other settings are left alone.
    expect(settings.bufferCents, defaultBufferCents);
  });

  test('the buffer defaults to 1000 and can be changed', () async {
    expect(await db.watchBufferCents().first, 100000);

    await db.setBufferCents(50000);
    expect(await db.watchBufferCents().first, 50000);
    await db.setBufferCents(0);
    expect(await db.watchBufferCents().first, 0);
    expect(await db.select(db.settings).get(), hasLength(1));
  });

  test('the bank balance follows the money across months', () async {
    final august = await db.getOrCreateMonth(2026, 8);
    await db.addIncome(august.id, 'Salary', 300000);
    await db.addBudget(august.id, 'Rent', 120000, isFixed: true);
    final food = await db.addBudget(august.id, 'Food', 40000);
    await db.addBudget(august.id, 'Insurance', 20000, isSinkingFund: true);
    await db.lockMonth(august.id);
    await db.addExpense(food, 5000);

    Future<int> balanceCents(int monthId) async => expectedBankBalanceCents(
      await db.watchMonth(monthId).first,
      await db.watchBudgets(monthId).first,
      await db.watchExpenses(monthId).first,
      bufferCents: 100000,
    );

    // 1000.00 buffer + 3000.00 income - 1200.00 rent - 50.00 food.
    expect(await balanceCents(august.id), 275000);

    // The new month starts from what was left, with the insurance savings
    // still in the account, plus its own income.
    final september = await db.getOrCreateMonth(2026, 9);
    expect(await balanceCents(september.id), 275000 + 300000);
  });

  test("copying the month before replaces the month's plan", () async {
    final september = await db.getOrCreateMonth(2026, 9);
    final october = await db.getOrCreateMonth(2026, 10);
    await db.addIncome(october.id, 'Old income', 1000);
    final old = await db.addBudget(october.id, 'Old budget', 1000);
    await db.lockMonth(october.id);
    await db.addExpense(old, 500);
    await db.updateMonthNotes(october.id, 'Keep me');
    // September is planned only after October was created.
    await db.addIncome(september.id, 'Salary', 300000);
    final food = await db.addBudget(september.id, 'Food', 40000);
    await db.addBudget(september.id, 'Rent', 120000, isFixed: true);
    await db.lockMonth(september.id);
    await db.addExpense(food, 5000);

    expect(await db.copyPlanFromMonthBefore(october.id), isTrue);

    final copied = await db.watchMonth(october.id).first;
    expect(copied.incomeCents, 300000);
    // 3000.00 income - 1200.00 fixed rent - 50.00 food.
    expect(copied.carryOverCents, 175000);
    expect(copied.lockedAt, isNull);
    expect(copied.notes, 'Keep me');
    final incomes = await db.watchIncomes(october.id).first;
    expect(incomes.map((i) => (i.name, i.amountCents)), [('Salary', 300000)]);
    final budgets = await db.watchBudgets(october.id).first;
    expect(budgets.map((b) => (b.name, b.amountCents, b.isFixed)), [
      ('Food', 40000, false),
      ('Rent', 120000, true),
    ]);
    expect(await db.watchExpenses(october.id).first, isEmpty);
    // September itself is left alone.
    expect(await db.watchBudgets(september.id).first, hasLength(2));
    expect(await db.watchExpenses(september.id).first, hasLength(2));

    // The first month has nothing to copy from.
    expect(await db.copyPlanFromMonthBefore(september.id), isFalse);
    expect(await db.watchBudgets(september.id).first, hasLength(2));
  });

  test('carryovers follow later changes to the months before', () async {
    final august = await db.getOrCreateMonth(2026, 8);
    await db.addIncome(august.id, 'Salary', 300000);
    final food = await db.addBudget(august.id, 'Food', 40000);
    final september = await db.getOrCreateMonth(2026, 9);
    final october = await db.getOrCreateMonth(2026, 10);
    Future<int> carryOverCents(Month month) async =>
        (await db.watchMonth(month.id).first).carryOverCents;
    expect(await carryOverCents(september), 300000);
    expect(await carryOverCents(october), 600000);

    final groceries = await db.addExpense(food, 5000);
    expect(await carryOverCents(september), 295000);
    expect(await carryOverCents(october), 595000);

    await db.addIncome(august.id, 'Bonus', 10000);
    expect(await carryOverCents(october), 605000);
    await db.updateBudget(
      food,
      name: 'Food',
      amountCents: 40000,
      isFixed: false,
      isSinkingFund: true,
    );
    // The whole sinking fund amount stays in the fund.
    expect(await carryOverCents(september), 270000);
    await db.deleteBudget(food);
    expect(await carryOverCents(september), 310000);

    // The plan of a month in between counts too.
    final rent = await db.addBudget(september.id, 'Rent', 120000);
    expect(await carryOverCents(october), 610000);
    await db.updateBudget(
      rent,
      name: 'Rent',
      amountCents: 120000,
      isFixed: true,
    );
    await db.lockMonth(september.id);
    expect(await carryOverCents(october), 490000);
    await db.deleteExpense(groceries);
    expect(await carryOverCents(october), 490000);
  });

  test('corrections to the carryover are kept as it changes', () async {
    final september = await db.getOrCreateMonth(2026, 9);
    await db.addIncome(september.id, 'Salary', 300000);
    final food = await db.addBudget(september.id, 'Food', 40000);
    final october = await db.getOrCreateMonth(2026, 10);
    Future<Month> octoberNow() => db.watchMonth(october.id).first;

    // 50.00 more was spent than tracked.
    await db.setCarryOverCents(october.id, 295000);
    expect((await octoberNow()).carryOverAdjustmentCents, -5000);

    await db.addExpense(food, 2500);
    expect((await octoberNow()).carryOverCents, 292500);

    // Correcting it again replaces the correction, down into the negative.
    await db.setCarryOverCents(october.id, -2550);
    expect((await octoberNow()).carryOverCents, -2550);
    expect((await octoberNow()).carryOverAdjustmentCents, -300050);

    // The first month has nothing before it, so it carries over just that.
    await db.setCarryOverCents(september.id, 10000);
    expect((await db.watchMonth(september.id).first).carryOverCents, 10000);
    expect((await octoberNow()).carryOverCents, 7450);

    // Copying the plan again starts over without corrections.
    await db.copyPlanFromMonthBefore(october.id);
    expect((await octoberNow()).carryOverAdjustmentCents, 0);
    expect((await octoberNow()).carryOverCents, 307500);
  });

  test('getOrCreateMonth reuses the existing month', () async {
    final first = await db.getOrCreateMonth(2026, 9);
    final second = await db.getOrCreateMonth(2026, 9);

    expect(second.id, first.id);
    expect(first.incomeCents, 0);
  });

  test('deleting a month deletes its budgets', () async {
    final month = await db.getOrCreateMonth(2026, 9);
    await db.addBudget(month.id, 'Rent', 120000);

    await (db.delete(db.months)..where((m) => m.id.equals(month.id))).go();

    expect(await db.select(db.budgets).get(), isEmpty);
  });

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

  test('hasMonthBefore is true once an earlier month exists', () async {
    final september = await db.getOrCreateMonth(2026, 9);
    expect(await db.hasMonthBefore(september.id), isFalse);

    final october = await db.getOrCreateMonth(2026, 10);
    expect(await db.hasMonthBefore(october.id), isTrue);
    expect(await db.hasMonthBefore(september.id), isFalse);
  });

  test('setBudgetByName adds, updates and removes a budget by name', () async {
    final month = await db.getOrCreateMonth(2026, 9);
    Future<List<(String, int, bool)>> budgets() async => [
      for (final b in await db.watchBudgets(month.id).first)
        (b.name, b.amountCents, b.isFixed),
    ];

    await db.setBudgetByName(month.id, 'Giving', 0);
    expect(await budgets(), isEmpty);

    await db.setBudgetByName(month.id, 'Giving', 5000, isFixed: true);
    await db.setBudgetByName(month.id, 'Rent', 90000, isFixed: true);
    expect(await budgets(), [('Giving', 5000, true), ('Rent', 90000, true)]);

    // Matched ignoring case, keeping its name and kind.
    await db.updateBudget(
      (await db.watchBudgets(month.id).first).first.id,
      name: 'giving',
      amountCents: 5000,
      isFixed: false,
    );
    await db.setBudgetByName(month.id, 'Giving', 7000, isFixed: true);
    expect(await budgets(), [('giving', 7000, false), ('Rent', 90000, true)]);

    await db.setBudgetByName(month.id, 'Giving', 0);
    expect(await budgets(), [('Rent', 90000, true)]);
  });

  test('setBudgetByName gives a budget without a category one', () async {
    final month = await db.getOrCreateMonth(2026, 9);
    await db.addBudget(month.id, 'Nest egg', 10000);
    await db.addBudget(
      month.id,
      'Rent',
      90000,
      category: BudgetCategory.giving,
    );
    await db.addBudget(month.id, 'Fund', 5000, isSinkingFund: true);

    await db.setBudgetByName(
      month.id,
      'Savings',
      20000,
      isFixed: true,
      category: BudgetCategory.savings,
    );
    await db.setBudgetByName(
      month.id,
      'Nest egg',
      15000,
      category: BudgetCategory.savings,
    );
    // Keeps the category it has, and a sinking fund is never savings.
    await db.setBudgetByName(
      month.id,
      'Rent',
      95000,
      category: BudgetCategory.essential,
    );
    await db.setBudgetByName(
      month.id,
      'Fund',
      6000,
      category: BudgetCategory.savings,
    );

    final budgets = await db.watchBudgets(month.id).first;
    expect(budgets.map((b) => (b.name, b.amountCents, b.isFixed, b.category)), [
      ('Nest egg', 15000, false, BudgetCategory.savings),
      ('Rent', 95000, false, BudgetCategory.giving),
      ('Fund', 6000, false, BudgetCategory.other),
      ('Savings', 20000, true, BudgetCategory.savings),
    ]);
  });

  test('setBudgetByName keeps a budget with tracked expenses at 0', () async {
    final month = await db.getOrCreateMonth(2026, 9);
    final groceries = await db.addBudget(month.id, 'Groceries', 40000);
    await db.addExpense(groceries, 2500, title: 'Market');

    await db.setBudgetByName(month.id, 'Groceries', 0);

    final budgets = await db.watchBudgets(month.id).first;
    expect(budgets.map((b) => (b.name, b.amountCents)), [('Groceries', 0)]);
    expect(await db.watchExpenses(month.id).first, hasLength(1));
  });

  test(
    'updateExpense changes an expense and what the month carries over',
    () async {
      final september = await db.getOrCreateMonth(2026, 9);
      await db.addIncome(september.id, 'Salary', 100000);
      final food = await db.addBudget(september.id, 'Food', 40000);
      final fun = await db.addBudget(september.id, 'Fun', 10000);
      final id = await db.addExpense(food, 5000, title: 'Market', note: 'Cash');
      final october = await db.getOrCreateMonth(2026, 10);

      await db.updateExpense(
        id,
        budgetId: fun,
        amountCents: 7000,
        title: 'Cinema',
        note: null,
      );

      final expense = (await db.watchExpenses(september.id).first).single;
      expect(
        (expense.budgetId, expense.amountCents, expense.title, expense.note),
        (fun, 7000, 'Cinema', null),
      );
      expect((await db.watchMonth(october.id).first).carryOverCents, 93000);
    },
  );

  test(
    'a custom order is kept, new budgets go last, new months copy it',
    () async {
      final september = await db.getOrCreateMonth(2026, 9);
      final rent = await db.addBudget(september.id, 'Rent', 90000);
      final food = await db.addBudget(september.id, 'Food', 40000);
      final fun = await db.addBudget(september.id, 'Fun', 10000);

      await db.setCustomBudgetOrder([fun, rent, food]);
      final car = await db.addBudget(september.id, 'Car', 5000);

      expect((await db.watchSettings().first).budgetOrder, BudgetOrder.custom);
      final ordered = (await db.watchBudgets(september.id).first).toList()
        ..sort((a, b) => a.position.compareTo(b.position));
      expect(ordered.map((b) => b.id), [fun, rent, food, car]);

      final october = await db.getOrCreateMonth(2026, 10);
      final copied = (await db.watchBudgets(october.id).first).toList()
        ..sort((a, b) => a.position.compareTo(b.position));
      expect(copied.map((b) => b.name), ['Fun', 'Rent', 'Food', 'Car']);
    },
  );

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
    addTearDown(() => currency = Currency.eur);
    currency = Currency.usd;
    expect(formatCents(123450), r'$1234.50');
    expect(formatCents(-2500), r'-$25.00');
    currency = Currency.gbp;
    expect(formatCents(5), '£0.05');
    currency = Currency.chf;
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
