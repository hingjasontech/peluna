import 'package:flutter/material.dart';

import 'package:peluna/analytics/mood_analytics.dart';
import 'package:peluna/views/widgets/analytics/analytics_format.dart';

class AnalyticsSummaryCard extends StatelessWidget {
  const AnalyticsSummaryCard({
    super.key,
    required this.summary,
    required this.rangeSelector,
  });

  final MoodSummary summary;
  final Widget rangeSelector;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Score',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                rangeSelector,
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _AnimatedScore(
                      // Restart the count from zero whenever the selected
                      // period changes, even if the net score happens to be
                      // the same.
                      key: ValueKey(
                        '${summary.start.millisecondsSinceEpoch}:'
                        '${summary.end.millisecondsSinceEpoch}',
                      ),
                      value: summary.netScore,
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: moodScoreColor(summary.netScore),
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'points',
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

class _AnimatedScore extends StatefulWidget {
  const _AnimatedScore({super.key, required this.value, required this.style});

  final int value;
  final TextStyle? style;

  @override
  State<_AnimatedScore> createState() => _AnimatedScoreState();
}

class _AnimatedScoreState extends State<_AnimatedScore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = _tween(0, widget.value);
    _controller.forward();
  }

  Animation<double> _tween(double begin, int end) {
    return Tween<double>(
      begin: begin,
      end: end.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _AnimatedScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    final from = _animation.value;
    _animation = _tween(from, widget.value);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Text(
          signedInt(_animation.value.round()),
          maxLines: 1,
          style: widget.style,
        );
      },
    );
  }
}
