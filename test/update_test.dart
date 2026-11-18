import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:peluna/app.dart';
import 'package:peluna/data/settings_repository.dart';
import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/providers/update_providers.dart';
import 'package:peluna/updates/update_checker.dart';
import 'package:peluna/updates/update_launcher.dart';
import 'package:peluna/updates/update_models.dart';
import 'package:peluna/views/pages/settings_page.dart';
import 'package:peluna/views/widgets/update_dialog.dart';
import 'package:peluna/views/widgets/update_settings_section.dart';

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

  group('AppVersion', () {
    test('parses tags and partial versions', () {
      final version = AppVersion.parse('v1.2.3');

      expect(version.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
      expect(version.prerelease, isNull);
      expect(version.toString(), '1.2.3');

      final partial = AppVersion.parse('1.4');
      expect(partial.major, 1);
      expect(partial.minor, 4);
      expect(partial.patch, 0);
    });

    test('keeps the Android build number separate from the tag', () {
      final version = AppVersion.parse('1.2.3+9', build: 9);

      expect(version.build, 9);
      expect(version.toString(), '1.2.3+9');
    });

    test('compares releases, prereleases and build numbers', () {
      expect(
        AppVersion.parse('1.3.0').isNewerThan(AppVersion.parse('1.2.9')),
        isTrue,
      );
      expect(
        AppVersion.parse('1.2.0').isNewerThan(AppVersion.parse('1.2.0-beta')),
        isTrue,
      );
      expect(
        AppVersion.parse('1.2.0-beta').isNewerThan(AppVersion.parse('1.2.0')),
        isFalse,
      );
      expect(
        AppVersion.parse(
          '1.2.0',
          build: 4,
        ).isNewerThan(AppVersion.parse('1.2.0', build: 3)),
        isTrue,
      );
      expect(
        AppVersion.parse(
          '1.2.0',
        ).isNewerThan(AppVersion.parse('1.2.0', build: 3)),
        isFalse,
      );
    });

    test('rejects malformed versions', () {
      expect(AppVersion.tryParse('not-a-version'), isNull);
      expect(AppVersion.tryParse('1.2.3.4'), isNull);
      expect(AppVersion.tryParse(null), isNull);
    });
  });

  group('GitHubUpdateChecker', () {
    test('returns the newer release and its GitHub page', () async {
      final checker = GitHubUpdateChecker(
        client: MockClient((request) async {
          expect(
            request.url,
            Uri.https(
              'api.github.com',
              '/repos/hingjasontech/peluna/releases/latest',
            ),
          );
          return http.Response(jsonEncode(_releaseJson()), 200);
        }),
        installedVersion: () async => AppVersion.parse('1.1.0', build: 3),
      );
      addTearDown(checker.close);

      final update = await checker.checkForUpdate();

      expect(update, isNotNull);
      expect(update!.versionLabel, '1.2.0');
      expect(update.releaseNotes, 'Notes for 1.2.0');
      expect(
        update.releasePage.toString(),
        'https://github.com/hingjasontech/peluna/releases/tag/v1.2.0',
      );
    });

    test('returns null for the same or an older release', () async {
      Future<AppUpdate?> check(String tag) {
        final checker = GitHubUpdateChecker(
          client: MockClient(
            (_) async => http.Response(jsonEncode(_releaseJson(tag: tag)), 200),
          ),
          installedVersion: () async => AppVersion.parse('1.1.0', build: 3),
        );
        addTearDown(checker.close);
        return checker.checkForUpdate();
      }

      expect(await check('v1.1.0'), isNull);
      expect(await check('v1.0.1'), isNull);
    });

    test('reports GitHub errors with a readable message', () async {
      final checker = GitHubUpdateChecker(
        client: MockClient(
          (_) async => http.Response('{"message":"Not Found"}', 404),
        ),
        installedVersion: () async => AppVersion.parse('1.1.0'),
      );
      addTearDown(checker.close);

      await expectLater(
        checker.checkForUpdate(),
        throwsA(
          isA<UpdateException>().having(
            (error) => error.message,
            'message',
            contains('No releases'),
          ),
        ),
      );
    });

    test('falls back to the tag page when GitHub omits html_url', () async {
      final checker = GitHubUpdateChecker(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(_releaseJson(includeReleasePage: false)),
            200,
          ),
        ),
        installedVersion: () async => AppVersion.parse('1.1.0'),
      );
      addTearDown(checker.close);

      final update = await checker.checkForUpdate();

      expect(
        update!.releasePage.toString(),
        'https://github.com/hingjasontech/peluna/releases/tag/v1.2.0',
      );
    });

    test('rejects an insecure release page', () async {
      final checker = GitHubUpdateChecker(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(
              _releaseJson(
                releasePage:
                    'http://github.com/hingjasontech/peluna/releases/tag/'
                    'v1.2.0',
              ),
            ),
            200,
          ),
        ),
        installedVersion: () async => AppVersion.parse('1.1.0'),
      );
      addTearDown(checker.close);

      await expectLater(
        checker.checkForUpdate(),
        throwsA(isA<UpdateException>()),
      );
    });

    test('rejects a release with an invalid tag', () async {
      final checker = GitHubUpdateChecker(
        client: MockClient(
          (_) async =>
              http.Response(jsonEncode(_releaseJson(tag: 'latest')), 200),
        ),
        installedVersion: () async => AppVersion.parse('1.1.0'),
      );
      addTearDown(checker.close);

      await expectLater(
        checker.checkForUpdate(),
        throwsA(
          isA<UpdateException>().having(
            (error) => error.message,
            'message',
            contains('invalid version'),
          ),
        ),
      );
    });
  });

  group('auto-check setting', () {
    test('defaults to off and persists changes', () async {
      final repository = SettingsRepository(hive.settingsBox);

      expect(repository.autoCheckUpdates, isFalse);

      await repository.setAutoCheckUpdates(true);

      expect(repository.autoCheckUpdates, isTrue);
      expect(hive.settingsBox.get('auto_check_updates'), isTrue);
    });

    test('notifier writes through to the settings box', () {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            SettingsRepository(hive.settingsBox),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(autoCheckUpdatesProvider), isFalse);

      container.read(autoCheckUpdatesProvider.notifier).setEnabled(true);

      expect(container.read(autoCheckUpdatesProvider), isTrue);
      expect(hive.settingsBox.get('auto_check_updates'), isTrue);
    });
  });

  group('SettingsPage updater section', () {
    testWidgets('is hidden when app updates are unsupported', (tester) async {
      await tester.pumpWidget(_settingsPage(hive, supportsAppUpdates: false));
      await tester.pump();

      expect(find.text('Check for Updates'), findsNothing);
      expect(find.text('Check automatically on startup'), findsNothing);
    });

    testWidgets('checks manually and reports an up-to-date app', (
      tester,
    ) async {
      final checker = _FakeChecker(null);

      await tester.pumpWidget(_settingsPage(hive, checker: checker));
      await tester.pump();

      expect(find.text('Check for Updates'), findsOneWidget);
      expect(find.text('Check automatically on startup'), findsOneWidget);

      await tester.ensureVisible(find.text('Check for Updates'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check for Updates'));
      await tester.pumpAndSettle();

      expect(checker.calls, 1);
      expect(find.text('Peluna is up to date.'), findsOneWidget);
    });

    testWidgets('opens the update dialog for a newer release', (tester) async {
      final checker = _FakeChecker(_sampleUpdate());

      await tester.pumpWidget(_settingsPage(hive, checker: checker));
      await tester.pump();

      await tester.ensureVisible(find.text('Check for Updates'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check for Updates'));
      await tester.pumpAndSettle();

      expect(find.text('Update available'), findsOneWidget);
      expect(find.text('Peluna 1.2.0 is available.'), findsOneWidget);
      expect(find.text('Notes for 1.2.0'), findsOneWidget);

      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      expect(find.text('Update available'), findsNothing);
    });

    testWidgets('toggles and persists the startup check', (tester) async {
      await tester.pumpWidget(_settingsPage(hive));
      await tester.pump();

      final switchFinder = find.byKey(autoCheckUpdatesSwitchKey);
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isFalse);

      await tester.tap(switchFinder);
      await tester.pump();

      expect(
        tester.widget<Switch>(find.byKey(autoCheckUpdatesSwitchKey)).value,
        isTrue,
      );
      expect(hive.settingsBox.get('auto_check_updates'), isTrue);
    });
  });

  group('UpdateAvailableDialog', () {
    testWidgets('opens the GitHub release page in the browser', (tester) async {
      final launcher = _FakeLauncher(opened: true);

      await tester.pumpWidget(_dialogHost(hive, launcher: launcher));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get update'));
      await tester.pumpAndSettle();

      expect(launcher.urls, [_sampleUpdate().releasePage]);
      expect(find.text('Update available'), findsNothing);
    });

    testWidgets('reports when the browser cannot be opened', (tester) async {
      final launcher = _FakeLauncher(opened: false);

      await tester.pumpWidget(_dialogHost(hive, launcher: launcher));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get update'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Could not open the release page'),
        findsOneWidget,
      );
      expect(find.text('Update available'), findsOneWidget);

      launcher.opened = true;
      await tester.tap(find.text('Get update'));
      await tester.pumpAndSettle();

      expect(launcher.urls.length, 2);
      expect(find.text('Update available'), findsNothing);
    });
  });

  group('startup check', () {
    testWidgets('shows the update dialog when enabled', (tester) async {
      await SettingsRepository(hive.settingsBox).setAutoCheckUpdates(true);
      final checker = _FakeChecker(_sampleUpdate());

      await tester.pumpWidget(_app(hive, checker: checker));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(checker.calls, 1);
      expect(find.text('Update available'), findsOneWidget);

      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
    });
  });
}

