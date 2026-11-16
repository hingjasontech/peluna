import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/providers/update_providers.dart';
import 'package:peluna/updates/update_installer.dart';
import 'package:peluna/updates/update_models.dart';

Future<void> showUpdateAvailableDialog(BuildContext context, AppUpdate update) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => UpdateAvailableDialog(update: update),
  );
}

enum _UpdatePhase {
  prompt,
  checkingPermission,
  needsPermission,
  downloading,
  verifying,
  installing,
  error,
}

class UpdateAvailableDialog extends ConsumerStatefulWidget {
  const UpdateAvailableDialog({super.key, required this.update});

  final AppUpdate update;

  @override
  ConsumerState<UpdateAvailableDialog> createState() =>
      _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends ConsumerState<UpdateAvailableDialog> {
  _UpdatePhase _phase = _UpdatePhase.prompt;
  double? _progress;
  String? _error;
  bool _busy = false;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _handleResume);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _handleResume() {
    if (!mounted || _phase != _UpdatePhase.needsPermission || _busy) {
      return;
    }
    _startInstall();
  }

  Future<void> _startInstall() async {
    if (_busy) return;

    final installer = ref.read(updateInstallerProvider);
    setState(() {
      _busy = true;
      _error = null;
      _phase = _UpdatePhase.checkingPermission;
    });

    try {
      final allowed = await installer.canInstall();
      if (!mounted) return;
      if (!allowed) {
        setState(() {
          _phase = _UpdatePhase.needsPermission;
          _busy = false;
        });
        return;
      }
      await _downloadAndInstall(installer);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = _UpdatePhase.error;
        _error = _errorMessage(error);
        _busy = false;
      });
    }
  }

  Future<void> _openInstallSettings() async {
    try {
      await ref.read(updateInstallerProvider).openInstallSettings();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = _UpdatePhase.error;
        _error = error is PlatformException
            ? error.message ?? 'Android could not open its settings.'
            : 'Android could not open its settings.';
        _busy = false;
      });
    }
  }

  Future<void> _downloadAndInstall(UpdateInstaller installer) async {
    setState(() {
      _phase = _UpdatePhase.downloading;
      _progress = null;
    });

    try {
      final path = await ref
          .read(updateDownloaderProvider)
          .download(
            widget.update,
            onProgress: _onProgress,
            onVerifying: () {
              if (!mounted) return;
              setState(() => _phase = _UpdatePhase.verifying);
            },
          );

      if (!mounted) return;
      setState(() => _phase = _UpdatePhase.installing);
      await installer.install(path);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = _UpdatePhase.error;
        _error = _errorMessage(error);
        _busy = false;
      });
    }
  }

  void _onProgress(double? value) {
    if (!mounted) return;

    if (value == null) {
      if (_progress == null) return;
      setState(() => _progress = null);
      return;
    }

    final next = value.clamp(0.0, 1.0).toDouble();
    if (_progress != null && (next - _progress!).abs() < 0.01) return;
    setState(() => _progress = next);
  }

  String _errorMessage(Object error) {
    if (error is UpdateException) return error.message;
    if (error is PlatformException) {
      return error.message ?? 'Android could not open the installer.';
    }
    return 'The update failed. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(_title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Peluna ${widget.update.versionLabel} is available.',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              _buildBody(theme),
            ],
          ),
        ),
        actions: _buildActions(),
      ),
    );
  }

  String get _title {
    return switch (_phase) {
      _UpdatePhase.prompt => 'Update available',
      _UpdatePhase.checkingPermission => 'Installing update',
      _UpdatePhase.needsPermission => 'Allow installs',
      _UpdatePhase.downloading => 'Installing update',
      _UpdatePhase.verifying => 'Installing update',
      _UpdatePhase.installing => 'Installing update',
      _UpdatePhase.error => 'Update failed',
    };
  }

  Widget _buildBody(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    switch (_phase) {
      case _UpdatePhase.prompt:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.update.apkSize > 0)
              Text(
                'Android APK · ${_formatSize(widget.update.apkSize)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
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
          ],
        );

      case _UpdatePhase.checkingPermission:
        return const _ProgressBody(label: 'Checking install permission…');

      case _UpdatePhase.needsPermission:
        return const Text(
          'Android needs permission to install updates from Peluna. '
          "Enable ‘Allow from this source’ in the settings screen, then "
          'return here to continue.',
        );

      case _UpdatePhase.downloading:
        final percent = _progress == null
            ? null
            : '${(_progress! * 100).round()}%';
        return _ProgressBody(
          label: 'Downloading the update…',
          value: _progress,
          detail: percent,
        );

      case _UpdatePhase.verifying:
        return const _ProgressBody(label: 'Verifying the download…');

      case _UpdatePhase.installing:
        return const _ProgressBody(label: 'Opening the Android installer…');

      case _UpdatePhase.error:
        return Text(_error ?? 'The update failed. Try again.');
    }
  }

  List<Widget> _buildActions() {
    switch (_phase) {
      case _UpdatePhase.prompt:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: _startInstall,
            child: const Text('Download & install'),
          ),
        ];

      case _UpdatePhase.needsPermission:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: _openInstallSettings,
            child: const Text('Open settings'),
          ),
        ];

      case _UpdatePhase.error:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: _startInstall,
            child: const Text('Try again'),
          ),
        ];

      case _UpdatePhase.checkingPermission:
      case _UpdatePhase.downloading:
      case _UpdatePhase.verifying:
      case _UpdatePhase.installing:
        return const [];
    }
  }

  String _shortNotes(String notes) {
    final trimmed = notes.trim();
    if (trimmed.length <= 600) return trimmed;
    return '${trimmed.substring(0, 600)}…';
  }

  String _formatSize(int bytes) {
    final megabytes = bytes / (1024 * 1024);
    return '${megabytes.toStringAsFixed(1)} MB';
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({required this.label, this.value, this.detail});

  final String label;
  final double? value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: value),
        if (detail != null) ...[
          const SizedBox(height: 8),
          Text(
            detail!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
