import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:peluna/models/diary_model.dart';
import 'package:peluna/views/pages/tags_page.dart';

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

  Future<void> pumpTags(
    WidgetTester tester, {
    List<String>? initialTags,
  }) async {
    await tester.pumpWidget(
      hive.wrap(MaterialApp(home: TagsPage(initialTags: initialTags))),
    );
    await tester.pumpAndSettle();
  }

  /// A host page that opens the tags editor and records what it returns.
  GoRouter buildTagsRouter(List<List<String>?> results) {
    return GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  results.add(
                    await context.pushNamed<List<String>>(
                      'tags',
                      extra: const ['existing'],
                    ),
                  );
                },
                child: const Text('open tags'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/tags',
          name: 'tags',
          builder: (context, state) =>
              TagsPage(initialTags: state.extra as List<String>?),
        ),
      ],
    );
  }

  Future<void> openTags(WidgetTester tester, GoRouter router) async {
    addTearDown(router.dispose);
    await tester.pumpWidget(
      hive.wrap(MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open tags'));
    await tester.pumpAndSettle();
  }

  Future<void> addTag(WidgetTester tester, String tag) async {
    await tester.enterText(find.byType(TextField), tag);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  Future<void> simulateSystemBack() {
    return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          'flutter/navigation',
          const JSONMessageCodec().encodeMessage(<String, dynamic>{
            'method': 'popRoute',
          }),
          (ByteData? _) {},
        );
  }

  testWidgets('suggests tags used by any diary in the app', (tester) async {
    await tester.runAsync(() async {
      await hive.put(
        DateTime(2026, 10, 1),
        Diary(DateTime(2026, 10, 1), 'one', null, null, ['work', 'travel']),
      );
      await hive.put(
        DateTime(2026, 10, 2),
        Diary(DateTime(2026, 10, 2), 'two', null, null, ['workout']),
      );
    });

    await pumpTags(tester);

    await tester.enterText(find.byType(TextField), 'wor');
    await tester.pumpAndSettle();

    // Suggestions come from all entries, prefix matches first.
    expect(find.text('work'), findsOneWidget);
    expect(find.text('workout'), findsOneWidget);

    await tester.tap(find.text('workout'));
    await tester.pumpAndSettle();

    expect(find.text('#workout'), findsOneWidget);
    // The field is cleared so another tag can be typed right away.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });

  testWidgets('does not suggest or add a tag twice', (tester) async {
    await tester.runAsync(() async {
      await hive.put(
        DateTime(2026, 10, 1),
        Diary(DateTime(2026, 10, 1), 'one', null, null, ['work']),
      );
    });

    await pumpTags(tester, initialTags: const ['work']);

    await tester.enterText(find.byType(TextField), 'wor');
    await tester.pumpAndSettle();

    // Already on this entry, so it is not offered as a suggestion.
    expect(find.text('work'), findsNothing);

    await tester.enterText(find.byType(TextField), 'WORK');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('#work'), findsOneWidget);
  });

  testWidgets('tag list is anchored at the bottom', (tester) async {
    await tester.runAsync(() async {
      await hive.put(
        DateTime(2026, 10, 1),
        Diary(DateTime(2026, 10, 1), 'one', null, null, ['first']),
      );
    });

    await pumpTags(tester, initialTags: const ['first', 'second']);

    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.reverse, isTrue);

    // The list is anchored at the bottom, so the most recently added tag sits
    // just above the input field.
    final second = tester.getTopLeft(find.text('#second'));
    final first = tester.getTopLeft(find.text('#first'));
    expect(second.dy, greaterThan(first.dy));
  });

  testWidgets('add button submits the typed tag', (tester) async {
    await pumpTags(tester, initialTags: const ['existing']);

    // Disabled until there is something to add.
    final addButton = find.widgetWithIcon(IconButton, Icons.add_circle);
    expect(tester.widget<IconButton>(addButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'typed');
    await tester.pump();

    await tester.tap(find.byTooltip('Add tag'));
    await tester.pumpAndSettle();

    expect(find.text('#typed'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });

  testWidgets('back arrow returns the tags without a save button', (
    tester,
  ) async {
    final results = <List<String>?>[];
    final router = buildTagsRouter(results);

    await openTags(tester, router);

    // The explicit save action is gone.
    expect(find.text('Save'), findsNothing);

    await addTag(tester, 'new');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('open tags'), findsOneWidget);
    expect(results.single, ['existing', 'new']);
  });

  testWidgets('system back returns the tags too', (tester) async {
    final results = <List<String>?>[];
    final router = buildTagsRouter(results);

    await openTags(tester, router);
    await addTag(tester, 'new');

    await simulateSystemBack();
    await tester.pumpAndSettle();

    expect(find.text('open tags'), findsOneWidget);
    expect(results.single, ['existing', 'new']);
  });
}
