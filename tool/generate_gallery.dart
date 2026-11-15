import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:peluna/app.dart';
import 'package:peluna/config/hive/hive_adapters.dart';
import 'package:peluna/config/router.dart';
import 'package:peluna/data/diary_repository.dart';
import 'package:peluna/data/settings_repository.dart';
import 'package:peluna/models/diary_model.dart';
import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/utils/utils.dart';

/// Logical size of the phone viewport each screenshot is rendered at.
const Size _screenSize = Size(390, 844);

/// Rendered at 1.5x so the gallery stays sharp on high-DPI screens.
const double _pixelRatio = 1.5;

const int _columns = 4;
const double _padding = 32;
const double _gap = 32;
const double _screenRadius = 20;
const Color _background = Color(0xFF0B0B0F);

void main() {
  testWidgets('generates the README gallery', (tester) async {
    await tester.runAsync(_loadSdkFonts);

    final previousPlatform = debugDefaultTargetPlatformOverride;
    final previousDisableShadows = debugDisableShadows;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    // Widget tests paint shadows as solid black by default, which leaves a
    // black halo around elevated widgets such as the FAB.
    debugDisableShadows = false;

    tester.view.physicalSize = _screenSize * _pixelRatio;
    tester.view.devicePixelRatio = _pixelRatio;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;

    Box<Diary>? diaryBox;
    Box? settingsBox;
    final screenshots = <ui.Image>[];

    try {
      await tester.runAsync(() async {
        Hive.registerAdapter(DiaryAdapter());
        diaryBox = await Hive.openBox<Diary>('diaries', bytes: Uint8List(0));
        settingsBox = await Hive.openBox('settings', bytes: Uint8List(0));
        await _seedSampleData(diaryBox!);
      });

      final captureKey = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            diaryRepositoryProvider.overrideWithValue(
              DiaryRepository(diaryBox!),
            ),
            settingsRepositoryProvider.overrideWithValue(
              SettingsRepository(settingsBox!),
            ),
          ],
          child: RepaintBoundary(key: captureKey, child: const Peluna()),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> snap() async {
        final image = await tester.runAsync(() async {
          final boundary =
              captureKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          return boundary.toImage(pixelRatio: _pixelRatio);
        });
        screenshots.add(image!);
      }

      // Home: calendar with moods and the selected day's diary card.
      await snap();

      // Home: mood circles hidden with the eye button.
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await snap();

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Diary editor for today.
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await snap();

      // Mood picker.
      await tester.tap(find.byIcon(Icons.mood));
      await tester.pumpAndSettle();
      await snap();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Weather picker.
      await tester.tap(find.byIcon(Icons.sunny));
      await tester.pumpAndSettle();
      await snap();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Tags editor.
      await tester.tap(find.byIcon(Icons.tag));
      await tester.pumpAndSettle();
      await snap();

      // Back to the diary, then home.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Settings.
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await snap();

      // Start of Week picker.
      await tester.tap(find.text('Start of Week'));
      await tester.pumpAndSettle();
      await snap();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      router.go('/');
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final gallery = await _composeGallery(screenshots);
        final byteData = await gallery.toByteData(
          format: ui.ImageByteFormat.png,
        );
        gallery.dispose();

        final outputDir = Directory('_gallery');
        if (!outputDir.existsSync()) {
          outputDir.createSync(recursive: true);
        }
        final outputFile = File('_gallery${Platform.pathSeparator}gallery.png');
        await outputFile.writeAsBytes(byteData!.buffer.asUint8List());
      });
    } finally {
      for (final screenshot in screenshots) {
        screenshot.dispose();
      }
      await tester.runAsync(() async {
        await diaryBox?.close();
        await settingsBox?.close();
      });
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      debugDisableShadows = previousDisableShadows;
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });
}

