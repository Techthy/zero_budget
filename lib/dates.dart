const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', //
  'August', 'September', 'October', 'November', 'December',
];

/// Formats a year and 1-based month like "September 2026".
String formatMonth(int year, int month) => '${_monthNames[month - 1]} $year';

/// Formats a date as a short day like "Sep 15".
String formatDay(DateTime date) =>
    '${_monthNames[date.month - 1].substring(0, 3)} ${date.day}';

/// A month of a year, with a 1-based month.
typedef YearMonth = ({int year, int month});

YearMonth yearMonthOf(DateTime date) => (year: date.year, month: date.month);

/// Encodes a month as a number like 202610, which sorts like the months do.
int encodeYearMonth(YearMonth yearMonth) =>
    yearMonth.year * 100 + yearMonth.month;

YearMonth decodeYearMonth(int encoded) =>
    (year: encoded ~/ 100, month: encoded % 100);

/// How many days before a month starts it can be planned.
const planAheadDays = 3;

/// The months the user can work in, newest first: every month in [planned],
/// the month of [today], and the next month once it's at most
/// [planAheadDays] away.
List<YearMonth> monthsToChooseFrom(
  Iterable<YearMonth> planned,
  DateTime today,
) {
  final next = DateTime(today.year, today.month + 1);
  final encoded = {
    ...planned.map(encodeYearMonth),
    encodeYearMonth(yearMonthOf(today)),
    if (!today.isBefore(DateTime(next.year, next.month, 1 - planAheadDays)))
      encodeYearMonth(yearMonthOf(next)),
  };
  return (encoded.toList()..sort((a, b) => b.compareTo(a)))
      .map(decodeYearMonth)
      .toList();
}

/// The month that started after the [current] one, to offer moving on to;
/// null if [current] isn't behind [today] or the user was already offered it
/// ([offered] is the latest month they were).
YearMonth? newMonthToOffer({
  required YearMonth current,
  required YearMonth? offered,
  required DateTime today,
}) {
  final calendar = encodeYearMonth(yearMonthOf(today));
  if (encodeYearMonth(current) >= calendar) return null;
  if (offered != null && encodeYearMonth(offered) >= calendar) return null;
  return decodeYearMonth(calendar);
}
