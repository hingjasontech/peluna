import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/data/diary_backup_service.dart';
import 'package:peluna/data/diary_repository.dart';
import 'package:peluna/data/settings_repository.dart';

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
