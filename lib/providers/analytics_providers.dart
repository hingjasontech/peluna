import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/analytics/mood_analytics.dart';
import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/providers/diary_providers.dart';

/// Today as a local calendar date. Overridable in tests for deterministic
/// ranges.
final analyticsTodayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return dateOnly(now);
});

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
}

class AnalyticsRangeNotifier extends Notifier<AnalyticsRangeRequest> {
  @override
  AnalyticsRangeRequest build() {
    return AnalyticsRangeRequest(
      type: AnalyticsRangeType.lifetime,
      anchor: ref.read(analyticsTodayProvider),
    );
  }

  void selectPeriod(AnalyticsRangeType type, {int? year, int? month}) {
    if (type == AnalyticsRangeType.custom) return;
    final today = ref.read(analyticsTodayProvider);
    final anchor = switch (type) {
      AnalyticsRangeType.year => DateTime(year ?? today.year, 1, 1),
      AnalyticsRangeType.month => DateTime(
        year ?? today.year,
        month ?? today.month,
        1,
      ),
      _ => today,
    };
    state = AnalyticsRangeRequest(type: type, anchor: anchor);
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
    customStart: request.customStart,
    customEnd: request.customEnd,
  );
});

final periodAnalyticsProvider = Provider<PeriodAnalytics?>((ref) {
  final period = ref.watch(analyticsPeriodProvider);
  if (period == null) return null;

  return buildPeriodAnalytics(ref.watch(analyticsDataProvider), period);
});
