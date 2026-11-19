import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/updates/update_models.dart';

Future<void> showUpdateAvailableDialog(BuildContext context, AppUpdate update) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => UpdateAvailableDialog(update: update),
  );
}

class UpdateAvailableDialog extends ConsumerStatefulWidget {
  const UpdateAvailableDialog({super.key, required this.update});

  final AppUpdate update;

  @override
  ConsumerState<UpdateAvailableDialog> createState() =>
      _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends ConsumerState<UpdateAvailableDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _openRelease() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final opened = await ref
        .read(externalLinkLauncherProvider)
        .open(widget.update.releasePage);

    if (!mounted) return;
    if (opened) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _busy = false;
      _error =
          'Could not open the release page. Check that a browser is '
          'available, then try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: const Text('Update available'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Peluna ${widget.update.versionLabel} is available.',
                style: theme.textTheme.titleSmall,
              ),
              if (widget.update.releaseNotes.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _shortNotes(widget.update.releaseNotes),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'GitHub opens in your browser. Download the APK there, then '
                'install it.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: _busy ? null : _openRelease,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Get update'),
          ),
        ],
      ),
    );
  }

  String _shortNotes(String notes) {
    final trimmed = notes.trim();
    if (trimmed.length <= 600) return trimmed;
    return '${trimmed.substring(0, 600)}…';
  }
}