Widget _settingsPage(
  HiveTestHarness hive, {
  bool supportsAppUpdates = true,
  UpdateChecker? checker,
}) {
  return ProviderScope(
    overrides: [
      diaryRepositoryProvider.overrideWithValue(hive.repository),
      settingsRepositoryProvider.overrideWithValue(
        SettingsRepository(hive.settingsBox),
      ),
      supportsAppUpdatesProvider.overrideWithValue(supportsAppUpdates),
      if (checker != null) updateCheckerProvider.overrideWithValue(checker),
    ],
    child: const MaterialApp(home: Scaffold(body: SettingsPage())),
  );
}

Widget _dialogHost(HiveTestHarness hive, {required UpdateLauncher launcher}) {
  return ProviderScope(
    overrides: [
      diaryRepositoryProvider.overrideWithValue(hive.repository),
      settingsRepositoryProvider.overrideWithValue(
        SettingsRepository(hive.settingsBox),
      ),
      updateLauncherProvider.overrideWithValue(launcher),
    ],
    child: MaterialApp(home: _DialogHost(update: _sampleUpdate())),
  );
}

Widget _app(HiveTestHarness hive, {required UpdateChecker checker}) {
  return ProviderScope(
    overrides: [
      diaryRepositoryProvider.overrideWithValue(hive.repository),
      settingsRepositoryProvider.overrideWithValue(
        SettingsRepository(hive.settingsBox),
      ),
      supportsAppUpdatesProvider.overrideWithValue(true),
      updateCheckerProvider.overrideWithValue(checker),
    ],
    child: const Peluna(),
  );
}

