import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import 'package:peluna/config/hive/hive_adapters.dart';
import 'package:peluna/data/diary_repository.dart';
import 'package:peluna/data/settings_repository.dart';
import 'package:peluna/models/diary_model.dart';
import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/utils/utils.dart';

/// In-memory Hive boxes wired into the app's providers.
///
/// Memory-backed boxes keep widget tests off disk. A real file write started
/// inside a widget test's fake-async zone never resolves, which used to hang
/// `tearDownAll` the moment the box was closed.
class HiveTestHarness {
  HiveTestHarness._(this.box, this.settingsBox);

  final Box<Diary> box;
  final Box settingsBox;

  DiaryRepository get repository => DiaryRepository(box);

  /// Wraps [child] in a [ProviderScope] backed by the in-memory boxes.
  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        diaryRepositoryProvider.overrideWithValue(DiaryRepository(box)),
        settingsRepositoryProvider.overrideWithValue(
          SettingsRepository(settingsBox),
        ),
      ],
      child: child,
    );
  }

  static bool _adapterRegistered = false;

  static Future<HiveTestHarness> create() async {
    if (!_adapterRegistered) {
      Hive.registerAdapter(DiaryAdapter());
      _adapterRegistered = true;
    }

    final box = await Hive.openBox<Diary>('diaries', bytes: Uint8List(0));
    final settingsBox = await Hive.openBox('settings', bytes: Uint8List(0));
    return HiveTestHarness._(box, settingsBox);
  }

  Future<void> clear() async {
    await box.clear();
    await settingsBox.clear();
  }

  Future<void> put(DateTime date, Diary diary) =>
      box.put(dateToString(date), diary);

  Future<void> dispose() async {
    await box.close();
    await settingsBox.close();
  }
}
