import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../dates.dart';
import '../month/month_providers.dart';
import '../settings/settings_providers.dart';

part 'savings_providers.g.dart';

/// The first and last month of the [period] that [month] is in.
({YearMonth first, YearMonth last}) savingsPeriodOf(
  YearMonth month,
  SavingsPeriod period,
) {
  final (firstMonth, length) = switch (period) {
    SavingsPeriod.quarter => ((month.month - 1) ~/ 3 * 3 + 1, 3),
    SavingsPeriod.year => (1, 12),
  };
  return (
    first: (year: month.year, month: firstMonth),
    last: (year: month.year, month: firstMonth + length - 1),
  );
}

/// Names the [period] that [month] is in, like "Q4 2026" or "2026".
String formatSavingsPeriod(YearMonth month, SavingsPeriod period) =>
    switch (period) {
      SavingsPeriod.quarter => 'Q${(month.month - 1) ~/ 3 + 1} ${month.year}',
      SavingsPeriod.year => '${month.year}',
    };

/// What was saved towards the savings goal in the period of [month].
class SavingsProgress {
  const SavingsProgress({
    required this.goalCents,
    required this.period,
    required this.month,
    required this.months,
  });

  /// Null while there's no goal.
  final int? goalCents;
  final SavingsPeriod period;

  /// The month the user works in, which picks the period.
  final YearMonth month;

  /// The months of the period that saved anything, oldest first.
  final List<MonthSavings> months;

  int get savedCents => months.fold(0, (sum, m) => sum + m.savedCents);

  /// How much of the goal is saved, from 0 to 1; 0 without a goal.
  double get fraction => switch (goalCents) {
    null => 0,
    final goal when goal <= 0 => 1,
    final goal => (savedCents / goal).clamp(0.0, 1.0),
  };

  String get periodName => formatSavingsPeriod(month, period);
}

/// Progress towards the savings goal in the period of the month the user
/// works in.
@riverpod
Stream<SavingsProgress> savingsProgress(Ref ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final month = await ref.watch(currentYearMonthProvider.future);
  final settings = await ref.watch(settingsProvider.future);
  final period = settings.savingsGoalPeriod;
  final (:first, :last) = savingsPeriodOf(month, period);
  yield* db
      .watchSavingsByMonth(first, last)
      .map(
        (months) => SavingsProgress(
          goalCents: settings.savingsGoalCents,
          period: period,
          month: month,
          months: months,
        ),
      );
}
