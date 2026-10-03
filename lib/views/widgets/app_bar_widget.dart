import 'package:flutter/material.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({super.key, this.title, this.leading});

  final Widget? title;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title ?? Text('Peluna'),
      centerTitle: true,
      leading: leading,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
