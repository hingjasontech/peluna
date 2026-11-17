import 'package:flutter/material.dart';

import 'package:peluna/analytics/score_analytics.dart';
import 'package:peluna/config/constant.dart';
import 'package:peluna/models/week_start.dart';
import 'package:peluna/views/widgets/analytics/analytics_format.dart';
import 'package:peluna/views/widgets/score_circle_widget.dart';

class ScoreCalendarCard extends StatelessWidget {
  const ScoreCalendarCard({
    super.key,
    required this.data,
    required this.period,
    required this.weekStart,
    required this.today,
    required this.onDayTap,
  });

  final AnalyticsData data;
  final AnalyticsPeriod period;
  final WeekStart weekStart;
  final DateTime today;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final startWeekday = switch (weekStart) {
      WeekStart.monday => DateTime.monday,
      WeekStart.sunday => DateTime.sunday,
      WeekStart.saturday => DateTime.saturday,
    };
    final leading = (period.start.weekday - startWeekday + 7) % 7;
    final dayCount = daysInclusive(period.start, period.end);
    final cellCount = ((leading + dayCount) / 7).ceil() * 7;

    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score calendar',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tap a day to open it. Empty days count as 0.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final label in weekdayLabels(weekStart))
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cellCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.72,
                mainAxisSpacing: 4,
                crossAxisSpacing: 2,
              ),
              itemBuilder: (context, index) {
                final dayOffset = index - leading;
                if (dayOffset < 0 || dayOffset >= dayCount) {
                  return const SizedBox.shrink();
                }
                final date = addDays(period.start, dayOffset);
                return _ScoreDayCell(
                  date: date,
                  score: data.scoreFor(date),
                  today: today,
                  onTap: () => onDayTap(date),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreDayCell extends StatelessWidget {
  const _ScoreDayCell({
    required this.date,
    required this.score,
    required this.today,
    required this.onTap,
  });

  final DateTime date;
  final int? score;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFuture = date.isAfter(today);
    final isToday = dateOnly(date) == dateOnly(today);
    final scoreIndex = score == null ? -1 : Score.getIndex(score!);

    final message = isFuture
        ? '${shortDate(date)} · not yet'
        : score == null
        ? '${shortDate(date)} · no score, counts as 0'
        : '${shortDate(date)}: ${Score.labels[scoreIndex]} '
              '(${signedInt(score!)})';

    Widget marker;
    if (isFuture) {
      marker = SizedBox(
        width: 30,
        height: 30,
        child: Center(
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else if (score == null) {
      marker = Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outlineVariant, width: 1),
        ),
        child: Text(
          '–',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    } else {
      marker = isToday
          ? Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary, width: 2),
              ),
              child: ScoreCircleWidget(index: scoreIndex, size: 28),
            )
          : ScoreCircleWidget(index: scoreIndex, size: 30);
    }

    return Tooltip(
      message: message,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: isFuture ? null : onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isFuture
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                    : colorScheme.onSurfaceVariant,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            marker,
          ],
        ),
      ),
    );
  }
}
