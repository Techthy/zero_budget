import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/data/database_provider.dart';
import 'package:zero_budget/money.dart';
import 'package:zero_budget/welcome/welcome_providers.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('updateBudget changes only that budget', () async {
    final month = await db.getOrCreateMonth(2026, 9);
    final rent = await db.addBudget(month.id, 'Rent', 120000);
    await db.addBudget(month.id, 'Food', 40000);

    await db.updateBudget(rent,
        name: 'Rent & bills', amountCents: 125000, isFixed: true);

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
    await db.updateBudget((await db.watchBudgets(august.id).first).single.id,
        name: 'Rent', amountCents: 120000, isFixed: true);
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
    expect((fixed.budgetId, fixed.amountCents, fixed.isFixed),
        (rent, 120000, true));

    // Locking in again after an edit updates instead of duplicating.
    await db.unlockMonth(month.id);
    await db.updateBudget(rent,
        name: 'Rent', amountCents: 125000, isFixed: true);
    await db.lockMonth(month.id);
    expect((await db.watchExpenses(month.id).first).single.amountCents, 125000);

    // A budget that's no longer fixed loses its fixed expense.
    await db.unlockMonth(month.id);
    await db.updateBudget(rent,
        name: 'Rent', amountCents: 125000, isFixed: false);
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
    if (version < 8 && version >= 2) {
      await old.customStatement('ALTER TABLE expenses DROP COLUMN title');
    }
    if (version < 7) {
      await old
          .customStatement('ALTER TABLE budgets DROP COLUMN is_sinking_fund');
      await old.customStatement('ALTER TABLE budgets DROP COLUMN saved_cents');
    }
    if (version < 6) await old.customStatement('DROP TABLE incomes');
    if (version < 5) {
      await old
          .customStatement('ALTER TABLE months DROP COLUMN carry_over_cents');
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

  for (final version in [1, 2, 3, 4, 5, 6, 7]) {
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
    });
  }

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
          'UPDATE months SET income_cents = 0 WHERE year = 2026 AND month = 10');
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
    final julyInsurance =
        await db.addBudget(july.id, 'Insurance', 10000, isSinkingFund: true);
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

  test('a sinking fund that stops being one releases its savings', () async {
    final august = await db.getOrCreateMonth(2026, 8);
    await db.addBudget(august.id, 'Insurance', 10000, isSinkingFund: true);
    final september = await db.getOrCreateMonth(2026, 9);
    final insurance = (await db.watchBudgets(september.id).first).single;
    expect(insurance.savedCents, 10000);
    expect(september.carryOverCents, -10000);

    await db.updateBudget(insurance.id,
        name: 'Insurance', amountCents: 10000, isFixed: false);

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

    expect((await container.read(currentMonthProvider.future)).incomeCents,
        300000);
    final budgets = await container.read(currentBudgetsProvider.future);
    expect(budgets.single.name, 'Rent');
  });

  test('the month offset moves the current month across years', () async {
    final now = DateTime.now();
    final container = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    container.listen(currentMonthProvider, (_, _) {});
    final offset = container.read(monthOffsetProvider.notifier);

    // Back to December of last year.
    for (var i = 0; i < now.month; i++) {
      offset.previous();
    }
    expect(container.read(currentYearMonthProvider),
        (year: now.year - 1, month: 12));
    final december = await container.read(currentMonthProvider.future);
    expect((december.year, december.month), (now.year - 1, 12));

    offset.reset();
    offset.next();
    final next = DateTime(now.year, now.month + 1);
    expect(container.read(currentYearMonthProvider),
        (year: next.year, month: next.month));
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
    expect(formatCents(123450), '1234.50');
    expect(formatCents(5), '0.05');
    expect(formatCents(-2500), '-25.00');
  });
}
