import 'package:flutter/material.dart';

import 'package:univ_tiaret/l10n/app_localizations.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.name,
    required this.email,
    this.press,
    this.isShowHi = true,
    this.isShowArrow = true,
  });

  final String name, email;
  final bool isShowHi, isShowArrow;
  final VoidCallback? press;

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return ListTile(
      onTap: press,
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: theme.colorScheme.primary,
        child: Text(
          _getInitials(name),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            isShowHi ? "${t.translate('hi')}, $name" : name,
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      subtitle: Text(email),
      trailing: isShowArrow
          ? Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: Theme.of(context).iconTheme.color!.withValues(alpha: 0.4),
            )
          : null,
    );
  }
}
