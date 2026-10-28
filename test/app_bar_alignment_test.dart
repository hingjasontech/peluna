import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peluna/config/theme.dart';
import 'package:peluna/views/pages/diary_page.dart';
import 'package:peluna/views/pages/tags_page.dart';
import 'package:peluna/views/widgets/app_bar_widget.dart';

import 'support/test_harness.dart';

void main() {
  late HiveTestHarness hive;

  setUpAll(() async {
    hive = await HiveTestHarness.create();
  });

  tearDownAll(() async {
    await hive.dispose();
  });

  test(
    'AppTheme has centerTitle set to false for both light and dark themes',
    () {
      expect(AppTheme.light.appBarTheme.centerTitle, isFalse);
      expect(AppTheme.dark.appBarTheme.centerTitle, isFalse);
    },
  );

  testWidgets('AppBarWidget has centerTitle set to false', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(appBar: AppBarWidget())),
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.centerTitle, isFalse);
  });

  testWidgets('DiaryPage AppBar has centerTitle set to false', (tester) async {
    await tester.pumpWidget(hive.wrap(const MaterialApp(home: DiaryPage())));

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.centerTitle, isFalse);
  });

  testWidgets('TagsPage AppBar has centerTitle set to false', (tester) async {
    await tester.pumpWidget(hive.wrap(const MaterialApp(home: TagsPage())));

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.centerTitle, isFalse);
  });
}
