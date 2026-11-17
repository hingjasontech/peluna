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

  testWidgets('score visibility reads the legacy settings key', (tester) async {
    await hive.settingsBox.put('show_calendar_mood', false);

    await tester.pumpWidget(
      hive.wrap(const MaterialApp(home: Scaffold(body: SettingsPage()))),
    );
    await tester.pump();

    expect(
      tester.widget<Switch>(find.byKey(showScoreOnCalendarSwitchKey)).value,
      isFalse,
    );
  });

  testWidgets('score visibility switch persists to settings', (tester) async {
    await tester.pumpWidget(
      hive.wrap(const MaterialApp(home: Scaffold(body: SettingsPage()))),
    );
    await tester.pump();

    final switchFinder = find.byKey(showScoreOnCalendarSwitchKey);
    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    await tester.tap(switchFinder);
    await tester.pump();

    expect(tester.widget<Switch>(switchFinder).value, isFalse);
    expect(SettingsRepository(hive.settingsBox).showCalendarScore, isFalse);

    // The whole row toggles the setting, not just the switch.
    await tester.tap(find.text('Show Scores on Calendar'));
    await tester.pump();

    expect(tester.widget<Switch>(switchFinder).value, isTrue);
    expect(SettingsRepository(hive.settingsBox).showCalendarScore, isTrue);
  });
}
