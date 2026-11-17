import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/providers/update_providers.dart';
import 'package:peluna/updates/update_models.dart';
import 'package:peluna/views/widgets/settings_section.dart';
import 'package:peluna/views/widgets/update_dialog.dart';

/// Identifies the startup update switch in widget tests.
const Key autoCheckUpdatesSwitchKey = Key('auto-check-updates-switch');

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
    final autoCheck = ref.watch(autoCheckUpdatesProvider);

    return SettingsSection(
      title: 'Updates',
      children: [
        SettingsTile(
          title: 'Check for Updates',
          icon: Icons.system_update_alt_outlined,
          trailing: _checking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _checking ? null : _checkForUpdates,
        ),
        SettingsTile(
          title: 'Check automatically on startup',
          icon: Icons.autorenew,
          trailing: Switch(
            key: autoCheckUpdatesSwitchKey,
            value: autoCheck,
            onChanged: (value) =>
                ref.read(autoCheckUpdatesProvider.notifier).setEnabled(value),
          ),
          onTap: () => ref
              .read(autoCheckUpdatesProvider.notifier)
              .setEnabled(!autoCheck),
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
