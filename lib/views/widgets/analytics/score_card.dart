import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:peluna/analytics/score_analytics.dart';
import 'package:peluna/config/constant.dart';
import 'package:peluna/views/widgets/analytics/analytics_format.dart';

/// The analytics overview: net score, cumulative chart, and score mix.
class ScoreCard extends StatelessWidget {
  const ScoreCard({
    super.key,
    required this.summary,
    required this.points,
    required this.rangeSelector,
  });

  final ScoreSummary summary;
  final List<CumulativePoint> points;
  final Widget rangeSelector;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Score',
                    style: theme.textTheme.titleMedium?.copyWith(
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
                        color: scoreColor(summary.netScore),
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
            const SizedBox(height: 18),
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
                        positiveColor: Score.colors[1],
                        negativeColor: Score.colors[3],
                        neutralColor: Score.colors[2],
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
                      for (final score in Score.values)
                        if (summary.countFor(score) > 0)
                          Expanded(
                            flex: summary.countFor(score),
                            child: ColoredBox(
                              color: Score.colors[Score.getIndex(score)],
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
                  for (var index = 0; index < Score.values.length; index++)
                    _LegendItem(
                      color: Score.colors[index],
                      label: Score.labels[index],
                      count: summary.countFor(Score.values[index]),
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
                  'Add a score to a diary entry to see the mix.',
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
                  : 'Every day in this range has a score.',
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

class _AnimatedScore extends StatefulWidget {
  const _AnimatedScore({super.key, required this.value, required this.style});

  final int value;
  final TextStyle? style;

  @override
  State<_AnimatedScore> createState() => _AnimatedScoreState();
}

class _AnimatedScoreState extends State<_AnimatedScore>
    with SingleTickerProviderStateMixin {
  /// The count always takes this long, no matter how far the score moves.
  static const Duration _countDuration = Duration(milliseconds: 500);

  late final AnimationController _controller;
  int _from = 0;
  late int _to;

  @override
  void initState() {
    super.initState();
    _to = widget.value;
    _controller = AnimationController(vsync: this, duration: _countDuration)
      ..forward();
  }

  /// Advances one point at a time, with the final point landing on the last
  /// frame so even a +1 change uses the full [_countDuration].
  int get _displayedValue {
    final delta = _to - _from;
    if (delta == 0) return _to;

    final steps = delta.abs();
    final completed = (_controller.value * steps).floor();
    return _from + delta.sign * math.min(completed, steps);
  }

  @override
  void didUpdateWidget(covariant _AnimatedScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    _from = _displayedValue;
    _to = widget.value;
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
          signedInt(_displayedValue),
          maxLines: 1,
          style: widget.style,
        );
      },
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
    final chart = Rect.fromLTRB(38, 10, size.width - 6, size.height - 26);
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

    Offset pointOffset(int index) {
      final x = points.length == 1
          ? chart.center.dx
          : chart.left + (index / (points.length - 1)) * chart.width;
      return Offset(x, yFor(points[index].cumulative));
    }

    final zeroY = yFor(0).clamp(chart.top, chart.bottom);

    final line = Path();
    final firstPoint = pointOffset(0);
    line.moveTo(firstPoint.dx, firstPoint.dy);
    for (var index = 0; index < points.length - 1; index++) {
      final previous = pointOffset(math.max(0, index - 1));
      final start = pointOffset(index);
      final end = pointOffset(index + 1);
      final next = pointOffset(math.min(points.length - 1, index + 2));
      final control1 = start + (end - previous) / 6;
      final control2 = end - (next - start) / 6;
      line.cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        end.dx,
        end.dy,
      );
    }

    final area = Path.from(line)
      ..lineTo(pointOffset(points.length - 1).dx, zeroY)
      ..lineTo(firstPoint.dx, zeroY)
      ..close();

    canvas.save();
    canvas.clipRect(chart);

    final above = Rect.fromLTRB(chart.left, chart.top, chart.right, zeroY);
    if (above.height > 0) {
      canvas.save();
      canvas.clipRect(above);
      canvas.drawPath(
        area,
        Paint()
          ..shader =
              ui.Gradient.linear(Offset(0, chart.top), Offset(0, zeroY), [
                positiveColor.withValues(alpha: 0.30),
                positiveColor.withValues(alpha: 0),
              ]),
      );
      canvas.restore();
    }

    final below = Rect.fromLTRB(chart.left, zeroY, chart.right, chart.bottom);
    if (below.height > 0) {
      canvas.save();
      canvas.clipRect(below);
      canvas.drawPath(
        area,
        Paint()
          ..shader =
              ui.Gradient.linear(Offset(0, zeroY), Offset(0, chart.bottom), [
                negativeColor.withValues(alpha: 0),
                negativeColor.withValues(alpha: 0.30),
              ]),
      );
      canvas.restore();
    }

    canvas.restore();

    final zeroPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    var dashStart = 0.0;
    while (dashStart < chart.width) {
      final dashEnd = math.min(dashStart + 2, chart.width);
      canvas.drawLine(
        Offset(chart.left + dashStart, zeroY),
        Offset(chart.left + dashEnd, zeroY),
        zeroPaint,
      );
      dashStart = dashEnd + 6;
    }

    if (points.length == 1) {
      final point = firstPoint;
      canvas.drawLine(
        Offset(point.dx, zeroY),
        point,
        Paint()
          ..color = _colorFor(points[0].cumulative).withValues(alpha: 0.35)
          ..strokeWidth = 2,
      );
    }

    final lineAbove = Rect.fromLTRB(chart.left, chart.top, chart.right, zeroY);
    final lineBelow = Rect.fromLTRB(
      chart.left,
      zeroY,
      chart.right,
      chart.bottom,
    );
    for (final (rect, color) in [
      (lineAbove, positiveColor),
      (lineBelow, negativeColor),
    ]) {
      if (rect.height <= 0) continue;
      canvas.save();
      canvas.clipRect(rect);
      canvas.drawPath(
        line,
        Paint()
          ..color = color.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 6),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.restore();
    }

    final lastPoint = pointOffset(points.length - 1);
    final lastColor = _colorFor(points.last.cumulative);
    canvas.drawCircle(
      lastPoint,
      9.5,
      Paint()..color = lastColor.withValues(alpha: 0.18),
    );
    canvas.drawCircle(lastPoint, 4.5, Paint()..color = lastColor);
    canvas.drawCircle(
      lastPoint,
      4.5,
      Paint()
        ..color = dotBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

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
