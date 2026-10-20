import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../month/month_providers.dart';

part 'history_providers.g.dart';

/// Every month except the current one, newest first.
@riverpod
Stream<List<MonthSummary>> pastMonths(Ref ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final currentMonthId = await ref.watch(currentMonthIdProvider.future);
  yield* db.watchMonthSummaries().map(
    (months) =>
        months.where((summary) => summary.month.id != currentMonthId).toList(),
  );
}

@riverpod
Stream<Month> monthById(Ref ref, int monthId) =>
    ref.watch(appDatabaseProvider).watchMonth(monthId);

@riverpod
Stream<List<Income>> incomesForMonth(Ref ref, int monthId) =>
    ref.watch(appDatabaseProvider).watchIncomes(monthId);

@riverpod
Stream<List<Budget>> budgetsForMonth(Ref ref, int monthId) =>
    ref.watch(appDatabaseProvider).watchBudgets(monthId);

@riverpod
Stream<List<Expense>> expensesForMonth(Ref ref, int monthId) =>
    ref.watch(appDatabaseProvider).watchExpenses(monthId);
