import 'package:hive_ce/hive.dart';

import 'package:peluna/models/week_start.dart';

/// Persisted, lightweight user preferences.
class SettingsRepository {
  SettingsRepository(this._box);

  final Box _box;

  static const String _showCalendarMoodKey = 'show_calendar_mood';
  static const String _weekStartKey = 'week_start';

  bool get showCalendarMood =>
      _box.get(_showCalendarMoodKey, defaultValue: true) as bool;

  Future<void> setShowCalendarMood(bool value) =>
      _box.put(_showCalendarMoodKey, value);

  /// The day the calendar week starts on, defaulting to [WeekStart.fallback].
  WeekStart get weekStart =>
      WeekStart.fromName(_box.get(_weekStartKey) as String?);

  Future<void> setWeekStart(WeekStart value) =>
      _box.put(_weekStartKey, value.name);
}
