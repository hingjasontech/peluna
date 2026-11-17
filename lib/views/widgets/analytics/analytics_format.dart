import 'package:flutter/material.dart';

import 'package:peluna/analytics/mood_analytics.dart';
import 'package:peluna/config/constant.dart';
import 'package:peluna/models/week_start.dart';

const List<String> _monthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _monthsLong = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _weekdaysShort = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

String signedInt(int value) => value > 0 ? '+$value' : '$value';

/// Maps a net score to the same green/orange/red palette as moods.
Color moodScoreColor(int score) {
  if (score >= 2) return Mood.moodColors[0];
  if (score > 0) return Mood.moodColors[1];
  if (score <= -2) return Mood.moodColors[4];
  if (score < 0) return Mood.moodColors[3];
  return Mood.moodColors[2];
}

String shortDate(DateTime date) =>
    '${_monthsShort[date.month - 1]} ${date.day}';

String fullDate(DateTime date) =>
    '${_monthsShort[date.month - 1]} ${date.day}, ${date.year}';

String monthLong(DateTime date) => _monthsLong[date.month - 1];

String monthShort(DateTime date) => _monthsShort[date.month - 1];

String countDays(int count) => '$count ${count == 1 ? 'day' : 'days'}';

String weekdayShort(int weekday) => _weekdaysShort[weekday - 1];

List<String> weekdayLabels(WeekStart weekStart) {
  final startWeekday = switch (weekStart) {
    WeekStart.monday => DateTime.monday,
    WeekStart.sunday => DateTime.sunday,
    WeekStart.saturday => DateTime.saturday,
  };
  return [
    for (var offset = 0; offset < 7; offset++)
      _weekdaysShort[(startWeekday - 1 + offset) % 7],
  ];
}

String analyticsPeriodLabel(AnalyticsPeriod period) {
  final start = period.start;
  final end = period.end;

  switch (period.type) {
    case AnalyticsRangeType.last7Days:
      return 'Last 7 days';
    case AnalyticsRangeType.last28Days:
      return 'Last 28 days';
    case AnalyticsRangeType.last90Days:
      return 'Last 90 days';
    case AnalyticsRangeType.last365Days:
      return 'Last 365 days';
    case AnalyticsRangeType.lifetime:
      return 'Lifetime';
    case AnalyticsRangeType.month:
      return '${monthLong(start)} ${start.year}';
    case AnalyticsRangeType.year:
      return '${start.year}';
    case AnalyticsRangeType.custom:
      if (start == end) return fullDate(start);
      if (start.year != end.year) {
        return '${fullDate(start)} – ${fullDate(end)}';
      }
      if (start.month != end.month) {
        return '${shortDate(start)} – ${shortDate(end)}, ${start.year}';
      }
      return '${monthShort(start)} ${start.day} – ${end.day}, ${start.year}';
  }
}
