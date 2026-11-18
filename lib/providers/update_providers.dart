import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/updates/update_checker.dart';
import 'package:peluna/updates/update_launcher.dart';

/// Update checks point at Android APK releases, so other targets only expose
/// the regular diary features.
final supportsAppUpdatesProvider = Provider<bool>(
  (ref) => !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
);

final updateCheckerProvider = Provider<UpdateChecker>((ref) {
  final checker = GitHubUpdateChecker();
  ref.onDispose(checker.close);
  return checker;
});

final updateLauncherProvider = Provider<UpdateLauncher>(
  (ref) => const UrlUpdateLauncher(),
);

class AutoCheckUpdatesNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).autoCheckUpdates;

  void setEnabled(bool value) {
    state = value;
    ref.read(settingsRepositoryProvider).setAutoCheckUpdates(value);
  }
}

final autoCheckUpdatesProvider =
    NotifierProvider<AutoCheckUpdatesNotifier, bool>(
      AutoCheckUpdatesNotifier.new,
    );
