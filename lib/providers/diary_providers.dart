import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/models/diary_draft.dart';
import 'package:peluna/models/diary_model.dart';
import 'package:peluna/providers/app_providers.dart';

/// The day currently selected on the home calendar.
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void select(DateTime day) => state = day;
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

/// A counter that ticks on every change to the diary box.
///
/// Providers that must react to box changes watch this. It counts up (1, 2, 3...)
/// instead of exposing the change itself, because Riverpod skips notifying
/// listeners when the new state equals the previous one. A `StreamProvider<void>`
/// emits `AsyncData(null)` every time, and `AsyncData(null) == AsyncData(null)`,
/// so only the first change would ever refresh its dependents. A distinct value
/// per change guarantees every dependent rebuilds.
class DiaryRevisionNotifier extends Notifier<int> {
  @override
  int build() {
    final subscription = ref
        .watch(diaryRepositoryProvider)
        .changes
        .listen((_) => state++);
    ref.onDispose(subscription.cancel);
    return 0;
  }
}

final diaryRevisionProvider = NotifierProvider<DiaryRevisionNotifier, int>(
  DiaryRevisionNotifier.new,
);

/// The saved diary for [selectedDateProvider], or null when there is none.
///
/// Derived, never stored: it recomputes from the date and the box, so imports,
/// deletions and edits can never leave it stale.
final selectedDiaryProvider = Provider<Diary?>((ref) {
  final date = ref.watch(selectedDateProvider);
  ref.watch(diaryRevisionProvider);
  return ref.watch(diaryRepositoryProvider).getByDate(date);
});

/// Every distinct tag used by any saved diary, sorted for display.
///
/// Watches [diaryRevisionProvider] so the list refreshes as soon as an entry is
/// saved, deleted or imported. This is what lets the tag editor suggest tags
/// from the entire app, not just the entry currently being edited.
final allTagsProvider = Provider<List<String>>((ref) {
  ref.watch(diaryRevisionProvider);

  // Keyed by lowercase so "Work" and "work" are one suggestion; the first
  // spelling encountered is the one shown.
  final tags = <String, String>{};
  for (final diary in ref.watch(diaryRepositoryProvider).getAll()) {
    for (final tag in diary.tags ?? const <String>[]) {
      final trimmed = tag.trim();
      if (trimmed.isEmpty) continue;
      tags.putIfAbsent(trimmed.toLowerCase(), () => trimmed);
    }
  }

  final sorted = tags.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return List.unmodifiable(sorted);
});

/// Editable state for the diary of a specific day.
class DiaryEditorNotifier extends Notifier<DiaryDraft> {
  DiaryEditorNotifier(this.date);

  final DateTime date;

  @override
  DiaryDraft build() {
    final existing = ref.read(diaryRepositoryProvider).getByDate(date);
    return DiaryDraft.fromDiary(date, existing);
  }

  void setContent(String value) => state = state.copyWith(content: value);

  void setMood(int? mood) =>
      state = state.copyWith(mood: mood, clearMood: mood == null);

  void setWeather(String? weather) =>
      state = state.copyWith(weather: weather, clearWeather: weather == null);

  void setTags(List<String> tags) =>
      state = state.copyWith(tags: List<String>.from(tags));

  Future<void> save() =>
      ref.read(diaryRepositoryProvider).save(state.toDiary());
}

final diaryEditorProvider =
    NotifierProvider.family<DiaryEditorNotifier, DiaryDraft, DateTime>(
      DiaryEditorNotifier.new,
      isAutoDispose: true,
    );
