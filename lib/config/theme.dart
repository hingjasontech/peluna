// Themes
import 'package:flutter/material.dart';

// Color
const Color _seedColor = Colors.indigo;

abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
    colorSchemeSeed: _seedColor,
  );

  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    colorSchemeSeed: _seedColor,
  );
}
