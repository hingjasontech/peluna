import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peluna/config/router.dart';
import 'package:peluna/config/theme.dart';
import 'package:peluna/providers/update_providers.dart';
import 'package:peluna/updates/update_models.dart';
import 'package:peluna/views/widgets/update_dialog.dart';

class Peluna extends ConsumerStatefulWidget {
  const Peluna({super.key});

  @override
  ConsumerState<Peluna> createState() => _PelunaState();
}

class _PelunaState extends ConsumerState<Peluna> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOnStartup());
  }

  Future<void> _checkOnStartup() async {
    if (!ref.read(supportsAppUpdatesProvider) ||
        !ref.read(autoCheckUpdatesProvider)) {
      return;
    }

    try {
      final update = await ref.read(updateCheckerProvider).checkForUpdate();
      final navigatorContext = rootNavigatorKey.currentContext;
      if (update == null || !mounted || navigatorContext == null) return;
      if (!navigatorContext.mounted) return;
      await showUpdateAvailableDialog(navigatorContext, update);
    } on UpdateException {
      // Startup checks fail silently: being offline is a normal state.
    } catch (_) {
      // Never block startup because an update check went wrong.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
    );
  }
}
