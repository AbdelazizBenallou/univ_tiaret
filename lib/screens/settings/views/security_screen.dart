import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:univ_tiaret/components/settings_tiles.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/route/route_constants.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.primaryColor;

    return Scaffold(
      appBar: AppBar(title: Text(t.translate('security'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          SettingsCard(
            isDark: isDark,
            children: [
              SettingsTile(
                icon: LucideIcons.lock,
                iconColor: iconColor,
                title: t.translate('change_password'),
                subtitle: t.translate('update_security'),
                onTap: () =>
                    Navigator.pushNamed(context, changePasswordScreenRoute),
                isDark: isDark,
                colors: colors,
              ),
              settingsDivider(isDark),
              SettingsTile(
                icon: LucideIcons.idCard,
                iconColor: iconColor,
                title: t.translate('manage_subscription'),
                subtitle: t.translate('subscription'),
                onTap: () => Navigator.pushNamed(context, subscribeScreenRoute),
                isDark: isDark,
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
