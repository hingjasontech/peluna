import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/providers/settings_providers.dart';
import 'package:peluna/views/widgets/app_snack_bar.dart';

/// Eye button that toggles score visibility on the calendar and persists it.
class ScoreVisibilityToggle extends ConsumerWidget {
  const ScoreVisibilityToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showScore = ref.watch(showCalendarScoreProvider);

    return IconButton(
      icon: Icon(showScore ? Icons.visibility : Icons.visibility_off),
      tooltip: showScore ? 'Hide score' : 'Show score',
      onPressed: () {
        final newVisibility = !showScore;
        ref.read(showCalendarScoreProvider.notifier).setVisible(newVisibility);
        AppSnackBar.show(context, newVisibility ? 'Show score' : 'Hide score');
      },
    );
  }
}
