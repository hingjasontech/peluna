import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peluna/models/diary_model.dart';
import 'package:peluna/views/pages/home_page.dart';

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

  testWidgets('home card reflects every change, not just the first', (
    tester,
  ) async {
    final now = DateTime.now();

    await tester.pumpWidget(hive.wrap(const MaterialApp(home: HomePage())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // First save: cold weather.
    await tester.runAsync(() async {
      await hive.put(now, Diary(now, 'entry', null, 'Cold', null));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.ac_unit), findsOneWidget);

    // Second save: hot weather. This used to keep showing the stale "cold"
    // icon, because the change stream emitted an equal AsyncData(null) each time.
    await tester.runAsync(() async {
      await hive.put(now, Diary(now, 'entry', null, 'Hot', null));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.sunny), findsOneWidget);
    expect(find.byIcon(Icons.ac_unit), findsNothing);
  });
}
