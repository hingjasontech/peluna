import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:peluna/models/week_start.dart';
import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/providers/settings_providers.dart';
import 'package:peluna/utils/utils.dart';
import 'package:peluna/views/widgets/list_tile_widget.dart';
import 'package:peluna/views/widgets/week_start_menu_widget.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(weekStartProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListView(
        children: [
          Column(
            spacing: 8,
            children: [
              ListTileWidget(
                title: const Text('Start of Week'),
                leading: const Icon(Icons.calendar_view_week_outlined),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(weekStart.label),
                    const SizedBox(width: 4),
                    const Icon(Icons.navigate_next_outlined),
                  ],
                ),
                onTap: () => _pickWeekStart(context, ref),
              ),
              ListTileWidget(
                title: const Text('Export Diaries'),
                leading: const Icon(Icons.file_upload_outlined),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _exportDiaries(context, ref),
              ),
              ListTileWidget(
                title: const Text('Import Diaries'),
                leading: const Icon(Icons.file_download_outlined),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _importDiaries(context, ref),
              ),
              ListTileWidget(
                title: Text(
                  'Clear All Diary',
                  style: TextStyle(color: colorScheme.error),
                ),
                leading: Icon(Icons.delete_outline, color: colorScheme.error),
                trailing: Icon(Icons.chevron_right, color: colorScheme.error),
                tileColor: colorScheme.error.withValues(alpha: 0.1),
                onTap: () => _clearAllDiaries(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}

Future<void> _pickWeekStart(BuildContext context, WidgetRef ref) async {
  final selected = await showDialog<WeekStart>(
    context: context,
    builder: (_) => WeekStartMenuWidget(selected: ref.read(weekStartProvider)),
  );

  if (selected == null) return;

  ref.read(weekStartProvider.notifier).select(selected);

  if (context.mounted) {
    _showSnack(context, 'Week starts on ${selected.label}');
  }
}

Future<void> _exportDiaries(BuildContext context, WidgetRef ref) async {
  final backup = ref.read(diaryBackupServiceProvider);

  if (backup.isEmpty) {
    _showSnack(context, 'No diaries to export.');
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Export Diaries'),
      content: const Text(
        'This backup is unencrypted plaintext — anyone with the file can read '
        'every entry.\n\n'
        'Only share it somewhere you trust.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Export'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    final exportList = backup.exportToJson();
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportList);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    final fileName = 'peluna_diaries_${dateToString(DateTime.now())}.json';

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes, mimeType: 'application/json', name: fileName),
          ],
          subject: 'Peluna Diaries Backup',
        ),
      );

      if (context.mounted && result.status != ShareResultStatus.dismissed) {
        _showSnack(context, 'Exported ${exportList.length} diaries.');
      }
    } else {
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Export Diaries',
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (uri != null && context.mounted) {
        _showSnack(context, 'Exported ${exportList.length} diaries.');
      }
    }
  } catch (e) {
    if (context.mounted) {
      _showSnack(context, 'Export failed: $e');
    }
  }
}

Future<void> _importDiaries(BuildContext context, WidgetRef ref) async {
  try {
    final pickedFile = await FilePicker.pickFile(
      dialogTitle: 'Import Diaries',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (pickedFile == null) {
      return;
    }

    final bytes = await pickedFile.readAsBytes();
    if (bytes.isEmpty) {
      if (context.mounted) {
        _showSnack(context, 'Selected file is empty.');
      }
      return;
    }

    final jsonContent = utf8.decode(bytes);
    final count = _countEntries(jsonDecode(jsonContent));

    if (count == 0) {
      if (context.mounted) {
        _showSnack(context, 'No valid diary entries found in file.');
      }
      return;
    }

    if (!context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import Diaries'),
        content: Text(
          'Found $count diary ${count == 1 ? 'entry' : 'entries'} in file.\n\n'
          'Existing entries for matching dates will be replaced. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final importedCount = await ref
        .read(diaryBackupServiceProvider)
        .importFromJsonString(jsonContent);

    if (context.mounted) {
      _showSnack(context, 'Successfully imported $importedCount diaries!');
    }
  } catch (e) {
    if (context.mounted) {
      _showSnack(context, 'Failed to import: $e');
    }
  }
}

void _clearAllDiaries(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Are you sure?'),
      content: const Text('This will clear all your diaries.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            Navigator.of(dialogContext).pop();
            await ref.read(diaryRepositoryProvider).clear();
            messenger
              ..clearSnackBars()
              ..showSnackBar(
                const SnackBar(
                  content: Text('All diaries cleared.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          },
          child: const Text('Yes'),
        ),
      ],
    ),
  );
}

int _countEntries(dynamic decoded) {
  if (decoded is List) {
    return decoded.length;
  }
  if (decoded is Map && decoded['diaries'] is List) {
    return (decoded['diaries'] as List).length;
  }
  if (decoded is Map) {
    return 1;
  }
  return 0;
}
