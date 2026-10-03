import 'package:peluna/config/notifier.dart';

final class HomeController {
  String selectedDateString = '';

  void updateCurrentDiary(String date) {
    currentDiaryNotifier.value = diariesBox.get(date);
  }
}
