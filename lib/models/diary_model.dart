class Diary {
  final DateTime date;
  final String? content;
  final int? score;
  final String? weather;
  final List<String>? tags;

  const Diary(this.date, this.content, this.score, this.weather, this.tags);

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'content': content,
      'score': score,
      'weather': weather,
      'tags': tags,
    };
  }

  /// Throws [FormatException] when the entry has no parseable `date`.
  ///
  /// A missing date used to fall back to `DateTime.now()`, which silently
  /// mapped malformed backup entries onto today and overwrote that diary.
  factory Diary.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    final DateTime parsedDate;
    if (rawDate is num) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate.toInt());
    } else if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate);
    } else {
      throw const FormatException('Diary entry is missing a valid "date".');
    }

    // Backups exported before the Mood → Score rename used `mood`.
    final rawScore = json['score'] ?? json['mood'];

    return Diary(
      parsedDate,
      json['content'] as String?,
      (rawScore as num?)?.toInt(),
      json['weather'] as String?,
      (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }
}
