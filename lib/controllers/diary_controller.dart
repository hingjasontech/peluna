import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:peluna/config/notifier.dart';
import 'package:peluna/models/diary_model.dart';
import 'package:peluna/utils/utils.dart';
import 'package:peluna/views/widgets/mood_menu_widget.dart';
import 'package:peluna/views/widgets/weather_menu_widget.dart';

class DiaryController extends ChangeNotifier {
  late final DateTime selectedDate;
  final TextEditingController contentController = TextEditingController();

  Diary? currentDiary;
  int? selectedMood;
  String? selectedWeather;
  List<String> tags = [];

  DiaryController() {
    _init();
  }

  void _init() {
    selectedDate = selectedDateTimeNotifier.value;
    currentDiary = currentDiaryNotifier.value;

    if (currentDiary != null) {
      selectedMood = currentDiary?.mood;
      selectedWeather = currentDiary?.weather;
      tags = List<String>.from(currentDiary?.tags ?? []);
      contentController.text = currentDiary?.content ?? '';
    }
  }

  String get dateString => dateToString(selectedDate);
  bool get isNewDiary => currentDiary == null;

  Future<void> showMoodMenu(BuildContext context) async {
    final selected = await showDialog<int?>(
      context: context,
      builder: (_) => MoodMenuWidget(selectedMood: selectedMood),
    );

    if (selected != null) {
      selectedMood = selected;
      notifyListeners();
    }
  }

  Future<void> showWeatherMenu(BuildContext context) async {
    final selected = await showDialog<String?>(
      context: context,
      builder: (_) => WeatherMenuWidget(selectedWeather: selectedWeather),
    );

    if (selected != null) {
      selectedWeather = selected;
      notifyListeners();
    }
  }

  Future<void> selectTags(BuildContext context) async {
    final result = await context.pushNamed<List<String>>('tags', extra: tags);

    if (result != null) {
      tags = result;
      notifyListeners();
    }
  }

  void saveDiary(BuildContext context) {
    final key = dateString;
    final diary = Diary(
      selectedDate,
      contentController.text,
      selectedMood,
      selectedWeather,
      tags,
    );

    // Save to database
    diariesBox.put(key, diary);

    // Update global state notifier
    currentDiaryNotifier.value = diariesBox.get(key);

    // Navigate back & show feedback
    context.pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved !')));
  }

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }
}
