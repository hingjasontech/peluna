import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peluna/data/settings_repository.dart';
import 'package:peluna/views/pages/settings_page.dart';

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

  testWidgets('mood visibility switch persists to settings', (tester) async {
    await tester.pumpWidget(
      hive.wrap(const MaterialApp(home: Scaffold(body: SettingsPage()))),
    );
    await tester.pump();

    final switchFinder = find.byKey(showMoodOnCalendarSwitchKey);
    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    await tester.tap(switchFinder);
    await tester.pump();

    expect(tester.widget<Switch>(switchFinder).value, isFalse);
    expect(SettingsRepository(hive.settingsBox).showCalendarMood, isFalse);

    // The whole row toggles the setting, not just the switch.
    await tester.tap(find.text('Show Moods on Calendar'));
    await tester.pump();

    expect(tester.widget<Switch>(switchFinder).value, isTrue);
    expect(SettingsRepository(hive.settingsBox).showCalendarMood, isTrue);
  });
}
