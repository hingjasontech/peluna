import 'package:flutter/material.dart';

import 'package:peluna/analytics/mood_analytics.dart';
import 'package:peluna/views/widgets/analytics/analytics_format.dart';

class AnalyticsRangeTypeSelector extends StatelessWidget {
  const AnalyticsRangeTypeSelector({
    super.key,
    required this.type,
    required this.onChanged,
  });

  final AnalyticsRangeType type;
  final ValueChanged<AnalyticsRangeType> onChanged;

  @override
  Widget build(BuildContext context) {
    return _PillSelector<AnalyticsRangeType>(
      selected: type,
      onChanged: onChanged,
      options: const [
        (AnalyticsRangeType.lifetime, 'Lifetime'),
        (AnalyticsRangeType.week, 'Week'),
        (AnalyticsRangeType.month, 'Month'),
        (AnalyticsRangeType.year, 'Year'),
        (AnalyticsRangeType.custom, 'Custom'),
      ],
    );
  }
}

class AnalyticsRangeBar extends StatelessWidget {
  const AnalyticsRangeBar({
    super.key,
    required this.period,
    required this.today,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onPickCustom,
  });

  final AnalyticsPeriod period;
  final DateTime today;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onPickCustom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCustom = period.type == AnalyticsRangeType.custom;
    final includesToday = period.contains(today);

    return Row(
      children: [
        if (!isCustom)
          IconButton(
            tooltip: 'Previous period',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                analyticsPeriodLabel(period),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (period.isPartial) ...[
                const SizedBox(height: 2),
                Text(
                  'In progress',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!includesToday && !isCustom)
          IconButton(
            tooltip: 'Jump to today',
            onPressed: onToday,
            icon: const Icon(Icons.today_outlined),
          ),
        if (isCustom)
          IconButton(
            tooltip: 'Change date range',
            onPressed: onPickCustom,
            icon: const Icon(Icons.calendar_month_outlined),
          )
        else
          IconButton(
            tooltip: 'Next period',
            onPressed: canGoNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
      ],
    );
  }
}

class AnalyticsMetricToggle extends StatelessWidget {
  const AnalyticsMetricToggle({
    super.key,
    required this.metric,
    required this.onChanged,
  });

  final ScoreMetric metric;
  final ValueChanged<ScoreMetric> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MetricButton(
            label: 'Net',
            selected: metric == ScoreMetric.net,
            onTap: () => onChanged(ScoreMetric.net),
          ),
          _MetricButton(
            label: 'Average',
            selected: metric == ScoreMetric.average,
            onTap: () => onChanged(ScoreMetric.average),
          ),
        ],
      ),
    );
  }
}

class _MetricButton extends StatelessWidget {
  const _MetricButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PillSelector<T> extends StatelessWidget {
  const _PillSelector({
    required this.selected,
    required this.onChanged,
    required this.options,
  });

  final T selected;
  final ValueChanged<T> onChanged;
  final List<(T, String)> options;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _PillButton(
                label: option.$2,
                selected: selected == option.$1,
                onTap: () => onChanged(option.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
