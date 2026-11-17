import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:peluna/analytics/mood_analytics.dart';
import 'package:peluna/providers/analytics_providers.dart';
import 'package:peluna/providers/diary_providers.dart';
import 'package:peluna/providers/settings_providers.dart';
import 'package:peluna/views/widgets/analytics/analytics_controls.dart';
import 'package:peluna/views/widgets/analytics/analytics_summary_card.dart';
import 'package:peluna/views/widgets/analytics/cumulative_score_card.dart';
import 'package:peluna/views/widgets/analytics/monthly_score_card.dart';
import 'package:peluna/views/widgets/analytics/mood_calendar_card.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(analyticsRangeProvider);
    final analytics = ref.watch(periodAnalyticsProvider);
    final period = analytics?.period;
    final today = ref.watch(analyticsTodayProvider);
    final data = ref.watch(analyticsDataProvider);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Card.filled(
              margin: EdgeInsets.zero,
              child: AnalyticsRangeDropdown(
                type: request.type,
                anchor: request.anchor,
                today: today,
                firstEntry: data.firstEntryDate,
                period: period,
                onSelected: (selection) {
                  if (selection.type == AnalyticsRangeType.custom) {
                    _pickCustomRange(context, ref);
                    return;
                  }
                  ref
                      .read(analyticsRangeProvider.notifier)
                      .selectPeriod(
                        selection.type,
                        year: selection.year,
                        month: selection.month,
                      );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (analytics == null)
              _EmptyAnalytics(onWrite: () => _openDay(context, ref, today))
            else
              _AnalyticsView(analytics: analytics),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsView extends ConsumerWidget {
  const _AnalyticsView({required this.analytics});

  final PeriodAnalytics analytics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = analytics.period;
    final summary = analytics.summary;
    final today = ref.watch(analyticsTodayProvider);
    final weekStart = ref.watch(weekStartProvider);
    final isLifetime = period.type == AnalyticsRangeType.lifetime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnalyticsSummaryCard(summary: summary, isLifetime: isLifetime),
        const SizedBox(height: 16),
        CumulativeScoreCard(
          points: analytics.points,
          summary: summary,
          title: 'Cumulative score',
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
