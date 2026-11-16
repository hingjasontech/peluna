import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/providers/update_providers.dart';
import 'package:peluna/updates/update_models.dart';
import 'package:peluna/views/widgets/list_tile_widget.dart';
import 'package:peluna/views/widgets/update_dialog.dart';

class UpdateSettingsSection extends ConsumerStatefulWidget {
  const UpdateSettingsSection({super.key});

  @override
  ConsumerState<UpdateSettingsSection> createState() =>
      _UpdateSettingsSectionState();
}

class _UpdateSettingsSectionState extends ConsumerState<UpdateSettingsSection> {
  bool _checking = false;

  Future<void> _checkForUpdates() async {
    if (_checking) return;

    setState(() => _checking = true);
    try {
      final update = await ref.read(updateCheckerProvider).checkForUpdate();
      if (!mounted) return;
      setState(() => _checking = false);

      if (update == null) {
        _showSnack(context, 'Peluna is up to date.');
      } else {
        await showUpdateAvailableDialog(context, update);
      }
    } on UpdateException catch (error) {
      if (mounted) _showSnack(context, error.message);
    } catch (_) {
      if (mounted) {
        _showSnack(context, 'Could not check for updates. Try again later.');
      }
    } finally {
      if (mounted && _checking) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final autoCheck = ref.watch(autoCheckUpdatesProvider);

    return Column(
      spacing: 8,
      children: [
        ListTileWidget(
          title: const Text('Check for Updates'),
          subtitle: const Text('Look for a newer GitHub release.'),
          leading: const Icon(Icons.system_update_alt_outlined),
          trailing: _checking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right),
          onTap: _checking ? null : _checkForUpdates,
        ),
        ListTileWidget(
          title: const Text('Check automatically on startup'),
          subtitle: const Text('Only checks GitHub for a new release.'),
          leading: const Icon(Icons.autorenew),
          trailing: Switch(
            value: autoCheck,
            onChanged: (value) =>
                ref.read(autoCheckUpdatesProvider.notifier).setEnabled(value),
          ),
          onTap: () => ref
              .read(autoCheckUpdatesProvider.notifier)
              .setEnabled(!autoCheck),
          tileColor: colorScheme.surfaceContainer,
        ),
      ],
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
