import 'package:flutter/material.dart';

class ListTileWidget extends StatelessWidget {
  const ListTileWidget({
    super.key,
    required this.title,
    this.leading,
    this.trailing = const Icon(Icons.navigate_next_outlined),
    this.onTap,
    this.tileColor,
  });

  final Widget title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? tileColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 16,
      tileColor: tileColor ?? Theme.of(context).colorScheme.surfaceContainer,
      title: title,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
