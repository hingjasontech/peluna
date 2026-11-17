import 'package:peluna/config/constant.dart';
import 'package:peluna/models/diary_model.dart';

/// Ranges available in the analytics page.
enum AnalyticsRangeType {
  last7Days,
  last28Days,
  last90Days,
  last365Days,
  lifetime,
  year,
  month,
  custom,
}

/// Normalises a [DateTime] to a local, time-free calendar date.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Adds calendar days without relying on 24-hour durations, which break
/// across daylight-saving transitions.
DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// Number of calendar days in [start]..[end], both inclusive.
int daysInclusive(DateTime start, DateTime end) {
  if (end.isBefore(start)) return 0;
  final from = DateTime.utc(start.year, start.month, start.day);
  final to = DateTime.utc(end.year, end.month, end.day);
  return to.difference(from).inDays + 1;
}

int _dayKey(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

/// Diary entries indexed by calendar day, plus derived score lookups.
///
/// Built once per diary revision so summaries and charts do not repeatedly
/// walk the Hive box.
class AnalyticsData {
  AnalyticsData._(this._entriesByDay, this._scoresByDay, this.firstEntryDate);

  factory AnalyticsData.fromDiaries(Iterable<Diary> diaries) {
    final entries = <int, Diary>{};
    final scores = <int, int>{};
    DateTime? firstEntry;

    for (final diary in diaries) {
      final date = dateOnly(diary.date);
      final key = _dayKey(date);
      final existing = entries[key];
      if (existing == null || dateOnly(existing.date).isBefore(date)) {
        entries[key] = diary;
      }
      if (firstEntry == null || date.isBefore(firstEntry)) {
        firstEntry = date;
      }

      final score = diary.score;
      if (score != null && Score.getIndex(score) != -1) {
        scores[key] = score;
      }
    }

    return AnalyticsData._(entries, scores, firstEntry);
  }

  final Map<int, Diary> _entriesByDay;
  final Map<int, int> _scoresByDay;

  /// Earliest saved entry, including future-dated entries.
  final DateTime? firstEntryDate;

  bool get isEmpty => _entriesByDay.isEmpty;

  int? scoreFor(DateTime date) => _scoresByDay[_dayKey(dateOnly(date))];

  Diary? diaryFor(DateTime date) => _entriesByDay[_dayKey(dateOnly(date))];

  /// Earliest entry on or before [today], or null when everything is future.
  DateTime? firstEntryOnOrBefore(DateTime today) {
    final first = firstEntryDate;
    if (first == null || first.isAfter(dateOnly(today))) return null;
    return first;
  }
}

/// Aggregated score numbers for one inclusive date range.
class ScoreSummary {
  const ScoreSummary({
    required this.start,
    required this.end,
    required this.totalDays,
    required this.loggedDays,
    required this.missingDays,
    required this.netScore,
    required this.positiveDays,
    required this.distribution,
  });

  final DateTime start;
  final DateTime end;
  final int totalDays;
  final int loggedDays;
  final int missingDays;
  final int netScore;
  final int positiveDays;

  /// Count per score value. Only days with a recorded score are included.
  final Map<int, int> distribution;

  int countFor(int score) => distribution[score] ?? 0;
}

ScoreSummary summarizeScores(AnalyticsData data, DateTime start, DateTime end) {
  final from = dateOnly(start);
  final to = dateOnly(end);
  final totalDays = daysInclusive(from, to);
  final distribution = <int, int>{for (final score in Score.values) score: 0};

  var net = 0;
  var logged = 0;
  var positive = 0;

  for (var day = from; !day.isAfter(to); day = addDays(day, 1)) {
    final score = data.scoreFor(day);
    if (score == null) continue;
    net += score;
    logged++;
    distribution[score] = (distribution[score] ?? 0) + 1;
    if (score > 0) positive++;
  }

  return ScoreSummary(
    start: from,
    end: to,
    totalDays: totalDays,
    loggedDays: logged,
    missingDays: totalDays - logged,
    netScore: net,
    positiveDays: positive,
    distribution: Map.unmodifiable(distribution),
  );
}

class CumulativePoint {
  const CumulativePoint({
    required this.date,
    required this.cumulative,
    required this.score,
  });

  final DateTime date;
  final int cumulative;
  final int? score;
}

/// Running net score for every day in the range, missing days included as 0.
List<CumulativePoint> cumulativePoints(
  AnalyticsData data,
  DateTime start,
  DateTime end,
) {
  final from = dateOnly(start);
  final to = dateOnly(end);
  if (to.isBefore(from)) return const [];

  final points = <CumulativePoint>[];
  var running = 0;
  for (var day = from; !day.isAfter(to); day = addDays(day, 1)) {
    final score = data.scoreFor(day);
    if (score != null) running += score;
    points.add(CumulativePoint(date: day, cumulative: running, score: score));
  }
  return List.unmodifiable(points);
}

/// A display period with its full bounds and the elapsed portion used for
/// calculations. Future days stay visible in the calendar but never count.
class AnalyticsPeriod {
  const AnalyticsPeriod({
    required this.type,
    required this.start,
    required this.end,
    required this.effectiveEnd,
  });

  final AnalyticsRangeType type;
  final DateTime start;

  /// Full period end, used by the calendar.
  final DateTime end;

  /// Last day included in scores. Equals [end] for completed periods.
  final DateTime effectiveEnd;

  bool get isPartial => effectiveEnd.isBefore(end);
  int get elapsedDays => daysInclusive(start, effectiveEnd);
  int get totalDays => daysInclusive(start, end);

  bool contains(DateTime date) {
    final d = dateOnly(date);
    return !d.isBefore(start) && !d.isAfter(end);
  }
}

AnalyticsPeriod buildPeriod({
  required AnalyticsRangeType type,
  required DateTime anchor,
  required DateTime today,
  DateTime? firstEntry,
  DateTime? customStart,
  DateTime? customEnd,
}) {
  final todayOnly = dateOnly(today);

  switch (type) {
    case AnalyticsRangeType.lifetime:
      var start = dateOnly(firstEntry ?? todayOnly);
      if (start.isAfter(todayOnly)) start = todayOnly;
      return AnalyticsPeriod(
        type: type,
        start: start,
        end: todayOnly,
        effectiveEnd: todayOnly,
      );
    case AnalyticsRangeType.last7Days:
      return _trailingPeriod(type, todayOnly, 7);
    case AnalyticsRangeType.last28Days:
      return _trailingPeriod(type, todayOnly, 28);
    case AnalyticsRangeType.last90Days:
      return _trailingPeriod(type, todayOnly, 90);
    case AnalyticsRangeType.last365Days:
      return _trailingPeriod(type, todayOnly, 365);
    case AnalyticsRangeType.custom:
      var from = dateOnly(customStart ?? todayOnly);
      var to = dateOnly(customEnd ?? todayOnly);
      if (to.isBefore(from)) {
        final swap = from;
        from = to;
        to = swap;
      }
      if (to.isAfter(todayOnly)) to = todayOnly;
      if (from.isAfter(to)) from = to;
      return AnalyticsPeriod(
        type: type,
        start: from,
        end: to,
        effectiveEnd: to,
      );
    case AnalyticsRangeType.year:
    case AnalyticsRangeType.month:
      break;
  }

  var safeAnchor = dateOnly(anchor);
  if (safeAnchor.isAfter(todayOnly)) safeAnchor = todayOnly;

  final DateTime start;
  final DateTime end;
  switch (type) {
    case AnalyticsRangeType.year:
      start = DateTime(safeAnchor.year, 1, 1);
      end = DateTime(safeAnchor.year, 12, 31);
    case AnalyticsRangeType.month:
      start = DateTime(safeAnchor.year, safeAnchor.month, 1);
      end = DateTime(safeAnchor.year, safeAnchor.month + 1, 0);
    case AnalyticsRangeType.lifetime:
    case AnalyticsRangeType.last7Days:
    case AnalyticsRangeType.last28Days:
    case AnalyticsRangeType.last90Days:
    case AnalyticsRangeType.last365Days:
    case AnalyticsRangeType.custom:
      throw StateError('Handled above');
  }

  return AnalyticsPeriod(
    type: type,
    start: start,
    end: end,
    effectiveEnd: end.isAfter(todayOnly) ? todayOnly : end,
  );
}

AnalyticsPeriod _trailingPeriod(
  AnalyticsRangeType type,
  DateTime today,
  int days,
) {
  return AnalyticsPeriod(
    type: type,
    start: addDays(today, -(days - 1)),
    end: today,
    effectiveEnd: today,
  );
}

/// Lifetime range from the first saved entry through today, or null when the
/// diary has no entry on or before today.
AnalyticsPeriod? buildLifetimePeriod(AnalyticsData data, DateTime today) {
  final todayOnly = dateOnly(today);
  final first = data.firstEntryOnOrBefore(todayOnly);
  if (first == null) return null;

  return buildPeriod(
    type: AnalyticsRangeType.lifetime,
    anchor: todayOnly,
    today: todayOnly,
    firstEntry: first,
  );
}

class MonthlyBucket {
  const MonthlyBucket({required this.month, required this.summary});

  /// First day of the calendar month.
  final DateTime month;
  final ScoreSummary summary;
}

class PeriodAnalytics {
  const PeriodAnalytics({
    required this.period,
    required this.summary,
    required this.points,
    required this.monthlyBuckets,
  });

  final AnalyticsPeriod period;
  final ScoreSummary summary;
  final List<CumulativePoint> points;

  /// Empty unless the range is long enough and short enough to read monthly.
  final List<MonthlyBucket> monthlyBuckets;
}

PeriodAnalytics buildPeriodAnalytics(
  AnalyticsData data,
  AnalyticsPeriod period,
) {
  final summary = summarizeScores(data, period.start, period.effectiveEnd);
  final points = cumulativePoints(data, period.start, period.effectiveEnd);
  final buckets = period.elapsedDays > 31 && period.elapsedDays <= 366
      ? _monthlyBuckets(data, period.start, period.effectiveEnd)
      : const <MonthlyBucket>[];

  return PeriodAnalytics(
    period: period,
    summary: summary,
    points: points,
    monthlyBuckets: buckets,
  );
}

List<MonthlyBucket> _monthlyBuckets(
  AnalyticsData data,
  DateTime start,
  DateTime end,
) {
  final buckets = <MonthlyBucket>[];
  var cursor = DateTime(start.year, start.month, 1);

  while (!cursor.isAfter(end)) {
    final monthEnd = DateTime(cursor.year, cursor.month + 1, 0);
    final bucketStart = cursor.isBefore(start) ? start : cursor;
    final bucketEnd = monthEnd.isAfter(end) ? end : monthEnd;
    buckets.add(
      MonthlyBucket(
        month: cursor,
        summary: summarizeScores(data, bucketStart, bucketEnd),
      ),
    );
    cursor = DateTime(cursor.year, cursor.month + 1, 1);
  }

  return List.unmodifiable(buckets);
}
