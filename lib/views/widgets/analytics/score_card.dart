import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:peluna/analytics/score_analytics.dart';
import 'package:peluna/config/constant.dart';
import 'package:peluna/views/widgets/analytics/analytics_format.dart';

/// The analytics overview: net score and cumulative chart.
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
  /// The count always takes this long, no matter how far the score moves.
  static const Duration _countDuration = Duration(milliseconds: 500);

  late final AnimationController _controller;
  int _from = 0;
  late int _to;
  bool _tickerEnabled = true;
  bool _pendingStart = true;

  @override
  void initState() {
    super.initState();
    _to = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: _countDuration,
      // The score is a readable number rather than decorative motion. Without
      // this, Flutter collapses the count to 25ms when the device has system
      // animations disabled, which makes the score jump to its final value.
      animationBehavior: AnimationBehavior.preserve,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    if (_tickerEnabled && _pendingStart) {
      _pendingStart = false;
      _controller.forward(from: 0);
    }
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
    _pendingStart = true;
    if (_tickerEnabled) {
      _pendingStart = false;
      _controller.forward(from: 0);
    }
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
        final displayed = _displayedValue;
        return Text(
          signedInt(displayed),
          maxLines: 1,
          style: widget.style?.copyWith(color: scoreColor(displayed)),
        );
      },
    );
  }
}

class _ChartLabel {
  const _ChartLabel(this.text, this.left, this.width);

