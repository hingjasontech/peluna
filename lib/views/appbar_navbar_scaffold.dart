import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:peluna/views/widgets/app_bar_widget.dart';
import 'package:peluna/views/widgets/mood_visibility_toggle.dart';
import 'package:peluna/views/widgets/nav_bar_widget.dart';

class AppbarNavbarScaffold extends StatelessWidget {
  const AppbarNavbarScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;
    final title = switch (index) {
      0 => 'Peluna',
      1 => 'Analytics',
      _ => 'Settings',
    };

    return Scaffold(
      appBar: AppBarWidget(
        title: Text(title),
        actions: [if (index == 0) const MoodVisibilityToggle()],
      ),
      bottomNavigationBar: NavbarWidget(navigationShell: navigationShell),
      body: navigationShell,
    );
  }
}
