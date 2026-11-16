import 'package:flutter/material.dart';

import 'package:peluna/analytics/mood_analytics.dart';
import 'package:peluna/config/constant.dart';
import 'package:peluna/views/widgets/analytics/analytics_format.dart';

class MoodDistributionCard extends StatelessWidget {
  const MoodDistributionCard({super.key, required this.summary});

  final MoodSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood mix',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              summary.loggedDays == 0
                  ? 'No moods logged in this range.'
                  : '${countDays(summary.loggedDays)} with a mood',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (summary.loggedDays > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      for (final mood in Mood.moodInt)
                        if (summary.countFor(mood) > 0)
                          Expanded(
                            flex: summary.countFor(mood),
                            child: ColoredBox(
                              color: Mood.moodColors[Mood.getIndex(mood)],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  for (var index = 0; index < Mood.moodInt.length; index++)
                    _LegendItem(
                      color: Mood.moodColors[index],
                      label: Mood.moodString[index],
                      count: summary.countFor(Mood.moodInt[index]),
                    ),
                ],
              ),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Add a mood to a diary entry to see the mix.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Text(
              summary.missingDays > 0
                  ? '${summary.missingDays} missing '
                        '${summary.missingDays == 1 ? 'day counts' : 'days count'} as 0.'
                  : 'Every day in this range has a mood.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label $count',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
