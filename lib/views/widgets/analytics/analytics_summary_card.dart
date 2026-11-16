import 'package:flutter/material.dart';

import 'package:peluna/analytics/mood_analytics.dart';
import 'package:peluna/views/widgets/analytics/analytics_controls.dart';
import 'package:peluna/views/widgets/analytics/analytics_format.dart';

class AnalyticsSummaryCard extends StatelessWidget {
  const AnalyticsSummaryCard({
    super.key,
    required this.summary,
    required this.metric,
    required this.onMetricChanged,
    required this.isLifetime,
  });

  final MoodSummary summary;
  final ScoreMetric metric;
  final ValueChanged<ScoreMetric> onMetricChanged;
  final bool isLifetime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showsNet = metric == ScoreMetric.net;

    final value = showsNet ? summary.netScore.toDouble() : summary.average;
    final valueColor = moodScoreColor(summary.average);

    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isLifetime ? 'LIFETIME' : 'SELECTED RANGE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                AnalyticsMetricToggle(
                  metric: metric,
                  onChanged: onMetricChanged,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey('${metric.name}:$value'),
                      tween: Tween<double>(begin: 0, end: value),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedValue, _) {
                        return Text(
                          showsNet
                              ? signedInt(animatedValue.round())
                              : signedAverage(animatedValue),
                          maxLines: 1,
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: valueColor,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    showsNet ? 'points' : 'per day',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
