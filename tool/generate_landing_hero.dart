import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:peluna/app.dart';
import 'package:peluna/config/hive/hive_adapters.dart';
import 'package:peluna/data/diary_repository.dart';
import 'package:peluna/data/settings_repository.dart';
import 'package:peluna/models/diary_model.dart';
import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/utils/utils.dart';

/// Logical phone viewport used by the app and the README gallery.
const Size _screenSize = Size(390, 844);

/// Rendering at 2x keeps the hero sharp without making the PNG huge.
const double _pixelRatio = 2;

const String _outputDir = 'build/landing';

/// The landing hero is intentionally pinned to the week shown in the design
/// reference. The UI itself is still rendered from the current app widgets, so
/// a UI change updates the image; only the sample calendar data is fixed.
final DateTime _heroDay = DateTime(2026, 11, 17);

void main() {
  testWidgets('generates the landing hero and OG image', (tester) async {
    await tester.runAsync(_loadSdkFonts);

    final previousPlatform = debugDefaultTargetPlatformOverride;
    final previousDisableShadows = debugDisableShadows;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    // Widget tests paint shadows as solid black by default.
    debugDisableShadows = false;

    tester.view.physicalSize = _screenSize * _pixelRatio;
    tester.view.devicePixelRatio = _pixelRatio;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;

    Box<Diary>? diaryBox;
    Box? settingsBox;
    ui.Image? heroImage;
    ui.Image? ogImage;

    try {
      await tester.runAsync(() async {
        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(DiaryAdapter());
        }
        diaryBox = await Hive.openBox<Diary>('diaries', bytes: Uint8List(0));
        settingsBox = await Hive.openBox('settings', bytes: Uint8List(0));
        await _seedHeroData(diaryBox!);
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
            nowProvider.overrideWithValue(() => _heroDay),
          ],
          child: RepaintBoundary(key: captureKey, child: const Peluna()),
        ),
      );
      await tester.pumpAndSettle();

      heroImage = await tester.runAsync(() async {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        return boundary.toImage(pixelRatio: _pixelRatio);
      });
      if (heroImage == null) {
        throw StateError('Could not capture the home screen.');
      }

      ogImage = await tester.runAsync(() => _composeOgImage(heroImage!));
      if (ogImage == null) {
        throw StateError('Could not compose the OG image.');
      }

      await tester.runAsync(() async {
        final output = Directory(_outputDir);
        if (!output.existsSync()) {
          output.createSync(recursive: true);
        }

        final heroBytes = await _encodePng(heroImage!);
        final ogBytes = await _encodePng(ogImage!);

        await File('$_outputDir/home.png').writeAsBytes(heroBytes);
        await File('$_outputDir/og.png').writeAsBytes(ogBytes);

        final manifest = <String, Object?>{
          'appVersion': _readAppVersion(),
          'tag':
              Platform.environment['HERO_TAG'] ??
              Platform.environment['GITHUB_REF_NAME'] ??
              'local',
          'commit':
              Platform.environment['HERO_COMMIT'] ??
              Platform.environment['GITHUB_SHA'] ??
              'local',
          'generatedAt': DateTime.now().toUtc().toIso8601String(),
          'fixture': {
            'from': '2026-11-10',
            'to': '2026-11-17',
            'selected': '2026-11-17',
          },
          'viewport': {
            'width': _screenSize.width.toInt(),
            'height': _screenSize.height.toInt(),
            'pixelRatio': _pixelRatio,
          },
          'hero': {
            'file': 'home.png',
            'width': heroImage!.width,
            'height': heroImage.height,
            'sha256': sha256.convert(heroBytes).toString(),
          },
          'og': {
            'file': 'og.png',
            'width': ogImage!.width,
            'height': ogImage.height,
            'sha256': sha256.convert(ogBytes).toString(),
          },
        };

        await File('$_outputDir/manifest.json').writeAsString(
          '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
        );
      });
    } finally {
      heroImage?.dispose();
      ogImage?.dispose();

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

    expect(File('$_outputDir/home.png').existsSync(), isTrue);
    expect(File('$_outputDir/og.png').existsSync(), isTrue);
    expect(File('$_outputDir/manifest.json').existsSync(), isTrue);
  });
}

/// Seeds the exact pinned week: a mix of scores through Nov 17, with no entry
/// on Nov 15 (the calendar in the reference has a gap there).
Future<void> _seedHeroData(Box<Diary> box) async {
  final entries =
      <
        ({
          DateTime date,
          String text,
          int score,
          String weather,
          List<String> tags,
        })
      >[
        (
          date: DateTime(2026, 11, 10),
          text: 'Steady progress at work and a brisk evening walk.',
          score: 1,
          weather: 'Balanced',
          tags: ['work', 'walk'],
        ),
        (
          date: DateTime(2026, 11, 11),
          text: 'Felt completely burnt out today. Taking tomorrow slow.',
          score: -2,
          weather: 'Hot',
          tags: ['burnout', 'rest'],
        ),
        (
          date: DateTime(2026, 11, 12),
          text: 'Great gym session and cooked dinner from scratch.',
          score: 2,
          weather: 'Balanced',
          tags: ['workout', 'cooking'],
        ),
        (
          date: DateTime(2026, 11, 13),
          text: 'Long day of meetings. Ready for an early night.',
          score: -1,
          weather: 'Cold',
          tags: ['work', 'rest'],
        ),
        (
          date: DateTime(2026, 11, 14),
          text: 'Rainy afternoon spent reading by the window.',
          score: 0,
          weather: 'Cold',
          tags: ['reading', 'rain'],
        ),
        // Nov 15 is intentionally empty, matching the reference calendar.
        (
          date: DateTime(2026, 11, 16),
          text: 'Cleaned up the desk and sketched out weekend plans.',
          score: 1,
          weather: 'Balanced',
          tags: ['focus', 'flutter'],
        ),
        (
          date: DateTime(2026, 11, 17),
          text: 'why are you reading this?',
          score: 2,
          weather: 'Balanced',
          tags: ['peluna', 'journal', 'grateful'],
        ),
      ];

  for (final entry in entries) {
    await box.put(
      dateToString(entry.date),
      Diary(entry.date, entry.text, entry.score, entry.weather, entry.tags),
    );
  }
}

