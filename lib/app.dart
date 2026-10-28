import 'package:flutter/material.dart';

import 'package:peluna/config/router.dart';
import 'package:peluna/config/theme.dart';

class Peluna extends StatelessWidget {
  const Peluna({super.key});

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
