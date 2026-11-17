import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:peluna/analytics/mood_analytics.dart';
import 'package:peluna/config/constant.dart';
import 'package:peluna/views/widgets/analytics/analytics_format.dart';

class CumulativeScoreCard extends StatelessWidget {
  const CumulativeScoreCard({
    super.key,
    required this.points,
    required this.summary,
    required this.title,
  });

  final List<CumulativePoint> points;
  final MoodSummary summary;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelStyle = (theme.textTheme.labelSmall ?? const TextStyle())
        .copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        );

    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (points.isEmpty)
              SizedBox(
                height: 150,
                child: Center(
                  child: Text(
                    'No score data yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Semantics(
                label:
                    'Cumulative score chart from '
                    '${shortDate(points.first.date)} to '
                    '${shortDate(points.last.date)}',
                child: SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _CumulativeChartPainter(
                        points: points,
                        positiveColor: Mood.moodColors[1],
                        negativeColor: Mood.moodColors[3],
                        neutralColor: Mood.moodColors[2],
                        gridColor: colorScheme.outlineVariant,
                        dotBorderColor: colorScheme.surfaceContainerHighest,
                        labelStyle: labelStyle,
                        textScaler: MediaQuery.textScalerOf(context),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
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
              const SizedBox(height: 12),
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
                padding: const EdgeInsets.symmetric(vertical: 16),
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
            const SizedBox(height: 12),
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

class _CumulativeChartPainter extends CustomPainter {
  _CumulativeChartPainter({
    required this.points,
    required this.positiveColor,
    required this.negativeColor,
    required this.neutralColor,
    required this.gridColor,
    required this.dotBorderColor,
    required this.labelStyle,
    required this.textScaler,
  });

  final List<CumulativePoint> points;
  final Color positiveColor;
  final Color negativeColor;
  final Color neutralColor;
  final Color gridColor;
  final Color dotBorderColor;
  final TextStyle labelStyle;
  final TextScaler textScaler;

  Color _colorFor(num value) {
    if (value > 0) return positiveColor;
    if (value < 0) return negativeColor;
    return neutralColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTRB(42, 10, size.width - 4, size.height - 28);
    if (chart.width <= 0 || chart.height <= 0) return;

    var minY = 0;
    var maxY = 0;
    for (final point in points) {
      minY = math.min(minY, point.cumulative);
      maxY = math.max(maxY, point.cumulative);
    }
    if (minY == maxY) {
      if (minY == 0) {
        minY = -1;
        maxY = 1;
      } else {
        minY = minY > 0 ? 0 : minY - 1;
        maxY = maxY < 0 ? 0 : maxY + 1;
      }
    }

    double yFor(num value) {
      final t = (value - minY) / (maxY - minY);
      return chart.bottom - t * chart.height;
    }

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;

    final ticks = <int>{minY, 0, maxY}.toList()..sort();
    for (final tick in ticks) {
      final y = yFor(tick);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      _paintText(
        canvas,
        signedInt(tick),
        Offset(chart.left - 8, y),
        alignRight: true,
        centreVertically: true,
      );
    }

    Offset pointOffset(int index) {
      final x = points.length == 1
          ? chart.center.dx
          : chart.left + (index / (points.length - 1)) * chart.width;
      return Offset(x, yFor(points[index].cumulative));
    }

    if (points.length == 1) {
      final point = pointOffset(0);
      final zeroY = yFor(0);
      canvas.drawLine(
        Offset(point.dx, zeroY),
        point,
        Paint()
          ..color = _colorFor(points[0].cumulative).withValues(alpha: 0.35)
          ..strokeWidth = 2,
      );
    } else {
      final positivePaint = Paint()
        ..color = positiveColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      final negativePaint = Paint()
        ..color = negativeColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      final neutralPaint = Paint()
        ..color = neutralColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      void drawSegment(Offset a, Offset b, num from, num to) {
        if (from == 0 && to == 0) {
          canvas.drawLine(a, b, neutralPaint);
          return;
        }
        if (from >= 0 && to >= 0) {
          canvas.drawLine(a, b, positivePaint);
          return;
        }
        if (from <= 0 && to <= 0) {
          canvas.drawLine(a, b, negativePaint);
          return;
        }

        final t = from / (from - to);
        final crossing = Offset.lerp(a, b, t)!;
        if (from > 0) {
          canvas.drawLine(a, crossing, positivePaint);
          canvas.drawLine(crossing, b, negativePaint);
        } else {
          canvas.drawLine(a, crossing, negativePaint);
          canvas.drawLine(crossing, b, positivePaint);
        }
      }

      for (var i = 1; i < points.length; i++) {
        drawSegment(
          pointOffset(i - 1),
          pointOffset(i),
          points[i - 1].cumulative,
          points[i].cumulative,
        );
      }
    }

    if (points.length <= 90) {
      final dotBorder = Paint()
        ..color = dotBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      for (var i = 0; i < points.length; i++) {
        final mood = points[i].mood;
        if (mood == null) continue;
        final moodIndex = Mood.getIndex(mood);
        final dotColor = moodIndex == -1
            ? _colorFor(points[i].cumulative)
            : Mood.moodColors[moodIndex];
        final offset = pointOffset(i);
        canvas.drawCircle(offset, 3.2, Paint()..color = dotColor);
        canvas.drawCircle(offset, 3.2, dotBorder);
      }
    }

    final sameYear = points.first.date.year == points.last.date.year;
    final firstLabel = sameYear
        ? shortDate(points.first.date)
        : fullDate(points.first.date);
    final lastLabel = sameYear
        ? shortDate(points.last.date)
        : fullDate(points.last.date);
    if (firstLabel == lastLabel) {
      _paintText(
        canvas,
        firstLabel,
        Offset(chart.center.dx, chart.bottom + 8),
        centreHorizontally: true,
      );
    } else {
      _paintText(canvas, firstLabel, Offset(chart.left, chart.bottom + 8));
      _paintText(
        canvas,
        lastLabel,
        Offset(chart.right, chart.bottom + 8),
        alignRight: true,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset anchor, {
    bool alignRight = false,
    bool centreHorizontally = false,
    bool centreVertically = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();

    var dx = anchor.dx;
    if (alignRight) dx -= painter.width;
    if (centreHorizontally) dx -= painter.width / 2;
    final dy = centreVertically ? anchor.dy - painter.height / 2 : anchor.dy;
    painter.paint(canvas, Offset(dx, dy));
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _CumulativeChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.positiveColor != positiveColor ||
        oldDelegate.negativeColor != negativeColor ||
        oldDelegate.neutralColor != neutralColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.dotBorderColor != dotBorderColor ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.textScaler != textScaler;
  }
}
