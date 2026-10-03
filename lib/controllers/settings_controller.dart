import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peluna/config/notifier.dart';

abstract final class SettingsController {
  static void deleteAllDiaries(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('This will clear all your diaries.'),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                diariesBox.clear();
                currentDiaryNotifier.value = null;
                context.pop();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
