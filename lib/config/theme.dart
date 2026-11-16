// Themes
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    colorSchemeSeed: Colors.blueAccent,
    appBarTheme: const AppBarTheme(centerTitle: false),
  );

  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    colorSchemeSeed: Colors.blueAccent,
    appBarTheme: const AppBarTheme(centerTitle: false),
  );
}
