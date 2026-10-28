import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:peluna/models/diary_model.dart';
import 'package:peluna/views/pages/home_page.dart';
import 'package:peluna/views/widgets/score_circle_widget.dart';

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

  Widget buildHome() => hive.wrap(const MaterialApp(home: HomePage()));

  testWidgets('displays TableCalendar on HomePage', (tester) async {
    await tester.pumpWidget(buildHome());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TableCalendar<Diary>), findsOneWidget);
  });

  testWidgets('renders ScoreCircleWidget on dates with mood', (tester) async {
    final now = DateTime.now();

    await tester.runAsync(() async {
      await hive.put(now, Diary(now, 'Had a great day!', 2, 'Hot', ['happy']));
    });

    await tester.pumpWidget(buildHome());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TableCalendar<Diary>), findsOneWidget);
    expect(find.byType(ScoreCircleWidget), findsWidgets);
    expect(find.text('+2'), findsWidgets);
  });

  testWidgets(
    'dynamically updates calendar when diary entry with mood is added',
    (tester) async {
      final now = DateTime.now();

      await tester.pumpWidget(buildHome());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('-1'), findsNothing);

      await tester.runAsync(() async {
        await hive.put(now, Diary(now, 'Feeling bad today', -1, null, null));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('-1'), findsWidgets);
    },
  );
}
