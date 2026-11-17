import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:peluna/data/settings_repository.dart';
import 'package:peluna/models/diary_model.dart';
import 'package:peluna/models/week_start.dart';
import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/providers/settings_providers.dart';
import 'package:peluna/views/pages/home_page.dart';
import 'package:peluna/views/pages/settings_page.dart';
import 'package:peluna/views/widgets/settings_section.dart';

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

  group('WeekStart', () {
    test('falls back to Monday for unknown or missing names', () {
      expect(WeekStart.fromName(null), WeekStart.monday);
      expect(WeekStart.fromName('nonsense'), WeekStart.monday);
    });

    test('round-trips through its name', () {
      for (final start in WeekStart.values) {
        expect(WeekStart.fromName(start.name), start);
      }
    });
  });

  group('SettingsRepository.weekStart', () {
    test('defaults to Monday when nothing is stored', () {
      expect(SettingsRepository(hive.settingsBox).weekStart, WeekStart.monday);
    });

    test('persists the chosen value', () async {
      final repo = SettingsRepository(hive.settingsBox);

      await repo.setWeekStart(WeekStart.monday);

      expect(repo.weekStart, WeekStart.monday);
      expect(hive.settingsBox.get('week_start'), 'monday');
    });
  });

  group('weekStartProvider', () {
    test('select() updates state and writes through to the repository', () {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            SettingsRepository(hive.settingsBox),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(weekStartProvider), WeekStart.monday);

      container.read(weekStartProvider.notifier).select(WeekStart.saturday);

      expect(container.read(weekStartProvider), WeekStart.saturday);
      expect(
        SettingsRepository(hive.settingsBox).weekStart,
        WeekStart.saturday,
      );
    });
  });

  group('SettingsPage', () {
    testWidgets('choosing a week start updates the tile and persists it', (
      tester,
    ) async {
      await tester.pumpWidget(
        hive.wrap(const MaterialApp(home: Scaffold(body: SettingsPage()))),
      );
      await tester.pump();

      // Default choice is shown on the tile.
      expect(find.text('Monday'), findsOneWidget);

      await tester.tap(find.text('Start of Week'));
      await tester.pumpAndSettle();

      // All three options are offered.
      expect(find.text('Saturday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);
      // Monday appears both on the tile and in the open dialog.
      expect(find.text('Monday'), findsNWidgets(2));

      await tester.tap(find.widgetWithText(RadioListTile<WeekStart>, 'Sunday'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(hive.settingsBox.get('week_start'), 'sunday');
      expect(find.text('Week starts on Sunday'), findsOneWidget);
      expect(
        find.descendant(
          of: find.widgetWithText(SettingsTile, 'Start of Week'),
          matching: find.text('Sunday'),
        ),
        findsOneWidget,
      );
    });
  });

  group('HomePage calendar', () {
    testWidgets('defaults to a Monday start', (tester) async {
      await tester.pumpWidget(hive.wrap(const MaterialApp(home: HomePage())));
      await tester.pump();

      final calendar = tester.widget<TableCalendar<Diary>>(
        find.byType(TableCalendar<Diary>),
      );
      expect(calendar.startingDayOfWeek, StartingDayOfWeek.monday);
    });

    testWidgets('uses the stored week start', (tester) async {
      await SettingsRepository(hive.settingsBox).setWeekStart(WeekStart.monday);

      await tester.pumpWidget(hive.wrap(const MaterialApp(home: HomePage())));
      await tester.pump();

      final calendar = tester.widget<TableCalendar<Diary>>(
        find.byType(TableCalendar<Diary>),
      );
      expect(calendar.startingDayOfWeek, StartingDayOfWeek.monday);
    });
  });
}
