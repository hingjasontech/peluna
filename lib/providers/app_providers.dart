import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/data/diary_backup_service.dart';
import 'package:peluna/data/diary_repository.dart';
import 'package:peluna/data/settings_repository.dart';
import 'package:peluna/utils/external_link_launcher.dart';

/// Returns the current time.
///
/// Widget tests and the landing-hero generator override this with a fixed
/// clock so screenshots do not depend on the machine's date.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Repository backed by the diaries Hive box.
///
/// Overridden in `main` (and in tests) with an instance bound to an opened box.
final diaryRepositoryProvider = Provider<DiaryRepository>(
  (ref) => throw UnimplementedError(
    'diaryRepositoryProvider must be overridden with an opened box',
  ),
);

/// Repository backed by the settings Hive box.
///
/// Overridden in `main` (and in tests) with an instance bound to an opened box.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError(
    'settingsRepositoryProvider must be overridden with an opened box',
  ),
);

/// Backup/restore helpers built on top of [diaryRepositoryProvider].
final diaryBackupServiceProvider = Provider<DiaryBackupService>(
  (ref) => DiaryBackupService(ref.watch(diaryRepositoryProvider)),
);

/// Opens links such as the GitHub repository in the platform browser.
final externalLinkLauncherProvider = Provider<ExternalLinkLauncher>(
  (ref) => const UrlExternalLinkLauncher(),
);
