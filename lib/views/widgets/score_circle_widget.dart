import 'package:flutter/material.dart';
import 'package:peluna/config/constant.dart';

class ScoreCircleWidget extends StatelessWidget {
  const ScoreCircleWidget({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Mood.moodColors[index],
      ),
      width: 28,
      height: 28,
      alignment: .center,

      // add a '+' prefix if > 0
      child: Text(
        Mood.moodInt[index] > 0
            ? '+${Mood.moodInt[index]}'
            : '${Mood.moodInt[index]}',
      ),
    );
  }
}
