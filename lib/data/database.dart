import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.drift.dart';

// All money is stored as whole cents to avoid floating point rounding errors.

class Months extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get year => integer()();
  IntColumn get month => integer()();

  /// Total of the month's incomes, kept in sync whenever one changes.
  IntColumn get incomeCents => integer().withDefault(const Constant(0))();

  /// When the plan was locked in to track spending; null while planning.
  DateTimeColumn get lockedAt => dateTime().nullable()();

  /// Balance left from the month before (negative if it was overspent), which
  /// is available to assign on top of the income.
  IntColumn get carryOverCents => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {year, month},
      ];
}

/// One source of money coming in during the month, like a salary.
class Incomes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get monthId =>
      integer().references(Months, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get amountCents => integer()();
}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get monthId =>
      integer().references(Months, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get amountCents => integer()();

  /// Fixed budgets, like rent, are always spent in full.
  BoolColumn get isFixed => boolean().withDefault(const Constant(false))();

  /// Sinking funds save up for costs that don't come every month, like a
  /// yearly insurance fee. The amount is paid into the fund in full, and
  /// whatever isn't spent carries over to the fund next month.
  BoolColumn get isSinkingFund =>
      boolean().withDefault(const Constant(false))();

  /// What a sinking fund had saved before this month; always 0 for other
  /// budgets.
  IntColumn get savedCents => integer().withDefault(const Constant(0))();
}

/// Money actually spent, entered manually against one of the month's budgets.
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get budgetId =>
      integer().references(Budgets, #id, onDelete: KeyAction.cascade)();
  IntColumn get amountCents => integer()();

  /// What the money was spent on. Required when entering an expense; fixed
  /// expenses go without.
  TextColumn get title => text().withLength(min: 1, max: 100).nullable()();

  TextColumn get note => text().withLength(max: 100).nullable()();
  DateTimeColumn get spentAt => dateTime().withDefault(currentDateAndTime)();

  /// Created automatically when the plan is locked in, spending a fixed
  /// budget in full.
  BoolColumn get isFixed => boolean().withDefault(const Constant(false))();
}

/// A month with the totals of its budgets and expenses.
typedef MonthSummary = ({Month month, int plannedCents, int spentCents});

/// What can be spent from [budget] this month, including a sinking fund's
/// savings.
int availableCents(Budget budget) => budget.amountCents + budget.savedCents;

/// What a sinking fund has saved once [spentCents] came out of it this month.
int fundBalanceCents(Budget budget, int spentCents) =>
    availableCents(budget) - spentCents;

/// What's left of the month's money at its end, which carries over to the
/// next month.
///
/// Sinking funds count as spent in full: their money stays in the fund.
int monthBalanceCents(
  Month month,
  List<Budget> budgets,
  Map<int, int> spentByBudget,
) {
  var balanceCents = month.incomeCents + month.carryOverCents;
  for (final budget in budgets) {
    balanceCents -= budget.isSinkingFund
        ? budget.amountCents
        : spentByBudget[budget.id] ?? 0;
  }
  return balanceCents;
}

/// Sums [expenses] per budget id.
Map<int, int> spentByBudget(Iterable<Expense> expenses) {
  final spent = <int, int>{};
  for (final expense in expenses) {
    spent.update(
      expense.budgetId,
      (sum) => sum + expense.amountCents,
      ifAbsent: () => expense.amountCents,
    );
  }
  return spent;
}

