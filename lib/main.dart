import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:peluna/config/router.dart';
import 'package:peluna/config/notifier.dart';
import 'package:peluna/config/hive/hive_adapters.dart';
import 'package:peluna/models/diary_model.dart';
import 'package:peluna/config/theme.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(DiaryAdapter());
  diariesBox = await Hive.openBox<Diary>('diaries');
  settingsBox = await Hive.openBox('settings');

  usePathUrlStrategy();

  runApp(const Peluna());
}

class Peluna extends StatelessWidget {
  const Peluna({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
    );
  }
}
