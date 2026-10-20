import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/data/month_math.dart';

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
}
