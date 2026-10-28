import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/models/week_start.dart';
import 'package:peluna/providers/app_providers.dart';

/// Whether mood scores are shown on the home calendar.
///
/// Source of truth is [settingsRepositoryProvider]; the value is loaded once
/// and written back on change, so the UI never touches the settings box.
class ShowCalendarMoodNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).showCalendarMood;

  void toggle() => setVisible(!state);

  void setVisible(bool value) {
    state = value;
    ref.read(settingsRepositoryProvider).setShowCalendarMood(value);
  }
}

final showCalendarMoodProvider =
    NotifierProvider<ShowCalendarMoodNotifier, bool>(
      ShowCalendarMoodNotifier.new,
    );

/// Which day the home calendar's week starts on.
///
/// Source of truth is [settingsRepositoryProvider]; the value is loaded once
/// and written back on change, so the UI never touches the settings box.
class WeekStartNotifier extends Notifier<WeekStart> {
  @override
  WeekStart build() => ref.read(settingsRepositoryProvider).weekStart;

  void select(WeekStart value) {
    state = value;
    ref.read(settingsRepositoryProvider).setWeekStart(value);
  }
}

final weekStartProvider = NotifierProvider<WeekStartNotifier, WeekStart>(
  WeekStartNotifier.new,
);
