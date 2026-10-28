import 'package:peluna/models/diary_model.dart';

/// In-progress state of a diary entry while it is being edited.
class DiaryDraft {
  const DiaryDraft({
    required this.date,
    this.content = '',
    this.mood,
    this.weather,
    this.tags = const <String>[],
  });

  /// Builds a draft from an existing [diary], or an empty one when it is null.
  factory DiaryDraft.fromDiary(DateTime date, Diary? diary) {
    if (diary == null) {
      return DiaryDraft(date: date);
    }
    return DiaryDraft(
      date: date,
      content: diary.content ?? '',
      mood: diary.mood,
      weather: diary.weather,
      tags: List<String>.from(diary.tags ?? const <String>[]),
    );
  }

  final DateTime date;
  final String content;
  final int? mood;
  final String? weather;
  final List<String> tags;

  DiaryDraft copyWith({
    String? content,
    int? mood,
    String? weather,
    List<String>? tags,
    bool clearMood = false,
    bool clearWeather = false,
  }) {
    return DiaryDraft(
      date: date,
      content: content ?? this.content,
      mood: clearMood ? null : mood ?? this.mood,
      weather: clearWeather ? null : weather ?? this.weather,
      tags: tags ?? this.tags,
    );
  }

  Diary toDiary() => Diary(date, content, mood, weather, tags);
}
