import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/analytics/mood_analytics.dart';
import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/providers/diary_providers.dart';
import 'package:peluna/providers/settings_providers.dart';

/// Today as a local calendar date. Overridable in tests for deterministic
/// ranges.
final analyticsTodayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return dateOnly(now);
});

class ScoreMetricNotifier extends Notifier<ScoreMetric> {
  @override
  ScoreMetric build() => ScoreMetric.net;

  void select(ScoreMetric metric) => state = metric;
}

final scoreMetricProvider = NotifierProvider<ScoreMetricNotifier, ScoreMetric>(
  ScoreMetricNotifier.new,
);

class AnalyticsRangeRequest {
  const AnalyticsRangeRequest({
    required this.type,
    required this.anchor,
    this.customStart,
    this.customEnd,
  });

  final AnalyticsRangeType type;
  final DateTime anchor;
  final DateTime? customStart;
  final DateTime? customEnd;

  AnalyticsRangeRequest copyWith({
    AnalyticsRangeType? type,
    DateTime? anchor,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return AnalyticsRangeRequest(
      type: type ?? this.type,
      anchor: anchor ?? this.anchor,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
    );
  }
}

class AnalyticsRangeNotifier extends Notifier<AnalyticsRangeRequest> {
  @override
  AnalyticsRangeRequest build() {
    return AnalyticsRangeRequest(
      type: AnalyticsRangeType.lifetime,
      anchor: ref.read(analyticsTodayProvider),
    );
  }

  void selectType(AnalyticsRangeType type) {
    if (type == AnalyticsRangeType.custom) return;
    state = state.copyWith(type: type);
  }

  void setCustomRange(DateTime start, DateTime end) {
    final today = ref.read(analyticsTodayProvider);
    var to = dateOnly(end);
    if (to.isAfter(today)) to = today;
    var from = dateOnly(start);
    if (from.isAfter(to)) from = to;

    state = AnalyticsRangeRequest(
      type: AnalyticsRangeType.custom,
      anchor: to,
      customStart: from,
      customEnd: to,
    );
  }

  void previous() {
    final type = state.type;
    if (type == AnalyticsRangeType.custom ||
        type == AnalyticsRangeType.lifetime) {
      return;
    }
    state = state.copyWith(anchor: _previousAnchor(type, state.anchor));
  }

  void next() {
    final type = state.type;
    if (type == AnalyticsRangeType.custom ||
        type == AnalyticsRangeType.lifetime) {
      return;
    }

    final today = ref.read(analyticsTodayProvider);
    final nextAnchor = _nextAnchor(type, state.anchor);
    if (dateOnly(nextAnchor).isAfter(today)) return;
    state = state.copyWith(anchor: nextAnchor);
  }

  void goToToday() {
    state = state.copyWith(anchor: ref.read(analyticsTodayProvider));
  }

  DateTime _previousAnchor(AnalyticsRangeType type, DateTime anchor) {
    return switch (type) {
      AnalyticsRangeType.lifetime => anchor,
      AnalyticsRangeType.week => addDays(anchor, -7),
      AnalyticsRangeType.month => DateTime(anchor.year, anchor.month - 1, 1),
      AnalyticsRangeType.year => DateTime(anchor.year - 1, 1, 1),
      AnalyticsRangeType.custom => anchor,
    };
  }

  DateTime _nextAnchor(AnalyticsRangeType type, DateTime anchor) {
    return switch (type) {
      AnalyticsRangeType.lifetime => anchor,
      AnalyticsRangeType.week => addDays(anchor, 7),
      AnalyticsRangeType.month => DateTime(anchor.year, anchor.month + 1, 1),
      AnalyticsRangeType.year => DateTime(anchor.year + 1, 1, 1),
      AnalyticsRangeType.custom => anchor,
    };
  }
}

final analyticsRangeProvider =
    NotifierProvider<AnalyticsRangeNotifier, AnalyticsRangeRequest>(
      AnalyticsRangeNotifier.new,
    );

/// All saved diaries, refreshed on every Hive box change.
final analyticsDataProvider = Provider<AnalyticsData>((ref) {
  ref.watch(diaryRevisionProvider);
  return AnalyticsData.fromDiaries(ref.watch(diaryRepositoryProvider).getAll());
});

final analyticsPeriodProvider = Provider<AnalyticsPeriod?>((ref) {
  final request = ref.watch(analyticsRangeProvider);
  final today = ref.watch(analyticsTodayProvider);

  if (request.type == AnalyticsRangeType.lifetime) {
    return buildLifetimePeriod(ref.watch(analyticsDataProvider), today);
  }

  return buildPeriod(
    type: request.type,
    anchor: request.anchor,
    today: today,
    weekStart: ref.watch(weekStartProvider),
    customStart: request.customStart,
    customEnd: request.customEnd,
  );
});

final periodAnalyticsProvider = Provider<PeriodAnalytics?>((ref) {
  final period = ref.watch(analyticsPeriodProvider);
  if (period == null) return null;

  return buildPeriodAnalytics(ref.watch(analyticsDataProvider), period);
});
