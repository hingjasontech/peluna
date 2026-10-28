/// The day the home calendar's week starts on, chosen in Settings.
///
/// Persisted by [name] rather than index, so adding or reordering values never
/// silently reinterprets an already-stored preference.
enum WeekStart {
  saturday('Saturday'),
  sunday('Sunday'),
  monday('Monday');

  const WeekStart(this.label);

  /// Human-readable name shown in the settings UI.
  final String label;

  /// Used when no preference has been stored yet.
  static const WeekStart fallback = WeekStart.monday;

  /// Resolves a persisted [name], falling back to [fallback] for unknown input.
  static WeekStart fromName(String? name) =>
      values.firstWhere((start) => start.name == name, orElse: () => fallback);
}
