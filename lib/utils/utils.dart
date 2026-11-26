const List<String> _weekdayShortNames = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

// take datetime, return date's string
String dateToString(DateTime date) {
  return date.toIso8601String().split('T').first;
}

/// Short weekday name for [date], for example `Mon`.
String weekdayShortName(DateTime date) => _weekdayShortNames[date.weekday - 1];
