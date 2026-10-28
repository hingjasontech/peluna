import 'package:flutter_test/flutter_test.dart';

import 'package:peluna/models/diary_model.dart';

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

  test('clear removes every diary', () async {
    final date = DateTime(2025, 9, 1);
    await hive.repository.save(Diary(date, 'Entry', 1, 'Hot', ['tag']));

    await hive.repository.clear();

    expect(hive.repository.isEmpty, isTrue);
    expect(hive.repository.getByDate(date), isNull);
  });
}
