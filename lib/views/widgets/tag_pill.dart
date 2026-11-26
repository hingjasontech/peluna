import 'package:flutter/material.dart';

/// The rounded tag pill shared by the diary editor and the tags page.
///
/// Keeping one widget makes the tag cards look identical in both places.
class TagPill extends StatelessWidget {
  const TagPill({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '#$tag',
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
