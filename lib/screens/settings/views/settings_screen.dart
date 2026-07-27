import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/floating_snackbar.dart';
import 'package:univ_tiaret/components/server_config_dialog.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/logic/auth_provider.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/main.dart';
import 'package:univ_tiaret/route/route_constants.dart';
import 'package:univ_tiaret/screens/profile/views/components/profile_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final t = AppLocalizations.of(context);
    final appState = MyApp.of(context);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      width: double.infinity,
      height: double.infinity,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          ProfileCard(
          name: auth.user?.firstName ?? "Student",
          email: auth.user?.email ?? "student@univ-tiaret.dz",
          press: () {},
        ),
        const SizedBox(height: 20),
        _SettingsCard(
          title: t.translate('account'),
          children: [
            _GreenTile(
              icon: Icons.person_outline_rounded,
              title: t.translate('profile'),
              subtitle: auth.user?.firstName ?? '',
              onTap: () {},
            ),
            _tileDivider(context),
            _GreenTile(
              icon: Icons.lock_outline_rounded,
              title: t.translate('change_password'),
              subtitle: '',
              onTap: () {
                Navigator.pushNamed(context, changePasswordScreenRoute);
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SettingsCard(
          title: t.translate('subscription'),
          children: [
            _GreenTile(
              icon: Icons.card_membership_rounded,
              title: t.translate('manage_subscription'),
              subtitle: '',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SettingsCard(
          title: t.translate('content'),
          children: [
            _GreenTile(
              icon: Icons.download_rounded,
              title: t.translate('downloads'),
              subtitle: '',
              onTap: () {
                Navigator.pushNamed(context, downloadsScreenRoute);
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SettingsCard(
          title: t.translate('preferences'),
          children: [
            _GreenTile(
              icon: Icons.palette_outlined,
              title: t.translate('theme'),
              subtitle: _themeModeLabel(appState?.themeMode ?? ThemeMode.system, t),
              onTap: () => _showThemePicker(context),
            ),
            _tileDivider(context),
            _GreenTile(
              icon: Icons.language_outlined,
              title: t.translate('language'),
              subtitle: _currentLang(t),
              onTap: () => _showLangPicker(context),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SettingsCard(
          title: t.translate('settings'),
          children: [
            _GreenTile(
              icon: Icons.notifications_outlined,
              title: t.translate('notifications'),
              subtitle: '',
              onTap: () {},
            ),
            _tileDivider(context),
            _GreenTile(
              icon: Icons.settings_outlined,
              title: t.translate('server_config'),
              subtitle: '',
              onTap: () => ServerConfigDialog.show(context),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SettingsCard(
          title: t.translate('help_support'),
          children: [
            _GreenTile(
              icon: Icons.help_outline_rounded,
              title: t.translate('get_help'),
              subtitle: '',
              onTap: () {},
            ),
            _tileDivider(context),
            _GreenTile(
              icon: Icons.question_answer_outlined,
              title: t.translate('faq'),
              subtitle: '',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Container(
            decoration: BoxDecoration(
              color: errorColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(defaultBorderRadious),
            ),
            child: ListTile(
              onTap: () => _showLogoutDialog(context, ref, t),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadious),
              ),
              leading: SvgPicture.asset(
                "assets/icons/Logout.svg",
                height: 24,
                width: 24,
                colorFilter: const ColorFilter.mode(
                  errorColor,
                  BlendMode.srcIn,
                ),
              ),
              title: Text(
                t.translate('log_out'),
                style: const TextStyle(
                  color: errorColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _tileDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 70,
      endIndent: 16,
      color: Theme.of(context).dividerTheme.color?.withValues(alpha: 0.3),
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
          icon: Icons.language,
          label: t.translate('english'),
          selected: t.locale.languageCode == 'en',
          onTap: () => _setLang(context, 'en'),
        ),
        _PickerItem(
          icon: Icons.language,
          label: t.translate('french'),
          selected: t.locale.languageCode == 'fr',
          onTap: () => _setLang(context, 'fr'),
        ),
        _PickerItem(
          icon: Icons.language,
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
                child: _PickerRow(item: item),
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
  const _PickerRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
                      : Theme.of(context).brightness == Brightness.dark
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
                  child: const Icon(Icons.check, size: 13, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.greenAccent.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.greenAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenAccent,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _GreenTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _GreenTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.greenLight, AppColors.greenAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.greenAccent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 20, color: Colors.white),
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
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
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
