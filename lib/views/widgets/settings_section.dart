import 'package:flutter/material.dart';

/// A titled group of related settings rows rendered as one card.
///
/// Add new settings to an existing section when possible; create a new
/// [SettingsSection] when the setting belongs to a different area
/// (Appearance, Data, Updates, ...).
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Card.filled(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0)
                  const Divider(height: 1, indent: 16, endIndent: 16),
                children[index],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One row inside a [SettingsSection].
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Styles the row as destructive (clear data, delete account, ...).
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = danger ? colorScheme.error : colorScheme.onSurfaceVariant;

    return ListTile(
      minVerticalPadding: 12,
      leading: icon == null ? null : Icon(icon, color: accent),
      title: Text(
        title,
        style: danger ? TextStyle(color: colorScheme.error) : null,
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing:
          trailing ??
          (onTap == null
              ? null
              : Icon(Icons.chevron_right, color: danger ? accent : null)),
      onTap: onTap,
    );
  }
}
