// take datetime, return date's string
String dateToString(DateTime date) {
  return date.toIso8601String().split('T').first;
}
