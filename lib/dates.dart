const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', //
  'August', 'September', 'October', 'November', 'December',
];

/// Formats a year and 1-based month like "September 2026".
String formatMonth(int year, int month) => '${_monthNames[month - 1]} $year';

/// Formats a date as a short day like "Sep 15".
String formatDay(DateTime date) =>
    '${_monthNames[date.month - 1].substring(0, 3)} ${date.day}';
