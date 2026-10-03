class Diary {
  final DateTime date;
  final String? content;
  final int? mood;
  final String? weather;
  final List<String>? tags;

  const Diary(this.date, this.content, this.mood, this.weather, this.tags);
}