/// Seeds a seven-day diary streak ending today, with a believable mix of
/// moods, weather, tags and entries.
Future<void> _seedSampleData(Box<Diary> box) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  const samples =
      <({int mood, String weather, String text, List<String> tags})>[
        (
          mood: 2,
          weather: 'Hot',
          text: 'Morning coffee on the balcony before starting the day.',
          tags: ['morning', 'coffee'],
        ),
        (
          mood: 1,
          weather: 'Balanced',
          text: 'Steady progress at work and a brisk evening walk.',
          tags: ['work', 'walk'],
        ),
        (
          mood: 0,
          weather: 'Cold',
          text: 'Rainy afternoon spent reading by the window.',
          tags: ['reading', 'rain'],
        ),
        (
          mood: -1,
          weather: 'Cold',
          text: 'Long day of meetings. Ready for an early night.',
          tags: ['work', 'rest'],
        ),
        (
          mood: 2,
          weather: 'Balanced',
          text: 'Great gym session and cooked dinner from scratch.',
          tags: ['workout', 'cooking'],
        ),
        (
          mood: -2,
          weather: 'Hot',
          text: 'Felt completely burnt out today. Taking tomorrow slow.',
          tags: ['burnout', 'rest'],
        ),
        (
          mood: 1,
          weather: 'Balanced',
          text: 'Cleaned up the desk and sketched out weekend plans.',
          tags: ['focus', 'flutter'],
        ),
      ];

  // Consecutive days ending today, so the calendar reads as a streak instead
  // of scattered mood circles.
  const streakLength = 7;
  for (var offset = streakLength - 1; offset >= 0; offset--) {
    final date = DateTime(today.year, today.month, today.day - offset);
    final sample = samples[offset % samples.length];
    await box.put(
      dateToString(date),
      Diary(date, sample.text, sample.mood, sample.weather, sample.tags),
    );
  }

  await box.put(
    dateToString(today),
    Diary(today, 'why are you reading this?', 2, 'Balanced', [
      'peluna',
      'journal',
      'grateful',
    ]),
  );
}

/// Lays the screenshots out in a grid on a single background image.
Future<ui.Image> _composeGallery(List<ui.Image> screenshots) async {
  final screenWidth = screenshots.first.width;
  final screenHeight = screenshots.first.height;
  final rows = (screenshots.length / _columns).ceil();

  final width = (_padding * 2 + _columns * screenWidth + (_columns - 1) * _gap)
      .round();
  final height = (_padding * 2 + rows * screenHeight + (rows - 1) * _gap)
      .round();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = _background,
  );

  final borderPaint = Paint()
    ..color = const Color(0x33FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  for (var i = 0; i < screenshots.length; i++) {
    final column = i % _columns;
    final row = i ~/ _columns;
    final left = _padding + column * (screenWidth + _gap);
    final top = _padding + row * (screenHeight + _gap);
    final rect = Rect.fromLTWH(
      left,
      top,
      screenWidth.toDouble(),
      screenHeight.toDouble(),
    );
    final rounded = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(_screenRadius),
    );

    canvas.save();
    canvas.clipRRect(rounded);
    canvas.drawImage(screenshots[i], Offset(left, top), Paint());
    canvas.restore();
    canvas.drawRRect(rounded, borderPaint);
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  return image;
}

/// Loads Roboto and Material Icons from the Flutter SDK, because widget tests
/// otherwise paint every glyph as an empty box.
Future<void> _loadSdkFonts() async {
  final fontsDir = _findMaterialFontsDir();
  if (fontsDir == null) {
    throw StateError(
      'Could not locate the Flutter SDK material_fonts directory. Set '
      'FLUTTER_ROOT and try again (resolved executable: '
      '${Platform.resolvedExecutable}).',
    );
  }

  final roboto = FontLoader('Roboto');
  for (final name in const [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-italic.ttf',
  ]) {
    final file = File('${fontsDir.path}${Platform.pathSeparator}$name');
    if (file.existsSync()) {
      final bytes = await file.readAsBytes();
      roboto.addFont(Future.value(ByteData.sublistView(bytes)));
    }
  }
  await roboto.load();

  final iconFile = File(
    '${fontsDir.path}${Platform.pathSeparator}materialicons-regular.otf',
  );
  if (iconFile.existsSync()) {
    final icons = FontLoader('MaterialIcons');
    final bytes = await iconFile.readAsBytes();
    icons.addFont(Future.value(ByteData.sublistView(bytes)));
    await icons.load();
  }
}

Directory? _findMaterialFontsDir() {
  final separator = Platform.pathSeparator;
  final candidates = <Directory>[];

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    candidates.add(
      Directory(
        '$flutterRoot${separator}bin${separator}cache$separator'
        'artifacts${separator}material_fonts',
      ),
    );
  }

  // Walk up from the running dart/flutter_tester binary looking for the SDK's
  // artifacts directory.
  var current = File(Platform.resolvedExecutable).parent;
  for (var depth = 0; depth < 10; depth++) {
    for (final suffix in [
      'bin${separator}cache${separator}artifacts${separator}material_fonts',
      'cache${separator}artifacts${separator}material_fonts',
      'artifacts${separator}material_fonts',
      'material_fonts',
    ]) {
      candidates.add(Directory('${current.path}$separator$suffix'));
    }
    final parent = current.parent;
    if (parent.path == current.path) break;
    current = parent;
  }

  for (final directory in candidates) {
    if (directory.existsSync()) return directory;
  }
  return null;
}
