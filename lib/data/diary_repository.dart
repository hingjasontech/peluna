import 'package:hive_ce/hive.dart';

import 'package:peluna/models/diary_model.dart';
import 'package:peluna/utils/utils.dart';

/// Single source of truth for persisted [Diary] entries.
///
/// The only place that talks to the diaries Hive box. Everything else reads
/// from here (directly or through providers), so persistence stays in one layer.
class DiaryRepository {
  DiaryRepository(this._box);

  final Box<Diary> _box;

  Diary? getByDate(DateTime date) => _box.get(dateToString(date));

  List<Diary> getAll() => _box.values.toList();

  Future<void> save(Diary diary) => _box.put(dateToString(diary.date), diary);

  Future<void> delete(DateTime date) => _box.delete(dateToString(date));

  Future<void> saveAll(Iterable<Diary> diaries) {
    return _box.putAll({
      for (final diary in diaries) dateToString(diary.date): diary,
    });
  }

  /// Removes every diary, then compacts the box so old frames are dropped.
  ///
  /// Hive keeps overwritten and deleted values on disk until compaction; for a
  /// diary app that means "cleared" text could otherwise linger in the file.
  Future<void> clear() async {
    await _box.clear();
    await _box.compact();
  }

  bool get isEmpty => _box.isEmpty;

  /// Emits whenever a diary entry is added, updated or removed.
  Stream<void> get changes => _box.watch().map<void>((_) {});
}
