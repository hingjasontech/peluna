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

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(hive.wrap(const MaterialApp(home: HomePage())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> openDeleteMenu(WidgetTester tester, String content) async {
    await tester.longPress(find.text(content));
    await tester.pumpAndSettle();
  }

  testWidgets('long press deletes the selected diary after confirmation', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.runAsync(() async {
      await hive.put(now, Diary(now, 'delete me', null, null, null));
    });

    await pumpHome(tester);
    expect(find.text('delete me'), findsOneWidget);

    await openDeleteMenu(tester, 'delete me');
    expect(find.text('Delete this diary'), findsOneWidget);

    // Menu action only keeps the destructive color.
    final menuText = tester.widget<Text>(find.text('Delete this diary'));
    final error = Theme.of(
      tester.element(find.text('Delete this diary')),
    ).colorScheme.error;
    expect(menuText.style?.color, error);

    await tester.tap(find.text('Delete this diary'));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure?'), findsOneWidget);
    expect(find.text('This will delete this diary.'), findsOneWidget);

    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(hive.repository.getByDate(now), isNull);
    expect(find.text('delete me'), findsNothing);
    expect(find.text('Diary deleted.'), findsOneWidget);
  });

  testWidgets('cancelling the warning keeps the diary', (tester) async {
    final now = DateTime.now();
    await tester.runAsync(() async {
      await hive.put(now, Diary(now, 'keep me', null, null, null));
    });

    await pumpHome(tester);
    await openDeleteMenu(tester, 'keep me');

    await tester.tap(find.text('Delete this diary'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(hive.repository.getByDate(now), isNotNull);
    expect(find.text('keep me'), findsOneWidget);
  });
}
