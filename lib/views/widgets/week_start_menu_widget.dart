import 'package:flutter/material.dart';

import 'package:peluna/models/week_start.dart';

/// Dialog that lets the user pick the first day of the calendar week.
///
/// Pops the chosen [WeekStart], or `null` when cancelled.
class WeekStartMenuWidget extends StatefulWidget {
  const WeekStartMenuWidget({super.key, required this.selected});

  final WeekStart selected;

  @override
  State<WeekStartMenuWidget> createState() => _WeekStartMenuWidgetState();
}

class _WeekStartMenuWidgetState extends State<WeekStartMenuWidget> {
  late WeekStart _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start of Week'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: WeekStart.values.length,
          itemBuilder: (_, index) {
            final start = WeekStart.values[index];
            return RadioGroup<WeekStart>(
              groupValue: _selected,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selected = value);
                }
              },
              child: RadioListTile<WeekStart>(
                minVerticalPadding: 12,
                value: start,
                title: Text(start.label),
              ),
            );
          },
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
