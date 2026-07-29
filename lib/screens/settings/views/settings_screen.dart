import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/floating_snackbar.dart';
import 'package:univ_tiaret/components/server_config_dialog.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/logic/auth_provider.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/main.dart';
import 'package:univ_tiaret/route/route_constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final t = AppLocalizations.of(context);
    final appState = MyApp.of(context);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      width: double.infinity,
      height: double.infinity,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _ProfileHeader(
            name: auth.user?.firstName ?? t.translate('student'),
            email: auth.user?.email ?? 'student@univ-tiaret.dz',
            isDark: isDark,
            colors: colors,
          ),
          const SizedBox(height: 24),
          _SectionCard(
            isDark: isDark,
            children: [
              _SettingTile(
                icon: Icons.person_rounded,
                title: t.translate('profile'),
                onTap: () {},
                isDark: isDark,
                colors: colors,
              ),
              _divider(isDark),
              _SettingTile(
                icon: Icons.lock_rounded,
                title: t.translate('change_password'),
                onTap: () => Navigator.pushNamed(context, changePasswordScreenRoute),
                isDark: isDark,
                colors: colors,
              ),
              _divider(isDark),
              _SettingTile(
                icon: Icons.badge_rounded,
                title: t.translate('manage_subscription'),
                subtitle: t.translate('subscription'),
                onTap: () {},
                isDark: isDark,
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            isDark: isDark,
            children: [
              _SettingTile(
                icon: Icons.download_rounded,
                title: t.translate('downloads'),
                onTap: () => Navigator.pushNamed(context, downloadsScreenRoute),
                isDark: isDark,
                colors: colors,
              ),
              _divider(isDark),
              _SettingTile(
                icon: Icons.folder_rounded,
                title: t.translate('storage'),
                subtitle: t.translate('manage_storage'),
                onTap: () {},
                isDark: isDark,
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            isDark: isDark,
            children: [
              _SettingTile(
                icon: Icons.palette_rounded,
                title: t.translate('theme'),
                subtitle: _themeModeLabel(appState?.themeMode ?? ThemeMode.system, t),
                trailing: _ThemeBadge(mode: appState?.themeMode ?? ThemeMode.system),
                onTap: () => _showThemePicker(context),
                isDark: isDark,
                colors: colors,
              ),
              _divider(isDark),
              _SettingTile(
                icon: Icons.language_rounded,
                title: t.translate('language'),
                subtitle: _currentLang(t),
                trailing: Text(
                  _currentLang(t),
                  style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.4)),
                ),
                onTap: () => _showLangPicker(context),
                isDark: isDark,
                colors: colors,
              ),
              _divider(isDark),
              _SettingTile(
                icon: Icons.notifications_rounded,
                title: t.translate('notifications'),
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeThumbColor: AppColors.greenAccent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onTap: () {},
                isDark: isDark,
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            isDark: isDark,
            children: [
              _SettingTile(
                icon: Icons.dns_rounded,
                title: t.translate('server_config'),
                onTap: () => ServerConfigDialog.show(context),
                isDark: isDark,
                colors: colors,
              ),
              _divider(isDark),
              _SettingTile(
                icon: Icons.help_outline_rounded,
                title: t.translate('get_help'),
                onTap: () {},
                isDark: isDark,
                colors: colors,
              ),
              _divider(isDark),
              _SettingTile(
                icon: Icons.chat_rounded,
                title: t.translate('faq'),
                onTap: () {},
                isDark: isDark,
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: errorColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => _showLogoutDialog(context, ref, t),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 20, color: errorColor),
                      const SizedBox(width: 10),
                      Text(
                        t.translate('log_out'),
                        style: TextStyle(
                          color: errorColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
    );
  }

  String _currentLang(AppLocalizations t) {
    switch (t.locale.languageCode) {
      case 'fr':
        return t.translate('french');
      case 'ar':
        return t.translate('arabic');
      default:
        return t.translate('english');
    }
  }

  String _themeModeLabel(ThemeMode mode, AppLocalizations t) {
    switch (mode) {
      case ThemeMode.dark:
        return t.translate('dark');
      case ThemeMode.light:
        return t.translate('light');
      case ThemeMode.system:
        return t.translate('system');
    }
  }

  void _showThemePicker(BuildContext context) {
    final t = AppLocalizations.of(context);
    final app = MyApp.of(context);
    _showPicker(
      context: context,
      title: t.translate('theme'),
      items: [
        _PickerItem(
          icon: Icons.phone_android_rounded,
          label: t.translate('system'),
          selected: app?.themeMode == ThemeMode.system,
          onTap: () => _setTheme(context, ThemeMode.system),
        ),
        _PickerItem(
          icon: Icons.light_mode_rounded,
          label: t.translate('light'),
          selected: app?.themeMode == ThemeMode.light,
          onTap: () => _setTheme(context, ThemeMode.light),
        ),
        _PickerItem(
          icon: Icons.dark_mode_rounded,
          label: t.translate('dark'),
          selected: app?.themeMode == ThemeMode.dark,
          onTap: () => _setTheme(context, ThemeMode.dark),
        ),
      ],
    );
  }

  void _setTheme(BuildContext context, ThemeMode mode) {
    Navigator.pop(context);
    MyApp.of(context)?.setThemeMode(mode);
  }

  void _showLangPicker(BuildContext context) {
    final t = AppLocalizations.of(context);
    _showPicker(
      context: context,
      title: t.translate('language'),
      items: [
        _PickerItem(
          icon: Icons.language_rounded,
          label: t.translate('english'),
          selected: t.locale.languageCode == 'en',
          onTap: () => _setLang(context, 'en'),
        ),
        _PickerItem(
          icon: Icons.language_rounded,
          label: t.translate('french'),
          selected: t.locale.languageCode == 'fr',
          onTap: () => _setLang(context, 'fr'),
        ),
        _PickerItem(
          icon: Icons.language_rounded,
          label: t.translate('arabic'),
          selected: t.locale.languageCode == 'ar',
          onTap: () => _setLang(context, 'ar'),
        ),
      ],
    );
  }

  void _setLang(BuildContext context, String code) {
    Navigator.pop(context);
    MyApp.of(context)?.setLocale(Locale(code));
  }

  void _showPicker({
    required BuildContext context,
    required String title,
    required List<_PickerItem> items,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.greenAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _PickerRow(item: item, isDark: isDark, colors: colors),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadious),
        ),
        title: Text(t.translate('log_out')),
        content: Text(t.translate('log_out_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                showFloatingSnackBar(
                  context,
                  message: t.translate('logged_out'),
                  type: SnackBarType.success,
                );
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  logInScreenRoute,
                  (route) => false,
                );
              }
            },
            child: Text(
              t.translate('log_out'),
              style: const TextStyle(color: errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerItem {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  _PickerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

class _PickerRow extends StatelessWidget {
  final _PickerItem item;
  final bool isDark;
  final ColorScheme colors;
  const _PickerRow({required this.item, required this.isDark, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.selected
          ? AppColors.greenAccent.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.selected
                      ? AppColors.greenAccent
                      : isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  size: 18,
                  color: item.selected
                      ? Colors.white
                      : colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        item.selected ? FontWeight.w600 : FontWeight.w400,
                    color: item.selected
                        ? AppColors.greenAccent
                        : colors.onSurface,
                  ),
                ),
              ),
              if (item.selected)
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, size: 13, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final bool isDark;
  final ColorScheme colors;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.greenLight, AppColors.greenAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.greenAccent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 18,
                  color: colors.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SectionCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme colors;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = AppColors.greenAccent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.onSurface.withValues(alpha: 0.25),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeBadge extends StatelessWidget {
  final ThemeMode mode;
  const _ThemeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.system => Icons.phone_android_rounded,
    };
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
    );
  }
}
