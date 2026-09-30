import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database.dart';
import '../data/database_provider.dart';

part 'welcome_providers.g.dart';

/// Months to shift the current month by, so moving through months can be
/// tried out in debug builds.
@riverpod
class MonthOffset extends _$MonthOffset {
  @override
  int build() => 0;

  void previous() => state--;
  void next() => state++;
  void reset() => state = 0;
}

/// The year and month the app treats as the current one.
@riverpod
({int year, int month}) currentYearMonth(Ref ref) {
  final now = DateTime.now();
  // DateTime rolls months outside 1-12 over into the next or previous year.
  final shifted =
      DateTime(now.year, now.month + ref.watch(monthOffsetProvider));
  return (year: shifted.year, month: shifted.month);
}

/// Id of the current month's row, created the first time it's needed.
@riverpod
Future<int> currentMonthId(Ref ref) async {
  final (:year, :month) = ref.watch(currentYearMonthProvider);
  final row =
      await ref.watch(appDatabaseProvider).getOrCreateMonth(year, month);
  return row.id;
}

@riverpod
Stream<Month> currentMonth(Ref ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final monthId = await ref.watch(currentMonthIdProvider.future);
  yield* db.watchMonth(monthId);
}

@riverpod
Stream<List<Budget>> currentBudgets(Ref ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final monthId = await ref.watch(currentMonthIdProvider.future);
  yield* db.watchBudgets(monthId);
}

@riverpod
Stream<List<Income>> currentIncomes(Ref ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final monthId = await ref.watch(currentMonthIdProvider.future);
  yield* db.watchIncomes(monthId);
}