class _DialogHost extends StatelessWidget {
  const _DialogHost({required this.update});

  final AppUpdate update;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => showUpdateAvailableDialog(context, update),
          child: const Text('open'),
        ),
      ),
    );
  }
}

class _FakeChecker implements UpdateChecker {
  _FakeChecker(this.result);

  final AppUpdate? result;
  int calls = 0;

  @override
  Future<AppUpdate?> checkForUpdate() async {
    calls++;
    return result;
  }

  @override
  void close() {}
}

class _FakeLauncher implements UpdateLauncher {
  _FakeLauncher({required this.opened});

  bool opened;
  final List<Uri> urls = [];

  @override
  Future<bool> open(Uri uri) async {
    urls.add(uri);
    return opened;
  }
}

AppUpdate _sampleUpdate() {
  return AppUpdate(
    version: AppVersion.parse('1.2.0'),
    releaseNotes: 'Notes for 1.2.0',
    releasePage: Uri.parse(
      'https://github.com/hingjasontech/peluna/releases/tag/v1.2.0',
    ),
  );
}

Map<String, dynamic> _releaseJson({
  String tag = 'v1.2.0',
  bool includeReleasePage = true,
  String? releasePage,
}) {
  return {
    'tag_name': tag,
    'body': 'Notes for ${tag.replaceFirst('v', '')}',
    if (includeReleasePage)
      'html_url':
          releasePage ??
          'https://github.com/hingjasontech/peluna/releases/tag/$tag',
  };
}
