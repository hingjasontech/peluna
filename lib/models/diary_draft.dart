import 'package:peluna/models/diary_model.dart';

/// In-progress state of a diary entry while it is being edited.
class DiaryDraft {
  const DiaryDraft({
    required this.date,
    this.content = '',
    this.score,
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
      score: diary.score,
      weather: diary.weather,
      tags: List<String>.from(diary.tags ?? const <String>[]),
    );
  }

  final DateTime date;
  final String content;
  final int? score;
  final String? weather;
  final List<String> tags;

  DiaryDraft copyWith({
    String? content,
    int? score,
    String? weather,
    List<String>? tags,
    bool clearScore = false,
    bool clearWeather = false,
  }) {
    return DiaryDraft(
      date: date,
      content: content ?? this.content,
      score: clearScore ? null : score ?? this.score,
      weather: clearWeather ? null : weather ?? this.weather,
      tags: tags ?? this.tags,
    );
  }

  Diary toDiary() => Diary(date, content, score, weather, tags);
}
