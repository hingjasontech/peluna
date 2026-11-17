import 'package:flutter/material.dart';

import 'package:peluna/config/constant.dart';
import 'package:peluna/views/widgets/score_circle_widget.dart';

class ScoreMenuWidget extends StatefulWidget {
  const ScoreMenuWidget({super.key, this.selectedScore});

  final int? selectedScore;

  @override
  State<ScoreMenuWidget> createState() => _ScoreMenuWidgetState();
}

class _ScoreMenuWidgetState extends State<ScoreMenuWidget> {
  int? _selectedScore;

  @override
  void initState() {
    super.initState();
    _selectedScore = widget.selectedScore;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Score'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: Score.values.length,
          itemBuilder: (_, index) {
            return RadioGroup<int>(
              groupValue: _selectedScore,
              onChanged: (value) {
                setState(() {
                  _selectedScore = value;
                });
              },
              child: RadioListTile(
                minVerticalPadding: 12,
                value: Score.values[index],
                title: Row(
                  spacing: 8,
                  children: [
                    ScoreCircleWidget(index: index),
                    Text(Score.labels[index]),
                  ],
                ),
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
              onPressed: () => Navigator.of(context).pop(_selectedScore),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
