import 'package:flutter/material.dart';

/// The five daily score values, with their labels, icons, and colors.
abstract final class Score {
  static const List<int> values = [2, 1, 0, -1, -2];
  static const List<String> labels = [
    'Awesome',
    'Good',
    'Neutral',
    'Bad',
    'Awful',
  ];
  static const List<IconData> icons = [
    Icons.sentiment_very_satisfied_outlined,
    Icons.sentiment_satisfied_outlined,
    Icons.sentiment_neutral_outlined,
    Icons.sentiment_dissatisfied_outlined,
    Icons.sentiment_very_dissatisfied_outlined,
  ];

  static List<Color> colors = [
    Colors.green[600]!,
    Colors.green[400]!,
    Colors.orange,
    Colors.red[400]!,
    Colors.red[600]!,
  ];

  /// Index of [score] in [values], or -1 when it is not a valid score.
  static int getIndex(int score) => values.indexOf(score);
}

// Weather
abstract final class Weather {
  static const List<String> weatherString = ['Hot', 'Balanced', 'Cold'];

  static const List weatherIcon = [Icons.sunny, Icons.cloud, Icons.ac_unit];

  static int getIndex(String weather) {
    return weatherString.indexOf(weather);
  }
}
