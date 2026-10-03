import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:peluna/config/constant.dart';
import 'package:peluna/views/widgets/score_circle_widget.dart';

class MoodMenuWidget extends StatefulWidget {
  const MoodMenuWidget({super.key, this.selectedMood});

  final int? selectedMood;

  @override
  State<MoodMenuWidget> createState() => _MoodMenuWidgetState();
}

class _MoodMenuWidgetState extends State<MoodMenuWidget> {
  int? _selectedMood;

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.selectedMood;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Mood'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: Mood.moodInt.length,
          itemBuilder: (_, index) {
            return RadioGroup<int>(
              groupValue: _selectedMood,
              onChanged: (value) {
                setState(() {
                  _selectedMood = value;
                });
              },
              child: RadioListTile(
                minVerticalPadding: 12,
                value: Mood.moodInt[index],
                title: Row(
                  spacing: 8,
                  children: [
                    ScoreCircleWidget(index: index),
                    Text(Mood.moodString[index]),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: .end,
          children: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => context.pop(_selectedMood),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
