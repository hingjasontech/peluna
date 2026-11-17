import 'package:hive_ce/hive.dart';

import 'package:peluna/models/week_start.dart';

/// Persisted, lightweight user preferences.
class SettingsRepository {
  SettingsRepository(this._box);

  final Box _box;

  static const String _showCalendarScoreKey = 'show_calendar_score';
  static const String _legacyShowCalendarMoodKey = 'show_calendar_mood';
  static const String _weekStartKey = 'week_start';
  static const String _autoCheckUpdatesKey = 'auto_check_updates';

  /// Defaults to true and falls back to the legacy `show_calendar_mood` key
  /// so existing installs keep their calendar preference after the rename.
  bool get showCalendarScore {
    final value =
        _box.get(_showCalendarScoreKey) ?? _box.get(_legacyShowCalendarMoodKey);
    return value as bool? ?? true;
  }

  Future<void> setShowCalendarScore(bool value) =>
      _box.put(_showCalendarScoreKey, value);

  /// The day the calendar week starts on, defaulting to [WeekStart.fallback].
  WeekStart get weekStart =>
      WeekStart.fromName(_box.get(_weekStartKey) as String?);

  Future<void> setWeekStart(WeekStart value) =>
      _box.put(_weekStartKey, value.name);

  /// Whether the app should look for a newer GitHub release when it starts.
  bool get autoCheckUpdates =>
      _box.get(_autoCheckUpdatesKey, defaultValue: false) as bool;

  Future<void> setAutoCheckUpdates(bool value) =>
      _box.put(_autoCheckUpdatesKey, value);
}
