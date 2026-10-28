import 'dart:convert';

import 'package:peluna/data/diary_repository.dart';
import 'package:peluna/models/diary_model.dart';

/// Reads and writes diaries through the JSON backup format.
///
/// Kept free of Flutter and file-system concerns so it can be tested directly;
/// the UI layer is responsible for picking files and sharing the result.
class DiaryBackupService {
  DiaryBackupService(this._diaries);

  final DiaryRepository _diaries;

  bool get isEmpty => _diaries.isEmpty;

  /// All diaries as JSON maps, sorted by date ascending.
  List<Map<String, dynamic>> exportToJson() {
    final entries = _diaries.getAll().map((diary) => diary.toJson()).toList();
    entries.sort((a, b) {
      final dateA = a['date'] as String? ?? '';
      final dateB = b['date'] as String? ?? '';
      return dateA.compareTo(dateB);
    });
    return entries;
  }

  /// Parses a JSON backup and stores every entry, replacing by date.
  ///
  /// Returns the number of imported entries. Throws [FormatException] when the
  /// content is empty or holds no valid entries.
  Future<int> importFromJsonString(String jsonContent) async {
    if (jsonContent.trim().isEmpty) {
      throw const FormatException('File is empty.');
    }

    final parsed = _parse(jsonDecode(jsonContent));
    if (parsed.isEmpty) {
      throw const FormatException('No valid diary entries found.');
    }

    await _diaries.saveAll(parsed);
    return parsed.length;
  }

  List<Diary> _parse(dynamic decoded) {
    final diaries = <Diary>[];

    if (decoded is List) {
      for (final item in decoded) {
        if (item is Map) {
          diaries.add(Diary.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } else if (decoded is Map) {
      final nested = decoded['diaries'];
      if (nested is List) {
        for (final item in nested) {
          if (item is Map) {
            diaries.add(Diary.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      } else {
        diaries.add(Diary.fromJson(Map<String, dynamic>.from(decoded)));
      }
    }

    return diaries;
  }
}
