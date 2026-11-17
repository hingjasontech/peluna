import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:peluna/analytics/mood_analytics.dart';
import 'package:peluna/views/widgets/analytics/analytics_format.dart';

/// A concrete choice from the date-range menu.
class AnalyticsRangeSelection {
  const AnalyticsRangeSelection(this.type, {this.year, this.month});

  final AnalyticsRangeType type;
  final int? year;
  final int? month;

  @override
  bool operator ==(Object other) {
    return other is AnalyticsRangeSelection &&
        other.type == type &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode => Object.hash(type, year, month);
}

class AnalyticsRangeDropdown extends StatelessWidget {
  const AnalyticsRangeDropdown({
    super.key,
    required this.type,
    required this.anchor,
    required this.today,
    required this.firstEntry,
    required this.period,
    required this.onSelected,
  });

  final AnalyticsRangeType type;
  final DateTime anchor;
  final DateTime today;
  final DateTime? firstEntry;
  final AnalyticsPeriod? period;
  final ValueChanged<AnalyticsRangeSelection> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final period = this.period;

    return PopupMenuButton<AnalyticsRangeSelection>(
      tooltip: 'Select date range',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: onSelected,
      itemBuilder: (context) => _menuItems(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 22,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DATE RANGE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    period == null
                        ? _labelFor(type, anchor)
                        : analyticsPeriodLabel(period),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (period != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _dateRangeLabel(period),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<AnalyticsRangeSelection>> _menuItems() {
    final currentYear = today.year;
    final firstYear = firstEntry?.year;
    final earliestYear = math.min(
      firstYear ?? currentYear - 1,
      currentYear - 1,
    );
    final recentMonths = [
      for (var offset = 0; offset < 3; offset++)
        DateTime(today.year, today.month - offset, 1),
    ];

    return [
      for (final (rangeType, label) in const [
        (AnalyticsRangeType.last7Days, 'Last 7 days'),
        (AnalyticsRangeType.last28Days, 'Last 28 days'),
        (AnalyticsRangeType.last90Days, 'Last 90 days'),
        (AnalyticsRangeType.last365Days, 'Last 365 days'),
        (AnalyticsRangeType.lifetime, 'Lifetime'),
      ])
        PopupMenuItem(
          value: AnalyticsRangeSelection(rangeType),
          child: _MenuLabel(label: label, selected: type == rangeType),
        ),
      const PopupMenuDivider(),
      for (var year = currentYear; year >= earliestYear; year--)
        PopupMenuItem(
          value: AnalyticsRangeSelection(AnalyticsRangeType.year, year: year),
          child: _MenuLabel(
            label: '$year',
            selected: type == AnalyticsRangeType.year && anchor.year == year,
          ),
        ),
      const PopupMenuDivider(),
      for (final month in recentMonths)
        PopupMenuItem(
          value: AnalyticsRangeSelection(
            AnalyticsRangeType.month,
            year: month.year,
            month: month.month,
          ),
          child: _MenuLabel(
            label: month.year == currentYear
                ? monthLong(month)
                : '${monthLong(month)} ${month.year}',
            selected:
                type == AnalyticsRangeType.month &&
                anchor.year == month.year &&
                anchor.month == month.month,
          ),
        ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: const AnalyticsRangeSelection(AnalyticsRangeType.custom),
        child: _MenuLabel(
          label: 'Custom',
          selected: type == AnalyticsRangeType.custom,
        ),
      ),
    ];
  }

  String _labelFor(AnalyticsRangeType type, DateTime anchor) {
    return switch (type) {
      AnalyticsRangeType.last7Days => 'Last 7 days',
      AnalyticsRangeType.last28Days => 'Last 28 days',
      AnalyticsRangeType.last90Days => 'Last 90 days',
      AnalyticsRangeType.last365Days => 'Last 365 days',
      AnalyticsRangeType.lifetime => 'Lifetime',
      AnalyticsRangeType.year => '${anchor.year}',
      AnalyticsRangeType.month => '${monthLong(anchor)} ${anchor.year}',
      AnalyticsRangeType.custom => 'Custom',
    };
  }

  String _dateRangeLabel(AnalyticsPeriod period) {
    final end = period.effectiveEnd;
    if (period.start == end) return fullDate(period.start);
    if (period.start.year != end.year) {
      return '${fullDate(period.start)} – ${fullDate(end)}';
    }
    return '${shortDate(period.start)} – ${shortDate(end)}, ${end.year}';
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: selected ? colorScheme.primary : null,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        if (selected) ...[
          const SizedBox(width: 12),
          Icon(Icons.check, size: 18, color: colorScheme.primary),
        ],
      ],
    );
  }
}
