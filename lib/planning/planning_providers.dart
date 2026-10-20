import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../dates.dart';

part 'planning_providers.g.dart';

/// Days to shift today by, so moving through time can be tried out in debug
/// builds.
@riverpod
class DayOffset extends _$DayOffset {
  @override
  int build() => 0;

  void shiftDays(int days) => state += days;

  /// Moves to the first day of the month [months] after (or before) the
  /// shifted today.
  void shiftToMonthStart(int months) {
    final today = _today(state);
    final target = DateTime(today.year, today.month + months);
    state += _daysBetween(today, target);
  }

  void reset() => state = 0;
}

DateTime _today(int dayOffset) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + dayOffset);
}

int _daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

/// Today's date, shifted by [DayOffset] in debug builds.
///
/// Invalidate it when the app comes back to the foreground, as the day may
/// have changed.
@riverpod
DateTime today(Ref ref) => _today(ref.watch(dayOffsetProvider));

/// The month the user works in, which they choose themselves.
///
/// The app starts in today's month and stays in it, even once a new month
/// starts, until the user moves on.
@riverpod
Future<YearMonth> currentYearMonth(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  final selected = await ref.watch(selectedYearMonthProvider.future);
  if (selected != null) return selected;
  final today = yearMonthOf(ref.read(todayProvider));
  await db.selectMonth(today, calendar: today);
  return today;
}

@riverpod
Stream<YearMonth?> selectedYearMonth(Ref ref) =>
    ref.watch(appDatabaseProvider).watchSelectedYearMonth();

/// The months the user can switch to, newest first.
@riverpod
Stream<List<YearMonth>> selectableMonths(Ref ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final today = ref.watch(todayProvider);
  final current = await ref.watch(currentYearMonthProvider.future);
  yield* db
      .watchYearMonths()
      .map((planned) => monthsToChooseFrom([...planned, current], today));
}

/// A month that started after the current one, to ask the user whether to
/// move on to it; null if there's none.
@riverpod
Future<YearMonth?> monthToOffer(Ref ref) async {
  final today = ref.watch(todayProvider);
  final current = await ref.watch(currentYearMonthProvider.future);
  final offered = await ref.watch(offeredYearMonthProvider.future);
  return newMonthToOffer(current: current, offered: offered, today: today);
}

@riverpod
Stream<YearMonth?> offeredYearMonth(Ref ref) =>
    ref.watch(appDatabaseProvider).watchOfferedYearMonth();

/// Id of the current month's row, created the first time it's needed.
@riverpod
Future<int> currentMonthId(Ref ref) async {
  final (:year, :month) = await ref.watch(currentYearMonthProvider.future);
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
