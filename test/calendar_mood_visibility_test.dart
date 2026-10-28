import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peluna/models/diary_model.dart';
import 'package:peluna/views/pages/home_page.dart';
import 'package:peluna/views/widgets/app_bar_widget.dart';
import 'package:peluna/views/widgets/mood_visibility_toggle.dart';
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

  testWidgets(
    'clicking eye icon toggles mood score visibility and pops SnackBar notification',
    (tester) async {
      final now = DateTime.now();

      await tester.runAsync(() async {
        await hive.put(now, Diary(now, 'Mood entry', 2, 'Hot', ['test']));
      });

      await tester.pumpWidget(
        hive.wrap(
          const MaterialApp(
            home: Scaffold(
              appBar: AppBarWidget(actions: [MoodVisibilityToggle()]),
              body: HomePage(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initially showMood is true: eye icon is Icons.visibility, mood is shown
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byType(ScoreCircleWidget), findsWidgets);
      expect(find.text('+2'), findsWidgets);

      // Tap the eye icon to hide mood
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Notification snackbar shows "Hide mood"
      expect(find.text('Hide mood'), findsOneWidget);

      // Eye icon is now Icons.visibility_off, and mood is hidden in calendar
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.text('${now.day}'), findsWidgets);

      // Tap again to show mood
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Notification snackbar shows "Show mood"
      expect(find.text('Show mood'), findsOneWidget);

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.text('+2'), findsWidgets);
    },
  );
}
