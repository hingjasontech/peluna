import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/providers/settings_providers.dart';

/// Eye button that toggles mood visibility on the calendar and persists it.
class MoodVisibilityToggle extends ConsumerWidget {
  const MoodVisibilityToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showMood = ref.watch(showCalendarMoodProvider);

    return IconButton(
      icon: Icon(showMood ? Icons.visibility : Icons.visibility_off),
      tooltip: showMood ? 'Hide mood' : 'Show mood',
      onPressed: () {
        final newVisibility = !showMood;
        ref.read(showCalendarMoodProvider.notifier).setVisible(newVisibility);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
              content: Text(newVisibility ? 'Show mood' : 'Hide mood'),
            ),
          );
      },
    );
  }
}
