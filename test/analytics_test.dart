import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peluna/analytics/mood_analytics.dart';
import 'package:peluna/config/constant.dart';
import 'package:peluna/models/diary_model.dart';
import 'package:peluna/models/week_start.dart';
import 'package:peluna/views/pages/analytics_page.dart';
import 'package:peluna/views/widgets/analytics/analytics_format.dart';
import 'package:peluna/views/widgets/analytics/analytics_summary_card.dart';

import 'support/test_harness.dart';

Diary _diary(DateTime date, int? mood, {String content = 'entry'}) {
  return Diary(date, content, mood, null, null);
}

void main() {
  group('date helpers', () {
    test('dateOnly strips time and keeps the local calendar day', () {
      expect(dateOnly(DateTime(2026, 11, 16, 23, 59)), DateTime(2026, 11, 16));
    });

    test('addDays handles month boundaries', () {
      expect(addDays(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 1));
      expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
    });

    test('daysInclusive counts both ends', () {
      expect(daysInclusive(DateTime(2026, 11, 16), DateTime(2026, 11, 16)), 1);
      expect(daysInclusive(DateTime(2026, 11, 16), DateTime(2026, 11, 22)), 7);
      expect(daysInclusive(DateTime(2026, 11, 22), DateTime(2026, 11, 16)), 0);
    });

    test('startOfWeek respects every configured week start', () {
      final monday = DateTime(2026, 11, 16); // Monday.
      expect(startOfWeek(monday, WeekStart.monday), monday);
      expect(startOfWeek(monday, WeekStart.sunday), DateTime(2026, 11, 15));
      expect(startOfWeek(monday, WeekStart.saturday), DateTime(2026, 11, 14));
    });
  });

  group('score colors', () {
    test('follows the five mood colors', () {
      expect(moodScoreColor(2), Mood.moodColors[0]);
      expect(moodScoreColor(0.5), Mood.moodColors[1]);
      expect(moodScoreColor(0), Mood.moodColors[2]);
      expect(moodScoreColor(-0.5), Mood.moodColors[3]);
      expect(moodScoreColor(-2), Mood.moodColors[4]);
    });
  });

  group('lifetime analytics', () {
    test('missing days count as zero', () {
      final data = AnalyticsData.fromDiaries([
        _diary(DateTime(2026, 1, 1), 2),
        _diary(DateTime(2026, 1, 3), -1),
      ]);
      final period = buildLifetimePeriod(data, DateTime(2026, 1, 5))!;
      final analytics = buildPeriodAnalytics(data, period);

      expect(period.type, AnalyticsRangeType.lifetime);
      expect(period.start, DateTime(2026, 1, 1));
      expect(period.end, DateTime(2026, 1, 5));
      expect(canGoToNextPeriod(period, DateTime(2026, 1, 5)), isFalse);
      expect(analytics.summary.totalDays, 5);
      expect(analytics.summary.loggedDays, 2);
      expect(analytics.summary.missingDays, 3);
      expect(analytics.summary.netScore, 1);
      expect(analytics.summary.average, closeTo(0.2, 0.0001));
      expect(analytics.summary.positiveDays, 1);
      expect(analytics.summary.countFor(2), 1);
      expect(analytics.summary.countFor(-1), 1);
      expect(analytics.summary.countFor(0), 0);
    });

    test('starts at the first entry even when it has no mood', () {
      final data = AnalyticsData.fromDiaries([
        _diary(DateTime(2025, 12, 30), null, content: 'first'),
        _diary(DateTime(2026, 1, 1), 2),
      ]);
      final period = buildLifetimePeriod(data, DateTime(2026, 1, 2))!;
      final analytics = buildPeriodAnalytics(data, period);

      expect(period.start, DateTime(2025, 12, 30));
      expect(analytics.summary.totalDays, 4);
      expect(analytics.summary.loggedDays, 1);
      expect(analytics.summary.netScore, 2);
      expect(analytics.summary.average, closeTo(0.5, 0.0001));
    });

    test('ignores future entries and invalid moods', () {
      final data = AnalyticsData.fromDiaries([
        _diary(DateTime(2026, 1, 1), 1),
        _diary(DateTime(2026, 1, 10), 2),
        _diary(DateTime(2026, 1, 2), 5),
      ]);
      final period = buildLifetimePeriod(data, DateTime(2026, 1, 2))!;
      final analytics = buildPeriodAnalytics(data, period);

      expect(analytics.summary.totalDays, 2);
      expect(analytics.summary.loggedDays, 1);
      expect(analytics.summary.netScore, 1);
      expect(analytics.summary.missingDays, 1);
    });

    test('returns null when every entry is in the future', () {
      final data = AnalyticsData.fromDiaries([
        _diary(DateTime(2026, 1, 10), 2),
      ]);
      expect(buildLifetimePeriod(data, DateTime(2026, 1, 2)), isNull);
    });
  });

  group('cumulative points', () {
    test('stay flat on missing days and can move down', () {
      final data = AnalyticsData.fromDiaries([
        _diary(DateTime(2026, 1, 1), 2),
        _diary(DateTime(2026, 1, 3), -1),
      ]);
      final points = cumulativePoints(
        data,
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 3),
      );

      expect(points.map((point) => point.cumulative), [2, 2, 1]);
      expect(points.map((point) => point.mood), [2, null, -1]);
    });
  });

  group('period analytics', () {
    final today = DateTime(2026, 11, 18); // Wednesday.

    test('current week counts only elapsed days', () {
      final data = AnalyticsData.fromDiaries([
        _diary(DateTime(2026, 11, 16), 2),
        _diary(DateTime(2026, 11, 18), 1),
      ]);
      final period = buildPeriod(
        type: AnalyticsRangeType.week,
        anchor: today,
        today: today,
        weekStart: WeekStart.monday,
      );
      final analytics = buildPeriodAnalytics(data, period);

      expect(period.start, DateTime(2026, 11, 16));
      expect(period.end, DateTime(2026, 11, 22));
      expect(period.effectiveEnd, today);
      expect(period.isPartial, isTrue);
      expect(analytics.summary.totalDays, 3);
      expect(analytics.summary.netScore, 3);
      expect(analytics.summary.average, 1);
      expect(analytics.summary.loggedDays, 2);
      expect(analytics.summary.missingDays, 1);
      expect(canGoToNextPeriod(period, today), isFalse);
    });

    test('completed week includes all seven days and allows next', () {
      final period = buildPeriod(
        type: AnalyticsRangeType.week,
        anchor: DateTime(2026, 11, 11),
        today: today,
        weekStart: WeekStart.monday,
      );

      expect(period.start, DateTime(2026, 11, 9));
      expect(period.end, DateTime(2026, 11, 15));
      expect(period.effectiveEnd, DateTime(2026, 11, 15));
      expect(period.isPartial, isFalse);
      expect(canGoToNextPeriod(period, today), isTrue);
    });

    test('month and year clamp their effective end to today', () {
      final month = buildPeriod(
        type: AnalyticsRangeType.month,
        anchor: today,
        today: today,
        weekStart: WeekStart.monday,
      );
      final year = buildPeriod(
        type: AnalyticsRangeType.year,
        anchor: today,
        today: today,
        weekStart: WeekStart.monday,
      );

      expect(month.start, DateTime(2026, 11, 1));
      expect(month.end, DateTime(2026, 11, 30));
      expect(month.effectiveEnd, today);
      expect(year.start, DateTime(2026, 1, 1));
      expect(year.end, DateTime(2026, 12, 31));
      expect(year.effectiveEnd, today);
      expect(canGoToNextPeriod(month, today), isFalse);
      expect(canGoToNextPeriod(year, today), isFalse);
    });

    test('custom ranges are inclusive and future-clamped', () {
      final period = buildPeriod(
        type: AnalyticsRangeType.custom,
        anchor: today,
        today: today,
        weekStart: WeekStart.monday,
        customStart: DateTime(2026, 11, 1),
        customEnd: DateTime(2026, 12, 1),
      );

      expect(period.start, DateTime(2026, 11, 1));
      expect(period.end, today);
      expect(period.totalDays, 18);
      expect(canGoToNextPeriod(period, today), isFalse);
    });

    test('long ranges produce monthly buckets', () {
      final period = buildPeriod(
        type: AnalyticsRangeType.year,
        anchor: today,
        today: today,
        weekStart: WeekStart.monday,
      );
      final analytics = buildPeriodAnalytics(
        AnalyticsData.fromDiaries(const []),
        period,
      );

      expect(analytics.monthlyBuckets, hasLength(11));
      expect(analytics.monthlyBuckets.first.month, DateTime(2026, 1, 1));
      expect(
        analytics.monthlyBuckets.fold<int>(
          0,
          (sum, bucket) => sum + bucket.summary.totalDays,
        ),
        analytics.summary.totalDays,
      );
    });
  });

  group('AnalyticsPage', () {
    late HiveTestHarness hive;

    setUpAll(() async {
      hive = await HiveTestHarness.create();
    });

    tearDownAll(() async {
      await hive.dispose();
    });

    setUp(() async {
      await hive.clear();
    });

    testWidgets('defaults to lifetime and switches to the week view', (
      tester,
    ) async {
      final now = DateTime.now();
      await tester.runAsync(() async {
        await hive.put(now, _diary(now, 2));
      });

      await tester.pumpWidget(
        hive.wrap(const MaterialApp(home: Scaffold(body: AnalyticsPage()))),
      );
      await tester.pump();
      expect(find.text('0'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Lifetime'), findsOneWidget);
      expect(find.text('LIFETIME'), findsOneWidget);
      expect(find.text('Cumulative score'), findsOneWidget);
      expect(find.textContaining('days logged'), findsNothing);
      expect(find.textContaining('Average +'), findsNothing);
      expect(find.byTooltip('Previous period'), findsNothing);
      final score = tester.widget<Text>(
        find.descendant(
          of: find.byType(AnalyticsSummaryCard),
          matching: find.text('+2'),
        ),
      );
      expect(score.style?.color, Mood.moodColors[0]);

      await tester.tap(find.text('Week'));
      await tester.pump();

      expect(find.text('SELECTED RANGE'), findsOneWidget);
      expect(find.text('Mood calendar'), findsOneWidget);
      expect(find.byTooltip('Previous period'), findsOneWidget);

      await tester.tap(find.text('Average'));
      await tester.pump();
      expect(find.text('per day'), findsOneWidget);

      await tester.tap(find.text('Lifetime'));
      await tester.pump();
      expect(find.text('LIFETIME'), findsOneWidget);
      expect(find.byTooltip('Previous period'), findsNothing);
    });

    testWidgets('shows the empty lifetime state without entries', (
      tester,
    ) async {
      await tester.pumpWidget(
        hive.wrap(const MaterialApp(home: Scaffold(body: AnalyticsPage()))),
      );
      await tester.pump();

      expect(find.text('Your score starts with one entry'), findsOneWidget);
      expect(find.text('Write today'), findsOneWidget);
    });
  });
}
