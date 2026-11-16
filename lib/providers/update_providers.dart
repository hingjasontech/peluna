import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/updates/update_checker.dart';
import 'package:peluna/updates/update_downloader.dart';
import 'package:peluna/updates/update_installer.dart';

/// In-app self-updates use Android's package installer, so other targets only
/// expose the regular diary features.
final supportsSelfUpdateProvider = Provider<bool>(
  (ref) => !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
);

final updateCheckerProvider = Provider<UpdateChecker>((ref) {
  final checker = GitHubUpdateChecker();
  ref.onDispose(checker.close);
  return checker;
});

final updateDownloaderProvider = Provider<UpdateDownloader>(
  (ref) => UpdateDownloader(),
);

final updateInstallerProvider = Provider<UpdateInstaller>(
  (ref) => const UpdateInstaller(),
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
