import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peluna/analytics/score_analytics.dart';
import 'package:peluna/config/constant.dart';
import 'package:peluna/models/diary_model.dart';
import 'package:peluna/views/pages/analytics_page.dart';
import 'package:peluna/views/widgets/analytics/analytics_format.dart';
import 'package:peluna/views/widgets/analytics/score_card.dart';

import 'support/test_harness.dart';

Diary _diary(DateTime date, int? score, {String content = 'entry'}) {
  return Diary(date, content, score, null, null);
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
  });

  group('score colors', () {
    test('follows the five score colors', () {
      expect(scoreColor(2), Score.colors[0]);
      expect(scoreColor(1), Score.colors[1]);
      expect(scoreColor(0), Score.colors[2]);
      expect(scoreColor(-1), Score.colors[3]);
      expect(scoreColor(-2), Score.colors[4]);
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
      expect(analytics.summary.totalDays, 5);
      expect(analytics.summary.loggedDays, 2);
      expect(analytics.summary.missingDays, 3);
      expect(analytics.summary.netScore, 1);
      expect(analytics.summary.positiveDays, 1);
      expect(analytics.summary.countFor(2), 1);
      expect(analytics.summary.countFor(-1), 1);
      expect(analytics.summary.countFor(0), 0);
    });

    test('starts at the first entry even when it has no score', () {
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
    });

    test('ignores future entries and invalid scores', () {
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
      expect(points.map((point) => point.score), [2, null, -1]);
    });
  });

  group('period analytics', () {
    final today = DateTime(2026, 11, 18);

    test('trailing ranges include today', () {
      final cases = [
        (AnalyticsRangeType.last7Days, 7),
        (AnalyticsRangeType.last28Days, 28),
        (AnalyticsRangeType.last90Days, 90),
        (AnalyticsRangeType.last365Days, 365),
      ];

      for (final (type, days) in cases) {
        final period = buildPeriod(type: type, anchor: today, today: today);

        expect(period.start, addDays(today, -(days - 1)));
        expect(period.end, today);
        expect(period.effectiveEnd, today);
        expect(period.totalDays, days);
        expect(period.isPartial, isFalse);
      }
    });

    test('last 7 days counts only logged days and missing days', () {
      final data = AnalyticsData.fromDiaries([
        _diary(DateTime(2026, 11, 16), 2),
        _diary(DateTime(2026, 11, 18), 1),
      ]);
      final period = buildPeriod(
        type: AnalyticsRangeType.last7Days,
        anchor: today,
        today: today,
      );
      final analytics = buildPeriodAnalytics(data, period);

      expect(period.start, DateTime(2026, 11, 12));
      expect(period.end, today);
      expect(period.effectiveEnd, today);
      expect(analytics.summary.totalDays, 7);
      expect(analytics.summary.netScore, 3);
      expect(analytics.summary.loggedDays, 2);
      expect(analytics.summary.missingDays, 5);
    });

    test('month and year clamp their effective end to today', () {
      final month = buildPeriod(
        type: AnalyticsRangeType.month,
        anchor: today,
        today: today,
      );
      final year = buildPeriod(
        type: AnalyticsRangeType.year,
        anchor: today,
        today: today,
      );

      expect(month.start, DateTime(2026, 11, 1));
      expect(month.end, DateTime(2026, 11, 30));
      expect(month.effectiveEnd, today);
      expect(year.start, DateTime(2026, 1, 1));
      expect(year.end, DateTime(2026, 12, 31));
      expect(year.effectiveEnd, today);
    });

    test('completed month and year keep their full range', () {
      final month = buildPeriod(
        type: AnalyticsRangeType.month,
        anchor: DateTime(2026, 10, 15),
        today: today,
      );
      final year = buildPeriod(
        type: AnalyticsRangeType.year,
        anchor: DateTime(2025, 6, 1),
        today: today,
      );

      expect(month.start, DateTime(2026, 10, 1));
      expect(month.end, DateTime(2026, 10, 31));
      expect(month.effectiveEnd, DateTime(2026, 10, 31));
      expect(year.start, DateTime(2025, 1, 1));
      expect(year.end, DateTime(2025, 12, 31));
      expect(year.effectiveEnd, DateTime(2025, 12, 31));
    });

    test('custom ranges are inclusive and future-clamped', () {
      final period = buildPeriod(
        type: AnalyticsRangeType.custom,
        anchor: today,
        today: today,
        customStart: DateTime(2026, 11, 1),
        customEnd: DateTime(2026, 12, 1),
      );

      expect(period.start, DateTime(2026, 11, 1));
      expect(period.end, today);
      expect(period.totalDays, 18);
    });

    test('long ranges produce monthly buckets', () {
      final period = buildPeriod(
        type: AnalyticsRangeType.year,
        anchor: today,
        today: today,
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

    testWidgets('defaults to lifetime and switches to a trailing range', (
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

      expect(find.byType(ScoreCard), findsOneWidget);
      expect(find.text('Lifetime'), findsOneWidget);
      expect(find.text('Score'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ScoreCard),
          matching: find.text('Lifetime'),
        ),
        findsOneWidget,
      );
      expect(find.text('Cumulative score'), findsNothing);
      expect(find.textContaining('per day'), findsNothing);
      expect(find.byTooltip('Previous period'), findsNothing);

      expect(find.text('0'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.descendant(of: find.byType(ScoreCard), matching: find.text('+1')),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 250));
      final score = tester.widget<Text>(
        find.descendant(of: find.byType(ScoreCard), matching: find.text('+2')),
      );
      expect(score.style?.color, Score.colors[0]);

      await tester.tap(find.text('Lifetime'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('7D'));
      await tester.pumpAndSettle();

      expect(find.text('7D'), findsOneWidget);
      expect(find.text('Score calendar'), findsOneWidget);
      expect(find.textContaining('Awesome'), findsNothing);
      expect(find.textContaining('Every day in this range'), findsNothing);
    });

    testWidgets('counts a +1 score over the full 500ms', (tester) async {
      final now = DateTime.now();
      await tester.runAsync(() async {
        await hive.put(now, _diary(now, 1));
      });

      await tester.pumpWidget(
        hive.wrap(const MaterialApp(home: Scaffold(body: AnalyticsPage()))),
      );
      await tester.pump();

      Finder scoreText(String text) => find.descendant(
        of: find.byType(ScoreCard),
        matching: find.text(text),
      );

      expect(scoreText('0'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 499));
      expect(scoreText('0'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(scoreText('+1'), findsOneWidget);
    });

    testWidgets('keeps the count at 500ms when system animations are off', (
      tester,
    ) async {
      final now = DateTime.now();
      await tester.runAsync(() async {
        await hive.put(now, _diary(now, 1));
      });

      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await tester.pumpWidget(
        hive.wrap(const MaterialApp(home: Scaffold(body: AnalyticsPage()))),
      );
      await tester.pump();

      Finder scoreText(String text) => find.descendant(
        of: find.byType(ScoreCard),
        matching: find.text(text),
      );

      expect(scoreText('0'), findsOneWidget);
      // Flutter normally compresses decorative animations to 25ms when the
      // device asks for reduced motion. The score count must not collapse.
      await tester.pump(const Duration(milliseconds: 100));
      expect(scoreText('0'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 399));
      expect(scoreText('0'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(scoreText('+1'), findsOneWidget);
    });

    testWidgets('waits for the tab to become visible before counting', (
      tester,
    ) async {
      final now = DateTime.now();
      await tester.runAsync(() async {
        await hive.put(now, _diary(now, 2));
      });

      final visible = ValueNotifier(false);
      addTearDown(visible.dispose);

      await tester.pumpWidget(
        hive.wrap(
          MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: visible,
                builder: (context, enabled, child) =>
                    TickerMode(enabled: enabled, child: child!),
                child: const AnalyticsPage(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      Finder scoreText(String text) => find.descendant(
        of: find.byType(ScoreCard),
        matching: find.text(text),
      );

      // An inactive IndexedStack branch is kept alive but muted. Starting the
      // controller there used to make it finish before the tab was ever shown.
      await tester.pump(const Duration(milliseconds: 600));
      expect(scoreText('0'), findsOneWidget);

      visible.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(scoreText('+1'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      expect(scoreText('+2'), findsOneWidget);
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
