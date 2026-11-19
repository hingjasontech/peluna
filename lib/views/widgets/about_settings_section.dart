import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/config/app_links.dart';
import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/providers/update_providers.dart';
import 'package:peluna/updates/update_models.dart';
import 'package:peluna/views/widgets/settings_section.dart';
import 'package:peluna/views/widgets/update_dialog.dart';

/// Identifies the GitHub source link in widget tests.
const Key viewSourceCodeTileKey = Key('view-source-code-tile');

class AboutSettingsSection extends ConsumerStatefulWidget {
  const AboutSettingsSection({super.key});

  @override
  ConsumerState<AboutSettingsSection> createState() =>
      _AboutSettingsSectionState();
}

class _AboutSettingsSectionState extends ConsumerState<AboutSettingsSection> {
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

  Future<void> _openSourceCode() async {
    final opened = await ref
        .read(externalLinkLauncherProvider)
        .open(AppLinks.sourceCode);

    if (!opened && mounted) {
      _showSnack(
        context,
        'Could not open GitHub. Check that a browser is available.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportsAppUpdates = ref.watch(supportsAppUpdatesProvider);

    return SettingsSection(
      title: 'About',
      children: [
        if (supportsAppUpdates)
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
          key: viewSourceCodeTileKey,
          title: 'View source code',
          leading: Image.asset(
            'assets/github_mark.png',
            width: 24,
            height: 24,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onTap: _openSourceCode,
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
