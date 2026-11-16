import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:peluna/analytics/mood_analytics.dart';
import 'package:peluna/providers/analytics_providers.dart';
import 'package:peluna/providers/diary_providers.dart';
import 'package:peluna/providers/settings_providers.dart';
import 'package:peluna/views/widgets/analytics/analytics_controls.dart';
import 'package:peluna/views/widgets/analytics/analytics_format.dart';
import 'package:peluna/views/widgets/analytics/analytics_summary_card.dart';
import 'package:peluna/views/widgets/analytics/cumulative_score_card.dart';
import 'package:peluna/views/widgets/analytics/monthly_score_card.dart';
import 'package:peluna/views/widgets/analytics/mood_calendar_card.dart';
import 'package:peluna/views/widgets/analytics/mood_distribution_card.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metric = ref.watch(scoreMetricProvider);
    final type = ref.watch(analyticsRangeProvider).type;
    final analytics = ref.watch(periodAnalyticsProvider);
    final period = analytics?.period;
    final today = ref.watch(analyticsTodayProvider);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Card.filled(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Column(
                  children: [
                    AnalyticsRangeTypeSelector(
                      type: type,
                      onChanged: (value) {
                        if (value == AnalyticsRangeType.custom) {
                          _pickCustomRange(context, ref);
                        } else {
                          ref
                              .read(analyticsRangeProvider.notifier)
                              .selectType(value);
                        }
                      },
                    ),
                    if (period != null &&
                        period.type != AnalyticsRangeType.lifetime) ...[
                      const SizedBox(height: 2),
                      AnalyticsRangeBar(
                        period: period,
                        today: today,
                        canGoNext: canGoToNextPeriod(period, today),
                        onPrevious: () => ref
                            .read(analyticsRangeProvider.notifier)
                            .previous(),
                        onNext: () =>
                            ref.read(analyticsRangeProvider.notifier).next(),
                        onToday: () => ref
                            .read(analyticsRangeProvider.notifier)
                            .goToToday(),
                        onPickCustom: () => _pickCustomRange(context, ref),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (analytics == null)
              _EmptyAnalytics(onWrite: () => _openDay(context, ref, today))
            else
              _AnalyticsView(analytics: analytics, metric: metric),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsView extends ConsumerWidget {
  const _AnalyticsView({required this.analytics, required this.metric});

  final PeriodAnalytics analytics;
  final ScoreMetric metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = analytics.period;
    final summary = analytics.summary;
    final today = ref.watch(analyticsTodayProvider);
    final weekStart = ref.watch(weekStartProvider);
    final isLifetime = period.type == AnalyticsRangeType.lifetime;
    final isCustom = period.type == AnalyticsRangeType.custom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnalyticsSummaryCard(
          summary: summary,
          metric: metric,
          onMetricChanged: (value) =>
              ref.read(scoreMetricProvider.notifier).select(value),
          isLifetime: isLifetime,
        ),
        const SizedBox(height: 16),
        CumulativeScoreCard(
          points: analytics.points,
          title: 'Cumulative score',
          subtitle: isLifetime
              ? 'Since ${fullDate(period.start)} · '
                    '${countDays(summary.totalDays)} tracked'
              : isCustom
              ? '${countDays(summary.totalDays)} selected · '
                    '${summary.loggedDays} logged'
              : '${summary.loggedDays} of '
                    '${summary.totalDays} days logged',
        ),
        if (analytics.monthlyBuckets.isNotEmpty) ...[
          const SizedBox(height: 16),
          MonthlyScoreCard(buckets: analytics.monthlyBuckets),
        ],
        if (period.totalDays <= 31) ...[
          const SizedBox(height: 16),
          MoodCalendarCard(
            data: ref.watch(analyticsDataProvider),
            period: period,
            weekStart: weekStart,
            today: today,
            onDayTap: (date) => _openDay(context, ref, date),
          ),
        ],
        const SizedBox(height: 16),
        MoodDistributionCard(summary: summary),
      ],
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics({required this.onWrite});

  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          children: [
            Icon(Icons.insights_outlined, size: 44, color: colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              'Your score starts with one entry',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Every day after your first entry counts. Days without a mood '
              'add 0, so the cumulative line never skips a day.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onWrite,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Write today'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
  final today = ref.read(analyticsTodayProvider);
  final request = ref.read(analyticsRangeProvider);
  final period = ref.read(analyticsPeriodProvider);
  final defaultStart = period?.start ?? today;
  final defaultEnd = period?.effectiveEnd ?? today;
  final start = request.type == AnalyticsRangeType.custom
      ? request.customStart ?? defaultStart
      : defaultStart;
  final end = request.type == AnalyticsRangeType.custom
      ? request.customEnd ?? defaultEnd
      : defaultEnd;

  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(today.year - 50, 1, 1),
    lastDate: today,
    initialDateRange: DateTimeRange(start: start, end: end),
    helpText: 'Select a date range',
    saveText: 'Apply',
  );

  if (picked == null) return;
  ref
      .read(analyticsRangeProvider.notifier)
      .setCustomRange(picked.start, picked.end);
}

void _openDay(BuildContext context, WidgetRef ref, DateTime date) {
  ref.read(selectedDateProvider.notifier).select(date);
  context.pushNamed('diary');
}
