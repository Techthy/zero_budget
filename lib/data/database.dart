import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../dates.dart';

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
  ///
  /// Kept in sync with the month before whenever anything changes, plus
  /// [carryOverAdjustmentCents].
  IntColumn get carryOverCents => integer().withDefault(const Constant(0))();

  /// Added to what the month before left: manual corrections, and savings
  /// released from sinking funds.
  IntColumn get carryOverAdjustmentCents =>
      integer().withDefault(const Constant(0))();

  /// Free-form notes about the month's plan, like goals or things to take
  /// care of; null when there are none.
  TextColumn get notes => text().nullable()();

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

  /// What the budget is for. Savings budgets count towards the savings goal,
  /// see [BudgetCategory.savings].
  TextColumn get category => textEnum<BudgetCategory>()
      .withDefault(Constant(BudgetCategory.other.name))();

  /// Where the budget goes among the month's budgets in the custom order,
  /// lowest first; see [BudgetOrder.custom]. New budgets go last.
  IntColumn get position => integer().withDefault(const Constant(0))();
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

/// App-wide settings, kept in a single row.
class Settings extends Table {
  /// Always [settingsRowId].
  IntColumn get id => integer()();

  /// Money always kept in the bank account on top of the plan, as a safety
  /// net.
  IntColumn get bufferCents =>
      integer().withDefault(const Constant(defaultBufferCents))();

  /// The month the user works in, see [encodeYearMonth]; null until the app
  /// first opens.
  IntColumn get selectedYearMonth => integer().nullable()();

  /// The latest month the user was offered to move on to, or chose to be in,
  /// see [encodeYearMonth]. Each new month is offered only once.
  IntColumn get offeredYearMonth => integer().nullable()();

  /// Whether debug builds show the bar to move through days and months.
  BoolColumn get showDebugBar => boolean().withDefault(const Constant(true))();

  /// What to save in each [savingsGoalPeriod]; null while there's no goal.
  IntColumn get savingsGoalCents => integer().nullable()();

  TextColumn get savingsGoalPeriod => textEnum<SavingsPeriod>()
      .withDefault(Constant(SavingsPeriod.year.name))();

  /// Whether the app is shown light, dark, or following the system.
  TextColumn get appearance => textEnum<Appearance>()
      .withDefault(Constant(Appearance.system.name))();

  /// How budgets are listed on the plan and while tracking.
  TextColumn get budgetOrder => textEnum<BudgetOrder>()
      .withDefault(Constant(BudgetOrder.category.name))();

  @override
  Set<Column> get primaryKey => {id};
}

/// How long the savings goal runs before it starts over.
enum SavingsPeriod { quarter, year }

/// What a budget is for, see [Budgets.category]. [BudgetOrder.category]
/// lists budgets in this order.
enum BudgetCategory {
  /// Given away, like to a charity or a church. Comes first in the plan.
  giving,

  /// Needed to live and work, like rent, utilities, groceries and
  /// transportation.
  essential,

  /// Counts towards the savings goal with what's spent from it, like a
  /// transfer to a savings account. It can be fixed, but never a sinking
  /// fund.
  savings,

  /// Everything else.
  other,
}

/// Light or dark colours for the app, see [Settings.appearance].
enum Appearance { system, light, dark }

/// How budgets are listed, see [Settings.budgetOrder].
enum BudgetOrder {
  /// By [BudgetCategory], like in the guided planning.
  /// Shown as "Recommended".
  category,

  /// All from A to Z.
  alphabetical,

  /// In the order the user dragged them into, see [Budgets.position].
  custom,
}

const settingsRowId = 1;
const defaultBufferCents = 100000;

/// A month with the totals of its budgets and expenses.
typedef MonthSummary = ({Month month, int plannedCents, int spentCents});

/// What a month's savings budgets spent.
typedef MonthSavings = ({YearMonth month, int savedCents});

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

