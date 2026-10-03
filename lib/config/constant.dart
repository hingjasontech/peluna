import 'package:flutter/material.dart';

// Mood class object
abstract final class Mood {
  static const List<int> moodInt = [2, 1, 0, -1, -2];
  static const List<String> moodString = [
    'Awesome',
    'Good',
    'Neutral',
    'Bad',
    'Awful',
  ];
  static const List<IconData> moodIcon = [
    Icons.sentiment_very_satisfied_outlined,
    Icons.sentiment_satisfied_outlined,
    Icons.sentiment_neutral_outlined,
    Icons.sentiment_dissatisfied_outlined,
    Icons.sentiment_very_dissatisfied_outlined,
  ];

  static List<Color> moodColors = [
    Colors.green[600]!,
    Colors.green[400]!,
    Colors.orange,
    Colors.red[400]!,
    Colors.red[600]!,
  ];

  // helper function
  static int getIndex(int mood) {
    return moodInt.indexOf(mood);
  }
}

// Weather
abstract final class Weather {
  static const List<String> weatherString = ['Hot', 'Balanced', 'Cold'];

  static const List weatherIcon = [Icons.sunny, Icons.cloud, Icons.ac_unit];

  static int getIndex(String weather) {
    return weatherString.indexOf(weather);
  }
}
