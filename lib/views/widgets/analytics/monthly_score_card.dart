import 'package:flutter/material.dart';

import 'package:peluna/analytics/score_analytics.dart';
import 'package:peluna/views/widgets/analytics/analytics_format.dart';

class MonthlyScoreCard extends StatelessWidget {
  const MonthlyScoreCard({super.key, required this.buckets});

  final List<MonthlyBucket> buckets;

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
              'Monthly scores',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Net score per month, with days that have a score.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final bucket in buckets) _MonthRow(bucket: bucket),
          ],
        ),
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.bucket});

  final MonthlyBucket bucket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summary = bucket.summary;
    final value = summary.netScore;
    final valueColor = value > 0
        ? colorScheme.primary
        : value < 0
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              monthShort(bucket.month),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${summary.loggedDays}/${summary.totalDays} days',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            signedInt(value),
            style: theme.textTheme.titleSmall?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
