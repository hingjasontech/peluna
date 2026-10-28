import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hive_ce_flutter/adapters.dart';

import 'package:peluna/app.dart';
import 'package:peluna/config/hive/hive_adapters.dart';
import 'package:peluna/data/diary_repository.dart';
import 'package:peluna/data/settings_repository.dart';
import 'package:peluna/models/diary_model.dart';
import 'package:peluna/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DiaryAdapter());

  final diariesBox = await Hive.openBox<Diary>('diaries');
  final settingsBox = await Hive.openBox('settings');

  usePathUrlStrategy();

  runApp(
    ProviderScope(
      overrides: [
        diaryRepositoryProvider.overrideWithValue(DiaryRepository(diariesBox)),
        settingsRepositoryProvider.overrideWithValue(
          SettingsRepository(settingsBox),
        ),
      ],
      child: const Peluna(),
    ),
  );
}
