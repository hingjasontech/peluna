import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peluna/config/app_links.dart';
import 'package:peluna/data/settings_repository.dart';
import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/utils/external_link_launcher.dart';
import 'package:peluna/views/pages/settings_page.dart';
import 'package:peluna/views/widgets/about_settings_section.dart';

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

  testWidgets('source code tile opens the GitHub repository', (tester) async {
    final launcher = _FakeLinkLauncher();

    await tester.pumpWidget(
      hive.wrap(
        ProviderScope(
          overrides: [externalLinkLauncherProvider.overrideWithValue(launcher)],
          child: const MaterialApp(home: Scaffold(body: SettingsPage())),
        ),
      ),
    );
    await tester.pump();

    final tile = find.byKey(viewSourceCodeTileKey);
    expect(tile, findsOneWidget);
    expect(find.text('View source code'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(launcher.urls, [AppLinks.sourceCode]);
  });

  testWidgets('reports when the source code page cannot open', (tester) async {
    final launcher = _FakeLinkLauncher(opened: false);

    await tester.pumpWidget(
      hive.wrap(
        ProviderScope(
          overrides: [externalLinkLauncherProvider.overrideWithValue(launcher)],
          child: const MaterialApp(home: Scaffold(body: SettingsPage())),
        ),
      ),
    );
    await tester.pump();

    final tile = find.byKey(viewSourceCodeTileKey);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not open GitHub'), findsOneWidget);
  });
}

class _FakeLinkLauncher implements ExternalLinkLauncher {
  _FakeLinkLauncher({this.opened = true});

  final bool opened;
  final List<Uri> urls = [];

  @override
  Future<bool> open(Uri uri) async {
    urls.add(uri);
    return opened;
  }
}
