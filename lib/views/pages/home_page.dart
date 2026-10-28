import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:peluna/config/constant.dart';
import 'package:peluna/models/diary_model.dart';
import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/providers/diary_providers.dart';
import 'package:peluna/providers/settings_providers.dart';
import 'package:peluna/utils/utils.dart';
import 'package:peluna/views/widgets/diary_card_widget.dart';
import 'package:peluna/views/widgets/score_circle_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = ref.read(selectedDateProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final showMood = ref.watch(showCalendarMoodProvider);
    final weekStart = ref.watch(weekStartProvider);
    final diaries = ref.watch(diaryRepositoryProvider);

    // Refresh the calendar whenever a diary is added, edited or removed.
    ref.watch(diaryRevisionProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goNamed('diary'),
        child: const Icon(Icons.edit),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Calendar
            TableCalendar<Diary>(
              firstDay: DateTime.utc(DateTime.now().year - 50, 1, 1),
              lastDay: DateTime.utc(DateTime.now().year + 50, 12, 31),
              focusedDay: _focusedDay,
              currentDay: DateTime.now(),
              availableGestures: AvailableGestures.horizontalSwipe,
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              startingDayOfWeek: StartingDayOfWeek.values.byName(
                weekStart.name,
              ),
              selectedDayPredicate: (day) => isSameDay(selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
                ref.read(selectedDateProvider.notifier).select(selectedDay);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle:
                    theme.textTheme.titleMedium ??
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: theme.colorScheme.onSurface,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                weekendStyle: TextStyle(
                  color: theme.colorScheme.error.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: true,
                isTodayHighlighted: true,
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
                defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                weekendTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                outsideTextStyle: TextStyle(color: theme.disabledColor),
              ),
              calendarBuilders: CalendarBuilders(
                prioritizedBuilder: (context, day, focusedDay) {
                  if (!showMood) {
                    return null;
                  }

                  final diary = diaries.getByDate(day);
                  if (diary == null || diary.mood == null) {
                    return null;
                  }

                  final moodIndex = Mood.getIndex(diary.mood!);
                  if (moodIndex < 0 || moodIndex >= Mood.moodInt.length) {
                    return null;
                  }

                  final isSelected = isSameDay(selectedDate, day);
                  final isToday = isSameDay(DateTime.now(), day);
                  final isOutside = day.month != focusedDay.month;

                  Widget scoreCircle = ScoreCircleWidget(
                    index: moodIndex,
                    size: 32,
                  );

                  if (isOutside) {
                    scoreCircle = Opacity(opacity: 0.35, child: scoreCircle);
                  }

                  final moodName = Mood.moodString[moodIndex];
                  final scoreVal = Mood.moodInt[moodIndex];
                  final scoreLabel = scoreVal > 0 ? '+$scoreVal' : '$scoreVal';
                  final tooltipMessage =
                      '${dateToString(day)}: $moodName ($scoreLabel)';

                  if (isSelected) {
                    return Center(
                      child: Tooltip(
                        message: tooltipMessage,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2.5,
                            ),
                          ),
                          child: scoreCircle,
                        ),
                      ),
                    );
                  }

                  if (isToday) {
                    return Center(
                      child: Tooltip(
                        message: tooltipMessage,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.6,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: scoreCircle,
                        ),
                      ),
                    );
                  }

                  return Center(
                    child: Tooltip(message: tooltipMessage, child: scoreCircle),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // the diary card
            const DiaryCardWidget(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