@DriftDatabase(tables: [Months, Incomes, Budgets, Expenses])
class AppDatabase extends _$AppDatabase {
  // Pass an executor (e.g. NativeDatabase.memory()) to use an in-memory
  // database in tests.
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'zero_budget'));

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(expenses);
          if (from < 3) await m.addColumn(months, months.lockedAt);
          if (from < 4) {
            await m.addColumn(budgets, budgets.isFixed);
            // Before version 2 the expenses table was just created in full.
            if (from >= 2) await m.addColumn(expenses, expenses.isFixed);
          }
          if (from < 5) await m.addColumn(months, months.carryOverCents);
          if (from < 6) {
            await m.createTable(incomes);
            // Each month had a single income before.
            await customStatement(
              "INSERT INTO incomes (month_id, name, amount_cents) "
              "SELECT id, 'Income', income_cents FROM months "
              'WHERE income_cents > 0',
            );
          }
          if (from < 7) {
            await m.addColumn(budgets, budgets.isSinkingFund);
            await m.addColumn(budgets, budgets.savedCents);
          }
          if (from < 8) {
            // Before version 2 the expenses table was just created in full.
            if (from >= 2) await m.addColumn(expenses, expenses.title);
            // Notes were shown as the expense's title before.
            await customStatement(
              'UPDATE expenses SET title = note, note = NULL '
              'WHERE note IS NOT NULL',
            );
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Returns the row for [year]/[month], creating it if it doesn't exist yet.
  ///
  /// A new month uses the latest earlier month as its template, starting with
  /// the same incomes and budgets, and carries over that month's balance.
  /// Sinking funds carry over their own savings.
  Future<Month> getOrCreateMonth(int year, int month) => transaction(() async {
        final query = select(months)
          ..where((m) => m.year.equals(year) & m.month.equals(month));
        final existing = await query.getSingleOrNull();
        if (existing != null) return existing;

        final template = await (select(months)
              ..where((m) =>
                  m.year.isSmallerThanValue(year) |
                  (m.year.equals(year) & m.month.isSmallerThanValue(month)))
              ..orderBy([
                (m) => OrderingTerm.desc(m.year),
                (m) => OrderingTerm.desc(m.month),
              ])
              ..limit(1))
            .getSingleOrNull();

        final templateBudgets = template == null
            ? const <Budget>[]
            : await (select(budgets)
                  ..where((b) => b.monthId.equals(template.id))
                  ..orderBy([(b) => OrderingTerm.asc(b.id)]))
                .get();
        final templateSpent = template == null
            ? const <int, int>{}
            : spentByBudget(await _expensesOfMonth(template.id).get());
        final carryOverCents = template == null
            ? 0
            : monthBalanceCents(template, templateBudgets, templateSpent);
        final monthId = await into(months).insert(
          MonthsCompanion.insert(
            year: year,
            month: month,
            incomeCents: Value(template?.incomeCents ?? 0),
            carryOverCents: Value(carryOverCents),
          ),
        );
        if (template != null) {
          final templateIncomes = await (select(incomes)
                ..where((i) => i.monthId.equals(template.id))
                ..orderBy([(i) => OrderingTerm.asc(i.id)]))
              .get();
          for (final income in templateIncomes) {
            await into(incomes).insert(
              IncomesCompanion.insert(
                monthId: monthId,
                name: income.name,
                amountCents: income.amountCents,
              ),
            );
          }
          for (final budget in templateBudgets) {
            await into(budgets).insert(
              BudgetsCompanion.insert(
                monthId: monthId,
                name: budget.name,
                amountCents: budget.amountCents,
                isFixed: Value(budget.isFixed),
                isSinkingFund: Value(budget.isSinkingFund),
                savedCents: Value(budget.isSinkingFund
                    ? fundBalanceCents(budget, templateSpent[budget.id] ?? 0)
                    : 0),
              ),
            );
          }
        }
        return query.getSingle();
      });

  /// Every month, newest first, with its planned and spent totals.
  Stream<List<MonthSummary>> watchMonthSummaries() {
    // Subqueries instead of joins so budgets aren't counted once per expense.
    return customSelect(
      'SELECT m.*, '
      '(SELECT COALESCE(SUM(b.amount_cents), 0) FROM budgets b '
      'WHERE b.month_id = m.id) AS planned_cents, '
      '(SELECT COALESCE(SUM(e.amount_cents), 0) FROM expenses e '
      'INNER JOIN budgets b ON b.id = e.budget_id '
      'WHERE b.month_id = m.id) AS spent_cents '
      'FROM months m ORDER BY m.year DESC, m.month DESC',
      readsFrom: {months, budgets, expenses},
    ).watch().map((rows) => [
          for (final row in rows)
            (
              month: months.map(row.data),
              plannedCents: row.read<int>('planned_cents'),
              spentCents: row.read<int>('spent_cents'),
            ),
        ]);
  }

  Stream<Month> watchMonth(int monthId) =>
      (select(months)..where((m) => m.id.equals(monthId))).watchSingle();

  Stream<List<Income>> watchIncomes(int monthId) => (select(incomes)
        ..where((i) => i.monthId.equals(monthId))
        ..orderBy([(i) => OrderingTerm.asc(i.id)]))
      .watch();

  Future<int> addIncome(int monthId, String name, int amountCents) =>
      transaction(() async {
        final id = await into(incomes).insert(
          IncomesCompanion.insert(
            monthId: monthId,
            name: name,
            amountCents: amountCents,
          ),
        );
        await _syncIncomeTotal(monthId);
        return id;
      });

  Future<void> updateIncome(
    int id, {
    required String name,
    required int amountCents,
  }) =>
      transaction(() async {
        final query = update(incomes)..where((i) => i.id.equals(id));
        final updated = await query.writeReturning(
          IncomesCompanion(name: Value(name), amountCents: Value(amountCents)),
        );
        for (final income in updated) {
          await _syncIncomeTotal(income.monthId);
        }
      });

  Future<void> deleteIncome(int id) => transaction(() async {
        final query = delete(incomes)..where((i) => i.id.equals(id));
        final deleted = await query.goAndReturn();
        for (final income in deleted) {
          await _syncIncomeTotal(income.monthId);
        }
      });

  Future<void> _syncIncomeTotal(int monthId) async {
    final total = incomes.amountCents.sum();
    final incomeCents = await (selectOnly(incomes)
          ..where(incomes.monthId.equals(monthId))
          ..addColumns([total]))
        .map((row) => row.read(total))
        .getSingle();
    await (update(months)..where((m) => m.id.equals(monthId)))
        .write(MonthsCompanion(incomeCents: Value(incomeCents ?? 0)));
  }

  /// Locks the month's plan in so spending can be tracked against it.
  ///
  /// Each fixed budget is spent in full by one fixed expense, which is kept in
  /// sync with the budget whenever the plan is locked in again.
  Future<void> lockMonth(int monthId) => transaction(() async {
        final monthBudgets = await (select(budgets)
              ..where((b) => b.monthId.equals(monthId)))
            .get();
        for (final budget in monthBudgets) {
          final fixedExpense = expenses.budgetId.equals(budget.id) &
              expenses.isFixed.equals(true);
          if (!budget.isFixed) {
            await (delete(expenses)..where((_) => fixedExpense)).go();
            continue;
          }
          final updated = await (update(expenses)..where((_) => fixedExpense))
              .write(ExpensesCompanion(amountCents: Value(budget.amountCents)));
          if (updated == 0) {
            await into(expenses).insert(
              ExpensesCompanion.insert(
                budgetId: budget.id,
                amountCents: budget.amountCents,
                isFixed: const Value(true),
              ),
            );
          }
        }
        await (update(months)..where((m) => m.id.equals(monthId)))
            .write(MonthsCompanion(lockedAt: Value(DateTime.now())));
      });

  /// Unlocks the month's plan for editing. Tracked expenses are kept.
  Future<void> unlockMonth(int monthId) =>
      (update(months)..where((m) => m.id.equals(monthId)))
          .write(const MonthsCompanion(lockedAt: Value(null)));

  Stream<List<Budget>> watchBudgets(int monthId) => (select(budgets)
        ..where((b) => b.monthId.equals(monthId))
        ..orderBy([(b) => OrderingTerm.asc(b.id)]))
      .watch();

  Future<int> addBudget(
    int monthId,
    String name,
    int amountCents, {
    bool isFixed = false,
    bool isSinkingFund = false,
  }) {
    assert(!(isFixed && isSinkingFund), 'A sinking fund is never fixed');
    return into(budgets).insert(
      BudgetsCompanion.insert(
        monthId: monthId,
        name: name,
        amountCents: amountCents,
        isFixed: Value(isFixed),
        isSinkingFund: Value(isSinkingFund),
      ),
    );
  }

  /// Updates the budget. Turning a sinking fund into a regular budget releases
  /// its savings back into the month.
  Future<void> updateBudget(
    int id, {
    required String name,
    required int amountCents,
    required bool isFixed,
    bool isSinkingFund = false,
  }) {
    assert(!(isFixed && isSinkingFund), 'A sinking fund is never fixed');
    return transaction(() async {
      if (!isSinkingFund) await _releaseSavings(id);
      await (update(budgets)..where((b) => b.id.equals(id))).write(
        BudgetsCompanion(
          name: Value(name),
          amountCents: Value(amountCents),
          isFixed: Value(isFixed),
          isSinkingFund: Value(isSinkingFund),
        ),
      );
    });
  }

  /// Deletes the budget and its expenses. A sinking fund's savings go back
  /// into the month.
  Future<void> deleteBudget(int id) => transaction(() async {
        await _releaseSavings(id);
        await (delete(budgets)..where((b) => b.id.equals(id))).go();
      });

  /// Moves a budget's savings into its month's carryover, so they're available
  /// to assign again.
  Future<void> _releaseSavings(int budgetId) async {
    final budget = await (select(budgets)..where((b) => b.id.equals(budgetId)))
        .getSingleOrNull();
    if (budget == null || budget.savedCents == 0) return;
    await customUpdate(
      'UPDATE months SET carry_over_cents = carry_over_cents + ? '
      'WHERE id = ?',
      variables: [
        Variable.withInt(budget.savedCents),
        Variable.withInt(budget.monthId),
      ],
      updates: {months},
    );
    await (update(budgets)..where((b) => b.id.equals(budgetId)))
        .write(const BudgetsCompanion(savedCents: Value(0)));
  }

  /// Expenses from all budgets of the month, newest first.
  Stream<List<Expense>> watchExpenses(int monthId) =>
      _expensesOfMonth(monthId).watch();

  Selectable<Expense> _expensesOfMonth(int monthId) {
    final query = select(expenses).join([
      innerJoin(budgets, budgets.id.equalsExp(expenses.budgetId)),
    ])
      ..where(budgets.monthId.equals(monthId))
      ..orderBy([
        OrderingTerm.desc(expenses.spentAt),
        OrderingTerm.desc(expenses.id),
      ]);
    return query.map((row) => row.readTable(expenses));
  }

  Future<int> addExpense(
    int budgetId,
    int amountCents, {
    String? title,
    String? note,
  }) =>
      into(expenses).insert(
        ExpensesCompanion.insert(
          budgetId: budgetId,
          amountCents: amountCents,
          title: Value(title),
          note: Value(note),
        ),
      );

  Future<void> deleteExpense(int id) =>
      (delete(expenses)..where((e) => e.id.equals(id))).go();
}
