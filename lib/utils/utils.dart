const List<String> _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

// take datetime, return date's string
String dateToString(DateTime date) {
  return date.toIso8601String().split('T').first;
}

/// Full weekday name for [date], for example `Monday`.
String weekdayName(DateTime date) => _weekdayNames[date.weekday - 1];
