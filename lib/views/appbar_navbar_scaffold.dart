import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peluna/views/widgets/app_bar_widget.dart';
import 'package:peluna/views/widgets/nav_bar_widget.dart';

class AppbarNavbarScaffold extends StatelessWidget {
  const AppbarNavbarScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(),
      bottomNavigationBar: NavbarWidget(navigationShell: navigationShell),
      body: navigationShell,
    );
  }
}
