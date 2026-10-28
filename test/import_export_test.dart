import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:peluna/data/diary_backup_service.dart';
import 'package:peluna/models/diary_model.dart';
import 'package:peluna/utils/utils.dart';

import 'support/test_harness.dart';

void main() {
  late HiveTestHarness hive;
  late DiaryBackupService backup;

  setUpAll(() async {
    hive = await HiveTestHarness.create();
  });

  tearDownAll(() async {
    await hive.dispose();
  });

  setUp(() async {
    await hive.clear();
    backup = DiaryBackupService(hive.repository);
  });

  group('Diary.toJson / Diary.fromJson round-trip', () {
    test('serialises all fields correctly', () {
      final date = DateTime(2025, 6, 15, 10, 30);
      final diary = Diary(date, 'Had coffee', 2, 'Hot', ['work', 'morning']);

      final json = diary.toJson();
      expect(json['date'], date.toIso8601String());
      expect(json['content'], 'Had coffee');
      expect(json['mood'], 2);
      expect(json['weather'], 'Hot');
      expect(json['tags'], ['work', 'morning']);
    });

    test('deserialises ISO-8601 date string', () {
      final json = {
        'date': '2025-06-15T10:30:00.000',
        'content': 'Great day',
        'mood': 1,
        'weather': 'Balanced',
        'tags': ['exercise'],
      };

      final diary = Diary.fromJson(json);
      expect(diary.date.year, 2025);
      expect(diary.date.month, 6);
      expect(diary.date.day, 15);
      expect(diary.content, 'Great day');
      expect(diary.mood, 1);
      expect(diary.weather, 'Balanced');
      expect(diary.tags, ['exercise']);
    });

    test('deserialises epoch-millisecond date int', () {
      final epoch = DateTime(2024, 1, 1).millisecondsSinceEpoch;
      final json = {
        'date': epoch,
        'content': null,
        'mood': null,
        'weather': null,
        'tags': null,
      };

      final diary = Diary.fromJson(json);
      expect(diary.date.year, 2024);
      expect(diary.date.month, 1);
      expect(diary.date.day, 1);
    });

    test('throws FormatException when date is missing', () {
      expect(
        () => Diary.fromJson({'content': 'No date'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when date is not parseable', () {
      expect(
        () => Diary.fromJson({'date': 'not-a-date', 'content': 'No date'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('handles null optional fields', () {
      final json = {
        'date': '2025-03-10T00:00:00.000',
        'content': null,
        'mood': null,
        'weather': null,
        'tags': null,
      };

      final diary = Diary.fromJson(json);
      expect(diary.content, isNull);
      expect(diary.mood, isNull);
      expect(diary.weather, isNull);
      expect(diary.tags, isNull);
    });
  });

  group('exportToJson', () {
    test('returns empty list when box is empty', () {
      expect(backup.exportToJson(), isEmpty);
    });

    test('returns sorted list of diary maps', () {
      final d1 = DateTime(2025, 3, 1);
      final d2 = DateTime(2025, 1, 15);
      final d3 = DateTime(2025, 6, 20);

      hive.box.put('2025-03-01', Diary(d1, 'March', 0, null, null));
      hive.box.put('2025-01-15', Diary(d2, 'January', 1, null, null));
      hive.box.put('2025-06-20', Diary(d3, 'June', -1, null, null));

      final result = backup.exportToJson();
      expect(result.length, 3);
      expect(result[0]['content'], 'January');
      expect(result[1]['content'], 'March');
      expect(result[2]['content'], 'June');
    });
  });

  group('importFromJsonString', () {
    test('imports a list of diaries from JSON string', () async {
      final now = DateTime(2025, 5, 10);
      final json = jsonEncode([
        {
          'date': now.toIso8601String(),
          'content': 'Imported entry',
          'mood': 2,
          'weather': 'Hot',
          'tags': ['travel'],
        },
      ]);

      final count = await backup.importFromJsonString(json);
      expect(count, 1);

      final saved = hive.repository.getByDate(now);
      expect(saved, isNotNull);
      expect(saved!.content, 'Imported entry');
      expect(saved.mood, 2);
    });

    test('replaces existing diary with same date on import', () async {
      final date = DateTime(2025, 8, 20);

      hive.box.put('2025-08-20', Diary(date, 'Old content', -1, null, null));

      final json = jsonEncode([
        {
          'date': date.toIso8601String(),
          'content': 'New content',
          'mood': 1,
          'weather': 'Balanced',
          'tags': [],
        },
      ]);

      await backup.importFromJsonString(json);

      final updated = hive.repository.getByDate(date);
      expect(updated!.content, 'New content');
      expect(updated.mood, 1);
    });

    test('imports multiple entries from a single JSON string', () async {
      final dates = [
        DateTime(2025, 1, 1),
        DateTime(2025, 2, 1),
        DateTime(2025, 3, 1),
      ];

      final json = jsonEncode(
        dates
            .map(
              (d) => {
                'date': d.toIso8601String(),
                'content': 'Entry',
                'mood': 0,
                'weather': null,
                'tags': null,
              },
            )
            .toList(),
      );

      final count = await backup.importFromJsonString(json);
      expect(count, 3);
      expect(hive.box.length, 3);
    });

    test('throws FormatException for empty content', () async {
      await expectLater(
        backup.importFromJsonString('   '),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'throws FormatException when JSON is valid but has no diaries',
      () async {
        await expectLater(
          backup.importFromJsonString('[]'),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test(
      'refuses an entry without a date and keeps existing diaries',
      () async {
        final today = DateTime.now();
        await hive.box.put(
          dateToString(today),
          Diary(today, 'Original', 1, null, null),
        );

        await expectLater(
          backup.importFromJsonString(
            jsonEncode([
              {'content': 'Missing date must not become today'},
            ]),
          ),
          throwsA(isA<FormatException>()),
        );

        final saved = hive.repository.getByDate(today);
        expect(saved, isNotNull);
        expect(saved!.content, 'Original');
        expect(saved.mood, 1);
      },
    );

    test('writes nothing when any entry is invalid', () async {
      final valid = DateTime(2025, 4, 1);

      await expectLater(
        backup.importFromJsonString(
          jsonEncode([
            {'date': valid.toIso8601String(), 'content': 'Valid'},
            {'content': 'Missing date'},
          ]),
        ),
        throwsA(isA<FormatException>()),
      );

      expect(hive.box.isEmpty, isTrue);
    });

    test('round-trip: export then import preserves all data', () async {
      final d1 = DateTime(2025, 7, 4);
      final d2 = DateTime(2025, 12, 25);
      hive.box.put(
        '2025-07-04',
        Diary(d1, 'Independence Day', 2, 'Hot', ['holiday']),
      );
      hive.box.put(
        '2025-12-25',
        Diary(d2, 'Christmas', 2, 'Cold', ['holiday', 'family']),
      );

      final exportList = backup.exportToJson();
      final jsonStr = jsonEncode(exportList);

      await hive.box.clear();
      expect(hive.box.isEmpty, isTrue);

      final count = await backup.importFromJsonString(jsonStr);
      expect(count, 2);

      final imported1 = hive.repository.getByDate(d1);
      expect(imported1!.content, 'Independence Day');
      expect(imported1.mood, 2);
      expect(imported1.tags, ['holiday']);

      final imported2 = hive.repository.getByDate(d2);
      expect(imported2!.content, 'Christmas');
      expect(imported2.weather, 'Cold');
      expect(imported2.tags, ['holiday', 'family']);
    });
  });
}
