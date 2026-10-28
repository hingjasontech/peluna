import 'package:flutter/material.dart';
import 'package:peluna/config/constant.dart';

class ScoreCircleWidget extends StatelessWidget {
  const ScoreCircleWidget({
    super.key,
    required this.index,
    this.size = 28,
    this.textStyle,
  });

  final int index;
  final double size;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    if (index < 0 || index >= Mood.moodInt.length) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Mood.moodColors[index],
      ),
      width: size,
      height: size,
      alignment: Alignment.center,

      // add a '+' prefix if > 0
      child: Text(
        Mood.moodInt[index] > 0
            ? '+${Mood.moodInt[index]}'
            : '${Mood.moodInt[index]}',
        style: textStyle ??
            TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.44,
            ),
      ),
    );
  }
}