Future<ui.Image> _composeOgImage(ui.Image hero) async {
  const width = 1200.0;
  const height = 630.0;
  const phoneHeight = 550.0;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.drawRect(
    const Rect.fromLTWH(0, 0, width, height),
    Paint()..color = const Color(0xFF0B0B0F),
  );

  final phoneWidth = phoneHeight * hero.width / hero.height;
  final phoneRect = Rect.fromLTWH(
    width - phoneWidth - 100,
    (height - phoneHeight) / 2,
    phoneWidth,
    phoneHeight,
  );
  final phoneRRect = RRect.fromRectAndRadius(
    phoneRect,
    const Radius.circular(20),
  );

  canvas.drawRect(
    const Rect.fromLTWH(0, 0, width, height),
    Paint()
      ..shader = ui.Gradient.radial(phoneRect.center, 420, const [
        Color(0x333B82F6),
        Color(0x000B0B0F),
      ]),
  );

  canvas.drawShadow(
    Path()..addRRect(phoneRRect.shift(const Offset(0, 18))),
    const Color(0xAA000000),
    32,
    false,
  );

  canvas.save();
  canvas.clipRRect(phoneRRect);
  canvas.drawImageRect(
    hero,
    Rect.fromLTWH(0, 0, hero.width.toDouble(), hero.height.toDouble()),
    phoneRect,
    Paint(),
  );
  canvas.restore();

  canvas.drawRRect(
    phoneRRect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x33FFFFFF),
  );

  _drawText(
    canvas,
    'Peluna',
    const Offset(100, 150),
    72,
    FontWeight.w700,
    const Color(0xFFFAFAFA),
  );
  _drawText(
    canvas,
    'A local-only, score-based diary.',
    const Offset(100, 255),
    28,
    FontWeight.w400,
    const Color(0xFFA1A1AA),
  );

  canvas.drawRect(
    const Rect.fromLTWH(100, 330, 64, 4),
    Paint()..color = const Color(0xFF3B82F6),
  );

  _drawText(
    canvas,
    'Local-only by design',
    const Offset(100, 382),
    22,
    FontWeight.w600,
    const Color(0xFFE4E4E7),
  );
  _drawText(
    canvas,
    'No account. No cloud.',
    const Offset(100, 427),
    22,
    FontWeight.w600,
    const Color(0xFFE4E4E7),
  );
  _drawText(
    canvas,
    'Your entries stay on your device.',
    const Offset(100, 472),
    22,
    FontWeight.w600,
    const Color(0xFFE4E4E7),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(width.toInt(), height.toInt());
  picture.dispose();
  return image;
}

void _drawText(
  Canvas canvas,
  String text,
  Offset offset,
  double fontSize,
  FontWeight weight,
  Color color,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, offset);
  painter.dispose();
}

Future<Uint8List> _encodePng(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) {
    throw StateError('Could not encode the rendered image as PNG.');
  }
  return data.buffer.asUint8List();
}

String _readAppVersion() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*(.+)$',
    multiLine: true,
  ).firstMatch(pubspec);
  return match?.group(1)?.trim().replaceAll('"', '') ?? 'unknown';
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

  final files = fontsDir.listSync().whereType<File>().toList(growable: false);

  File? find(String name) {
    final lower = name.toLowerCase();
    for (final file in files) {
      if (file.uri.pathSegments.last.toLowerCase() == lower) return file;
    }
    return null;
  }

  final robotoFiles = [
    find('roboto-regular.ttf'),
    find('roboto-medium.ttf'),
    find('roboto-bold.ttf'),
    find('roboto-italic.ttf'),
  ].whereType<File>().toList();

  if (robotoFiles.isEmpty) {
    throw StateError(
      'No Roboto fonts found in ${fontsDir.path}. '
      'Found ${files.length} files instead.',
    );
  }

  final roboto = FontLoader('Roboto');
  for (final file in robotoFiles) {
    final bytes = await file.readAsBytes();
    roboto.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await roboto.load();

  final iconFile = find('materialicons-regular.otf');
  if (iconFile == null) {
    throw StateError('Material Icons font not found in ${fontsDir.path}.');
  }

  final icons = FontLoader('MaterialIcons');
  final bytes = await iconFile.readAsBytes();
  icons.addFont(Future.value(ByteData.sublistView(bytes)));
  await icons.load();
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
