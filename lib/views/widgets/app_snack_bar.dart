import 'package:flutter/material.dart';

/// The single snackbar style used across Peluna.
///
/// Show every message through [show] or [showWith] so the design and the
/// duration stay identical everywhere.
abstract final class AppSnackBar {
  static const Duration duration = Duration(seconds: 3);

  static SnackBar build(String message) {
    return SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  /// Shows [message] on the nearest scaffold messenger.
  static void show(BuildContext context, String message) {
    showWith(ScaffoldMessenger.of(context), message);
  }

  /// Shows [message] on an already captured messenger.
  ///
  /// Use this when the widget may be popped before the message appears, such
  /// as saving the diary or clearing all entries.
  static void showWith(ScaffoldMessengerState messenger, String message) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(build(message));
  }
}
