import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/models/week_start.dart';
import 'package:peluna/providers/app_providers.dart';

/// Whether scores are shown on the home calendar.
///
/// Source of truth is [settingsRepositoryProvider]; the value is loaded once
/// and written back on change, so the UI never touches the settings box.
class ShowCalendarScoreNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).showCalendarScore;

  void toggle() => setVisible(!state);

  void setVisible(bool value) {
    state = value;
    ref.read(settingsRepositoryProvider).setShowCalendarScore(value);
  }
}

final showCalendarScoreProvider =
    NotifierProvider<ShowCalendarScoreNotifier, bool>(
      ShowCalendarScoreNotifier.new,
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
