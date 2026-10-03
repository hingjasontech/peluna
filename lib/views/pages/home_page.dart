import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:peluna/config/notifier.dart';
import 'package:peluna/controllers/home_controller.dart';
import 'package:peluna/utils/utils.dart';
import 'package:peluna/views/widgets/diary_card_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final controller = HomeController();

  @override
  void initState() {
    super.initState();
    controller.selectedDateString = dateToString(DateTime.now());
    controller.updateCurrentDiary(controller.selectedDateString);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedDateTimeNotifier,
      builder: (context, selectedDate, child) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () =>
                context.goNamed('diary', extra: currentDiaryNotifier.value),
            child: Icon(Icons.edit),
          ),
          body: Column(
            children: [
              // Calender picker
              CalendarDatePicker(
                initialDate: DateTime.now(),
                firstDate: DateTime(DateTime.now().year - 100),
                lastDate: DateTime(DateTime.now().year + 100),
                currentDate: selectedDate,
                onDateChanged: (value) {
                  selectedDateTimeNotifier.value = value;
                  controller.selectedDateString = dateToString(value);
                  controller.updateCurrentDiary(controller.selectedDateString);
                },
              ),
              // the diary card
              DiaryCardWidget(),
            ],
          ),
        );
      },
    );
  }
}
