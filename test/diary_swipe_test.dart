import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peluna/data/settings_repository.dart';
import 'package:peluna/models/diary_model.dart';
import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/providers/diary_providers.dart';
import 'package:peluna/utils/utils.dart';
import 'package:peluna/views/pages/diary_page.dart';

import 'support/test_harness.dart';

void main() {
  late HiveTestHarness hive;

  setUpAll(() async {
    hive = await HiveTestHarness.create();
  });

  tearDownAll(() async {
    await hive.dispose();
  });

  setUp(() async {
    await hive.clear();
  });

  Future<void> pumpDiary(WidgetTester tester, DateTime date) async {
    final container = ProviderContainer(
      overrides: [
        diaryRepositoryProvider.overrideWithValue(hive.repository),
        settingsRepositoryProvider.overrideWithValue(
          SettingsRepository(hive.settingsBox),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(selectedDateProvider.notifier).select(date);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DiaryPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('swiping moves to the next and previous day', (tester) async {
    final today = DateTime(2026, 5, 20);
    final yesterday = DateTime(2026, 5, 19);
    final tomorrow = DateTime(2026, 5, 21);

    await tester.runAsync(() async {
      await hive.put(
        yesterday,
        Diary(yesterday, 'yesterday entry', null, null, null),
      );
      await hive.put(
        tomorrow,
        Diary(tomorrow, 'tomorrow entry', null, null, null),
      );
    });

    await pumpDiary(tester, today);
    expect(find.text(dateToString(today)), findsOneWidget);

    // Swipe left: next day.
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text(dateToString(tomorrow)), findsOneWidget);
    expect(find.text('tomorrow entry'), findsOneWidget);

    // Swipe right twice: back to today, then the previous day.
    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text(dateToString(today)), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text(dateToString(yesterday)), findsOneWidget);
    expect(find.text('yesterday entry'), findsOneWidget);

    // The day before yesterday has no diary, so another swipe stays put.
    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text(dateToString(yesterday)), findsOneWidget);
  });

  testWidgets('swiping stops at days without a diary', (tester) async {
    final today = DateTime(2026, 5, 20);
    final tomorrow = DateTime(2026, 5, 21);

    await tester.runAsync(() async {
      await hive.put(
        tomorrow,
        Diary(tomorrow, 'tomorrow entry', null, null, null),
      );
    });

    await pumpDiary(tester, today);

    // Tomorrow has a diary, so the swipe moves.
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text(dateToString(tomorrow)), findsOneWidget);

    // The day after tomorrow has no diary, so the swipe is blocked.
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text(dateToString(tomorrow)), findsOneWidget);

    // Today is the day the page was opened for, so it stays reachable even
    // though it has no diary yet.
    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text(dateToString(today)), findsOneWidget);

    // Yesterday has no diary, so the swipe is blocked.
    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text(dateToString(today)), findsOneWidget);
  });

  testWidgets('swiping away saves the day being left', (tester) async {
    final today = DateTime(2026, 5, 20);
    final tomorrow = DateTime(2026, 5, 21);

    await tester.runAsync(() async {
      await hive.put(
        tomorrow,
        Diary(tomorrow, 'tomorrow entry', null, null, null),
      );
    });

    await pumpDiary(tester, today);
    await tester.enterText(find.byType(TextField), 'typed today');

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(hive.repository.getByDate(today)?.content, 'typed today');
  });
}