  final String text;
  final double left;
  final double width;
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
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;

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
      } else if (minY > 0) {
        minY = 0;
      } else {
        maxY = 0;
      }
    }

    final ticks = _axisTicks(minY, maxY);
    final tickLabels = [for (final tick in ticks) _formatAxisValue(tick)];
    final yLabelWidth = _maxTextWidth(tickLabels);
    final labelHeight = _textHeight('0');

    final plot = Rect.fromLTRB(
      yLabelWidth + 12,
      math.max(14, labelHeight / 2 + 4),
      size.width - 16,
      size.height - (labelHeight + 14),
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    final domainMin = ticks.first.toDouble();
    final domainMax = ticks.last.toDouble();

    double yFor(num value) {
      final t = (value - domainMin) / (domainMax - domainMin);
      return plot.bottom - t * plot.height;
    }

    Offset pointOffset(int index) {
      final x = points.length == 1
          ? plot.center.dx
          : plot.left + (index / (points.length - 1)) * plot.width;
      return Offset(x, yFor(points[index].cumulative));
    }

    final zeroY = yFor(0).clamp(plot.top, plot.bottom);

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

    final lastPoint = pointOffset(points.length - 1);
    final area = Path.from(line)
      ..lineTo(lastPoint.dx, zeroY)
      ..lineTo(firstPoint.dx, zeroY)
      ..close();

    _paintArea(canvas, area, plot, zeroY);
    _paintGrid(canvas, plot, ticks, yFor);

    if (points.length == 1) {
      canvas.drawLine(
        Offset(firstPoint.dx, zeroY),
        firstPoint,
        Paint()
          ..color = _colorFor(points[0].cumulative).withValues(alpha: 0.35)
          ..strokeWidth = 2,
      );
    }

    // Clip only at the zero line so the glow can spill into the side padding.
    // Clipping to the plot rectangle used to cut off the left start and the
    // endpoint halo.
    final positiveClip = Rect.fromLTRB(0, 0, size.width, zeroY);
    if (positiveClip.height > 0) {
      canvas.save();
      canvas.clipRect(positiveClip);
      _paintStroke(canvas, line, positiveColor);
      canvas.restore();
    }

    final negativeClip = Rect.fromLTRB(0, zeroY, size.width, size.height);
    if (negativeClip.height > 0) {
      canvas.save();
      canvas.clipRect(negativeClip);
      _paintStroke(canvas, line, negativeColor);
      canvas.restore();
    }

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

    for (var index = 0; index < ticks.length; index++) {
      _paintText(
        canvas,
        tickLabels[index],
        Offset(plot.left - 8, yFor(ticks[index])),
        alignRight: true,
        centreVertically: true,
      );
    }

    for (final label in _buildXLabels(plot)) {
      _paintText(canvas, label.text, Offset(label.left, plot.bottom + 8));
    }
  }

  void _paintArea(Canvas canvas, Path area, Rect plot, double zeroY) {
    final layerBounds = plot.inflate(1);
    canvas.saveLayer(layerBounds, Paint());

    final above = Rect.fromLTRB(
      layerBounds.left,
      layerBounds.top,
      layerBounds.right,
      zeroY,
    );
    if (above.height > 0) {
      canvas.save();
      canvas.clipRect(above);
      canvas.drawPath(
        area,
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, plot.top), Offset(0, zeroY), [
            positiveColor.withValues(alpha: 0.30),
            positiveColor.withValues(alpha: 0),
          ]),
      );
      canvas.restore();
    }

    final below = Rect.fromLTRB(
      layerBounds.left,
      zeroY,
      layerBounds.right,
      layerBounds.bottom,
    );
    if (below.height > 0) {
      canvas.save();
      canvas.clipRect(below);
      canvas.drawPath(
        area,
        Paint()
          ..shader =
              ui.Gradient.linear(Offset(0, zeroY), Offset(0, plot.bottom), [
                negativeColor.withValues(alpha: 0),
                negativeColor.withValues(alpha: 0.30),
              ]),
      );
      canvas.restore();
    }

    // Fade the fill at both ends. The area used to close with a hard vertical
    // wall at the newest point, which looked like the chart was cut off.
    final fade = math.min(18.0, plot.width * 0.12);
    if (fade > 0) {
      final stop = fade / plot.width;
      canvas.drawRect(
        layerBounds,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.linear(
            Offset(plot.left, 0),
            Offset(plot.right, 0),
            const [
              Color(0x00FFFFFF),
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
              Color(0x00FFFFFF),
            ],
            [0, stop, 1 - stop, 1],
          ),
      );
    }

    canvas.restore();
  }

  void _paintGrid(
    Canvas canvas,
    Rect plot,
    List<int> ticks,
    double Function(num) yFor,
  ) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    final zeroPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.75)
      ..strokeWidth = 1;

    for (final tick in ticks) {
      final y = yFor(tick);
      canvas.drawLine(
        Offset(plot.left, y),
        Offset(plot.right, y),
        tick == 0 ? zeroPaint : gridPaint,
      );
    }
  }

  void _paintStroke(Canvas canvas, Path line, Color color) {
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
  }

  List<_ChartLabel> _buildXLabels(Rect plot) {
    final sameYear = points.first.date.year == points.last.date.year;
    String labelFor(int index) {
      final date = points[index].date;
      return sameYear ? shortDate(date) : fullDate(date);
    }

    for (final desired in const [4, 3, 2, 1]) {
      final indices = _xLabelIndices(points.length, desired);
      final labels = <_ChartLabel>[];
      var fits = true;

      for (var position = 0; position < indices.length; position++) {
        final index = indices[position];
        final text = labelFor(index);
        final width = _textWidth(text);

        final double left;
        if (indices.length == 1) {
          left = plot.center.dx - width / 2;
        } else if (position == 0) {
          left = plot.left;
        } else if (position == indices.length - 1) {
          left = plot.right - width;
        } else {
          final x = points.length == 1
              ? plot.center.dx
              : plot.left + (index / (points.length - 1)) * plot.width;
          left = x - width / 2;
        }

        if (left < plot.left - 0.5 || left + width > plot.right + 0.5) {
          fits = false;
          break;
        }
        labels.add(_ChartLabel(text, left, width));
      }

      if (!fits) continue;

      labels.sort((a, b) => a.left.compareTo(b.left));
      for (var index = 1; index < labels.length; index++) {
        final gap =
            labels[index].left -
            (labels[index - 1].left + labels[index - 1].width);
        if (gap < 10) {
          fits = false;
          break;
        }
      }

      if (fits) return labels;
    }

    return const [];
  }

  List<int> _xLabelIndices(int count, int desired) {
    if (count <= 1) return const [0];
    if (desired <= 1) return [(count - 1) ~/ 2];

    final indices = <int>{0, count - 1};
    for (var step = 1; step < desired - 1; step++) {
      indices.add(((count - 1) * step / (desired - 1)).round());
    }
    return indices.toList()..sort();
  }

  List<int> _axisTicks(int minValue, int maxValue) {
    if (minValue > 0) minValue = 0;
    if (maxValue < 0) maxValue = 0;

    if (minValue == maxValue) {
      if (minValue == 0) return const [-1, 0, 1];
      return minValue > 0 ? [0, minValue] : [minValue, 0];
    }

    for (var magnitude = 1; magnitude <= 1000000000; magnitude *= 10) {
      for (final multiplier in const [1, 2, 5]) {
        final step = magnitude * multiplier;
        final minTick = (minValue / step).floor() * step;
        final maxTick = (maxValue / step).ceil() * step;
        final count = (maxTick - minTick) ~/ step + 1;
        if (count <= 5) {
          return [
            for (var value = minTick; value <= maxTick; value += step) value,
          ];
        }
      }
    }

    return <int>{minValue, 0, maxValue}.toList()..sort();
  }

  String _formatAxisValue(int value) {
    final magnitude = value.abs();
    if (magnitude >= 1000000) {
      return '${_compact(value / 1000000)}M';
    }
    if (magnitude >= 1000) {
      return '${_compact(value / 1000)}K';
    }
    return '$value';
  }

  String _compact(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.05) return rounded.toInt().toString();
    return value.toStringAsFixed(1);
  }

  TextPainter _layoutText(String text) {
    return TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
  }

  double _textWidth(String text) {
    final painter = _layoutText(text);
    final width = painter.width;
    painter.dispose();
    return width;
  }

  double _textHeight(String text) {
    final painter = _layoutText(text);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  double _maxTextWidth(Iterable<String> texts) {
    var width = 0.0;
    for (final text in texts) {
      width = math.max(width, _textWidth(text));
    }
    return width;
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset anchor, {
    bool alignRight = false,
    bool centreVertically = false,
  }) {
    final painter = _layoutText(text);

    var dx = anchor.dx;
    if (alignRight) dx -= painter.width;
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