/// What should be in the bank account right now: the buffer, plus the
/// month's income and carryover and whatever sinking funds saved before, minus
/// everything spent so far.
///
/// Assumes all of the month's income has come in already.
int expectedBankBalanceCents(
  Month month,
  List<Budget> budgets,
  Iterable<Expense> expenses, {
  required int bufferCents,
}) {
  var balanceCents = bufferCents + month.incomeCents + month.carryOverCents;
  for (final budget in budgets) {
    balanceCents += budget.savedCents;
  }
  for (final expense in expenses) {
    balanceCents -= expense.amountCents;
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

@DriftDatabase(tables: [Months, Incomes, Budgets, Expenses, Settings])
class AppDatabase extends _$AppDatabase {
  // Pass an executor (e.g. NativeDatabase.memory()) to use an in-memory
  // database in tests.
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'zero_budget'));

  @override
  int get schemaVersion => 18;

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
          if (from < 9) await m.addColumn(months, months.notes);
          if (from < 10) await m.createTable(settings);
          // Before version 10 the settings table was just created in full.
          if (from == 10) {
            await m.addColumn(settings, settings.selectedYearMonth);
            await m.addColumn(settings, settings.offeredYearMonth);
          }
          // Added out of order, as syncing the carryovers below reads whole
          // budgets.
          if (from < 18) {
            await m.addColumn(budgets, budgets.category);
            // Savings were a flag from version 14 on.
            if (from >= 14) {
              await customStatement(
                "UPDATE budgets SET category = 'savings' WHERE is_savings",
              );
              await m.dropColumn(budgets, 'is_savings');
            }
            // Giving and the essentials were recognized by their names, the
            // ones the guided planning gives them.
            await customStatement(
              "UPDATE budgets SET category = CASE lower(name) "
              "WHEN 'giving' THEN 'giving' ELSE 'essential' END "
              "WHERE category = 'other' AND lower(name) IN "
              "('giving', 'rent', 'utilities', 'groceries', 'transportation')",
            );
          }
          if (from < 17) {
            await m.addColumn(budgets, budgets.position);
            // Keeps the order they were added in.
            await customStatement('UPDATE budgets SET position = id');
          }
          if (from < 12) {
            await m.addColumn(months, months.carryOverAdjustmentCents);
            // Carryovers were only worked out when a month was created, and
            // could be corrected by hand since. Keep them as they are.
            await _syncCarryOvers(keepCarryOvers: true);
          }
          // Before version 10 the settings table was just created in full.
          if (from >= 10 && from < 13) {
            await m.addColumn(settings, settings.showDebugBar);
          }
          if (from >= 10 && from < 14) {
            await m.addColumn(settings, settings.savingsGoalCents);
            await m.addColumn(settings, settings.savingsGoalPeriod);
          }
          if (from >= 10 && from < 15) {
            await m.addColumn(settings, settings.appearance);
          }
          if (from >= 10 && from < 16) {
            await m.addColumn(settings, settings.budgetOrder);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Returns the row for [year]/[month], creating it if it doesn't exist yet.
  ///
  /// A new month uses the latest earlier month as its template, see
  /// [_copyPlan].
  Future<Month> getOrCreateMonth(int year, int month) => transaction(() async {
        final query = select(months)
          ..where((m) => m.year.equals(year) & m.month.equals(month));
        final existing = await query.getSingleOrNull();
        if (existing != null) return existing;

        final monthId = await into(months).insert(
          MonthsCompanion.insert(year: year, month: month),
        );
        final template = await _monthBefore(year, month);
        if (template != null) await _copyPlan(template, monthId);
        await _syncCarryOvers();
        return query.getSingle();
      });

  /// Replaces the month's incomes and budgets with the ones of the latest
  /// earlier month, as if the month was created from it again, and unlocks
  /// it. Tracked expenses are deleted with their budgets, and corrections to
  /// the carryover are undone; notes are kept.
  ///
  /// Returns false, changing nothing, if there's no earlier month.
  Future<bool> copyPlanFromMonthBefore(int monthId) => transaction(() async {
        final month = await (select(months)
              ..where((m) => m.id.equals(monthId)))
            .getSingle();
        final template = await _monthBefore(month.year, month.month);
        if (template == null) return false;

        await (delete(budgets)..where((b) => b.monthId.equals(monthId))).go();
        await (delete(incomes)..where((i) => i.monthId.equals(monthId))).go();
        await (update(months)..where((m) => m.id.equals(monthId))).write(
          const MonthsCompanion(
            lockedAt: Value(null),
            carryOverAdjustmentCents: Value(0),
          ),
        );
        await _copyPlan(template, monthId);
        await _syncCarryOvers();
        return true;
      });

  /// Whether there's a month before the month [monthId], which it carries
  /// money over from.
  Future<bool> hasMonthBefore(int monthId) async {
    final month = await (select(months)..where((m) => m.id.equals(monthId)))
        .getSingle();
    return await _monthBefore(month.year, month.month) != null;
  }

  /// The latest month before [year]/[month], if any.
  Future<Month?> _monthBefore(int year, int month) => (select(months)
        ..where((m) =>
            m.year.isSmallerThanValue(year) |
            (m.year.equals(year) & m.month.isSmallerThanValue(month)))
        ..orderBy([
          (m) => OrderingTerm.desc(m.year),
          (m) => OrderingTerm.desc(m.month),
        ])
        ..limit(1))
      .getSingleOrNull();

  /// Gives the month [monthId] the same incomes and budgets as [template].
  /// Sinking funds carry over their own savings.
  Future<void> _copyPlan(Month template, int monthId) async {
    final templateBudgets = await (select(budgets)
          ..where((b) => b.monthId.equals(template.id))
          ..orderBy([(b) => OrderingTerm.asc(b.id)]))
        .get();
    final templateSpent =
        spentByBudget(await _expensesOfMonth(template.id).get());
    await (update(months)..where((m) => m.id.equals(monthId)))
        .write(MonthsCompanion(incomeCents: Value(template.incomeCents)));
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
          category: Value(budget.category),
          position: Value(budget.position),
          savedCents: Value(budget.isSinkingFund
              ? fundBalanceCents(budget, templateSpent[budget.id] ?? 0)
              : 0),
        ),
      );
    }
  }

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
    await _syncCarryOvers();
  }

  /// Sets each month's carryover to what the month before left, plus its
  /// adjustment, from the first month on.
  ///
  /// Call it after anything that changes a month's balance. With
  /// [keepCarryOvers], the carryovers stay as they are and the adjustments
  /// are set to match instead.
  Future<void> _syncCarryOvers({bool keepCarryOvers = false}) async {
    final allMonths = await (select(months)
          ..orderBy([
            (m) => OrderingTerm.asc(m.year),
            (m) => OrderingTerm.asc(m.month),
          ]))
        .get();
    final budgetsByMonth = <int, List<Budget>>{};
    for (final budget in await select(budgets).get()) {
      (budgetsByMonth[budget.monthId] ??= []).add(budget);
    }
    final spent = spentByBudget(await select(expenses).get());

    Month? before;
    for (final month in allMonths) {
      final leftCents = before == null
          ? 0
          : monthBalanceCents(before, budgetsByMonth[before.id] ?? [], spent);
      final synced = keepCarryOvers
          ? month.copyWith(
              carryOverAdjustmentCents: month.carryOverCents - leftCents,
            )
          : month.copyWith(
              carryOverCents: leftCents + month.carryOverAdjustmentCents,
            );
      if (synced != month) await update(months).replace(synced);
      before = synced;
    }
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
        await _syncCarryOvers();
      });

  /// Corrects what the month carries over from the month before, when it
  /// doesn't match what was actually left.
  ///
  /// The difference is kept as an adjustment, so the carryover still follows
  /// changes to the month before.
  Future<void> setCarryOverCents(int monthId, int carryOverCents) =>
      transaction(() async {
        final month = await (select(months)
              ..where((m) => m.id.equals(monthId)))
            .getSingle();
        final leftCents =
            month.carryOverCents - month.carryOverAdjustmentCents;
        await (update(months)..where((m) => m.id.equals(monthId))).write(
          MonthsCompanion(
            carryOverAdjustmentCents: Value(carryOverCents - leftCents),
          ),
        );
        await _syncCarryOvers();
      });

  /// Saves the month's notes. Blank notes are removed.
  Future<void> updateMonthNotes(int monthId, String notes) {
    final trimmed = notes.trim();
    return (update(months)..where((m) => m.id.equals(monthId))).write(
          MonthsCompanion(notes: Value(trimmed.isEmpty ? null : trimmed)),
        );
  }

  /// The settings, with defaults until any is changed.
  Stream<Setting> watchSettings() =>
      select(settings).watchSingleOrNull().map(
            (row) =>
                row ??
                const Setting(
                  id: settingsRowId,
                  bufferCents: defaultBufferCents,
                  showDebugBar: true,
                  savingsGoalPeriod: SavingsPeriod.year,
                  appearance: Appearance.system,
                  budgetOrder: BudgetOrder.category,
                ),
          );

  Future<void> _updateSettings(SettingsCompanion changes) =>
      into(settings).insertOnConflictUpdate(
        changes.copyWith(id: const Value(settingsRowId)),
      );

  /// The buffer to keep in the bank account, see [Settings.bufferCents].
  Stream<int> watchBufferCents() =>
      watchSettings().map((settings) => settings.bufferCents);

  Future<void> setBufferCents(int bufferCents) =>
      _updateSettings(SettingsCompanion(bufferCents: Value(bufferCents)));

  Future<void> setAppearance(Appearance appearance) =>
      _updateSettings(SettingsCompanion(appearance: Value(appearance)));

  Future<void> setBudgetOrder(BudgetOrder order) =>
      _updateSettings(SettingsCompanion(budgetOrder: Value(order)));

  Future<void> setShowDebugBar(bool show) =>
      _updateSettings(SettingsCompanion(showDebugBar: Value(show)));

  /// Sets the savings goal, or removes it when [goalCents] is null.
  Future<void> setSavingsGoal(int? goalCents, SavingsPeriod period) =>
      _updateSettings(
        SettingsCompanion(
          savingsGoalCents: Value(goalCents),
          savingsGoalPeriod: Value(period),
        ),
      );

  /// What savings budgets spent in each month from [first] to [last], oldest
  /// first. Months that saved nothing are left out.
  Stream<List<MonthSavings>> watchSavingsByMonth(
    YearMonth first,
    YearMonth last,
  ) {
    return customSelect(
      'SELECT m.year, m.month, SUM(e.amount_cents) AS saved_cents '
      'FROM expenses e '
      'INNER JOIN budgets b ON b.id = e.budget_id '
      'INNER JOIN months m ON m.id = b.month_id '
      "WHERE b.category = 'savings' AND m.year * 100 + m.month BETWEEN ? AND ? "
      'GROUP BY m.id ORDER BY m.year, m.month',
      variables: [
        Variable.withInt(encodeYearMonth(first)),
        Variable.withInt(encodeYearMonth(last)),
      ],
      readsFrom: {months, budgets, expenses},
    ).watch().map((rows) => [
          for (final row in rows)
            (
              month: (year: row.read<int>('year'), month: row.read<int>('month')),
              savedCents: row.read<int>('saved_cents'),
            ),
        ]);
  }

  /// The month the user works in, or null if they haven't been in one yet.
  Stream<YearMonth?> watchSelectedYearMonth() => watchSettings()
      .map((settings) => settings.selectedYearMonth)
      .distinct()
      .map((encoded) => encoded == null ? null : decodeYearMonth(encoded));

  /// The latest month the user was offered to move on to, see
  /// [Settings.offeredYearMonth].
  Stream<YearMonth?> watchOfferedYearMonth() => watchSettings()
      .map((settings) => settings.offeredYearMonth)
      .distinct()
      .map((encoded) => encoded == null ? null : decodeYearMonth(encoded));

  /// Moves the user to [yearMonth]. Choosing a month also counts as being
  /// offered it and the [calendar] month, which aren't offered again.
  Future<void> selectMonth(YearMonth yearMonth, {required YearMonth calendar}) =>
      transaction(() async {
        await _markOffered(yearMonth);
        await _markOffered(calendar);
        await _updateSettings(
          SettingsCompanion(
            selectedYearMonth: Value(encodeYearMonth(yearMonth)),
          ),
        );
      });

  /// Remembers that the user was offered to move on to [yearMonth] and
  /// declined.
  Future<void> declineMonth(YearMonth yearMonth) => _markOffered(yearMonth);

  Future<void> _markOffered(YearMonth yearMonth) async {
    final offered = (await watchSettings().first).offeredYearMonth;
    final encoded = encodeYearMonth(yearMonth);
    if (offered != null && offered >= encoded) return;
    await _updateSettings(SettingsCompanion(offeredYearMonth: Value(encoded)));
  }

  /// Every month with a plan, in no particular order.
  Stream<List<YearMonth>> watchYearMonths() => select(months)
      .map((m) => (year: m.year, month: m.month))
      .watch();

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
    BudgetCategory category = BudgetCategory.other,
  }) {
    assert(!(isFixed && isSinkingFund), 'A sinking fund is never fixed');
    assert(
      !(category == BudgetCategory.savings && isSinkingFund),
      'A sinking fund is never savings',
    );
    return transaction(() async {
      final last = budgets.position.max();
      final lastPosition = await (selectOnly(budgets)
            ..where(budgets.monthId.equals(monthId))
            ..addColumns([last]))
          .map((row) => row.read(last))
          .getSingle();
      final id = await into(budgets).insert(
        BudgetsCompanion.insert(
          monthId: monthId,
          name: name,
          amountCents: amountCents,
          isFixed: Value(isFixed),
          isSinkingFund: Value(isSinkingFund),
          category: Value(category),
          position: Value(lastPosition == null ? 0 : lastPosition + 1),
        ),
      );
      await _syncCarryOvers();
      return id;
    });
  }

  /// Sets the month's first budget called [name], ignoring case, to
  /// [amountCents]. It keeps its name and kind; if there's none yet, it's
  /// added as a new budget, fixed or not by [isFixed]. It gets the
  /// [category] either way, unless it has one other than
  /// [BudgetCategory.other] already, or it's a sinking fund and [category] is
  /// savings.
  ///
  /// An amount of 0 removes the budget instead, unless expenses were tracked
  /// against it or it holds savings: then it's kept at 0.
  Future<void> setBudgetByName(
    int monthId,
    String name,
    int amountCents, {
    bool isFixed = false,
    BudgetCategory category = BudgetCategory.other,
  }) =>
      transaction(() async {
        final existing = await (select(budgets)
              ..where((b) =>
                  b.monthId.equals(monthId) &
                  b.name.lower().equals(name.toLowerCase()))
              ..orderBy([(b) => OrderingTerm.asc(b.id)])
              ..limit(1))
            .getSingleOrNull();
        if (existing == null) {
          if (amountCents == 0) return;
          await addBudget(
            monthId,
            name,
            amountCents,
            isFixed: isFixed,
            category: category,
          );
          return;
        }
        if (amountCents == 0 && existing.savedCents == 0) {
          final tracked = await (select(expenses)
                ..where((e) =>
                    e.budgetId.equals(existing.id) & e.isFixed.equals(false))
                ..limit(1))
              .getSingleOrNull();
          if (tracked == null) {
            await deleteBudget(existing.id);
            return;
          }
        }
        await (update(budgets)..where((b) => b.id.equals(existing.id)))
            .write(
          BudgetsCompanion(
            amountCents: Value(amountCents),
            category: Value(
              existing.category != BudgetCategory.other ||
                      (category == BudgetCategory.savings &&
                          existing.isSinkingFund)
                  ? existing.category
                  : category,
            ),
          ),
        );
        await _syncCarryOvers();
      });

  /// Puts the budgets [budgetIds] in that order and lists budgets in the
  /// custom order from now on.
  Future<void> setCustomBudgetOrder(List<int> budgetIds) =>
      transaction(() async {
        for (final (position, id) in budgetIds.indexed) {
          await (update(budgets)..where((b) => b.id.equals(id)))
              .write(BudgetsCompanion(position: Value(position)));
        }
        await setBudgetOrder(BudgetOrder.custom);
      });

  /// Updates the budget. Turning a sinking fund into a regular budget releases
  /// its savings back into the month.
  Future<void> updateBudget(
    int id, {
    required String name,
    required int amountCents,
    required bool isFixed,
    bool isSinkingFund = false,
    BudgetCategory category = BudgetCategory.other,
  }) {
    assert(!(isFixed && isSinkingFund), 'A sinking fund is never fixed');
    assert(
      !(category == BudgetCategory.savings && isSinkingFund),
      'A sinking fund is never savings',
    );
    return transaction(() async {
      if (!isSinkingFund) await _releaseSavings(id);
      await (update(budgets)..where((b) => b.id.equals(id))).write(
        BudgetsCompanion(
          name: Value(name),
          amountCents: Value(amountCents),
          isFixed: Value(isFixed),
          isSinkingFund: Value(isSinkingFund),
          category: Value(category),
        ),
      );
      await _syncCarryOvers();
    });
  }

  /// Deletes the budget and its expenses. A sinking fund's savings go back
  /// into the month.
  Future<void> deleteBudget(int id) => transaction(() async {
        await _releaseSavings(id);
        await (delete(budgets)..where((b) => b.id.equals(id))).go();
        await _syncCarryOvers();
      });

  /// Moves a budget's savings into its month's carryover, so they're available
  /// to assign again. Call [_syncCarryOvers] after.
  Future<void> _releaseSavings(int budgetId) async {
    final budget = await (select(budgets)..where((b) => b.id.equals(budgetId)))
        .getSingleOrNull();
    if (budget == null || budget.savedCents == 0) return;
    await customUpdate(
      'UPDATE months '
      'SET carry_over_adjustment_cents = carry_over_adjustment_cents + ? '
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
      transaction(() async {
        final id = await into(expenses).insert(
          ExpensesCompanion.insert(
            budgetId: budgetId,
            amountCents: amountCents,
            title: Value(title),
            note: Value(note),
          ),
        );
        await _syncCarryOvers();
        return id;
      });

  /// Changes what an expense was, its amount and the budget it came out of.
  /// When it was spent stays the same.
  Future<void> updateExpense(
    int id, {
    required int budgetId,
    required int amountCents,
    required String? title,
    String? note,
  }) =>
      transaction(() async {
        await (update(expenses)..where((e) => e.id.equals(id))).write(
          ExpensesCompanion(
            budgetId: Value(budgetId),
            amountCents: Value(amountCents),
            title: Value(title),
            note: Value(note),
          ),
        );
        await _syncCarryOvers();
      });

  Future<void> deleteExpense(int id) => transaction(() async {
        await (delete(expenses)..where((e) => e.id.equals(id))).go();
        await _syncCarryOvers();
      });
}
