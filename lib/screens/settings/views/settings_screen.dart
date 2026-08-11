import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:univ_tiaret/components/auth_network_image.dart';
import 'package:univ_tiaret/components/floating_snackbar.dart';
import 'package:univ_tiaret/components/settings_tiles.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/logic/auth_provider.dart';
import 'package:univ_tiaret/logic/connectivity_provider.dart';
import 'package:univ_tiaret/logic/profile_provider.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/main.dart';
import 'package:univ_tiaret/route/route_constants.dart';
import 'package:univ_tiaret/services/badge_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final networkStatus = ref.watch(connectivityProvider);
    final t = AppLocalizations.of(context);
    final appState = MyApp.of(context);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sections = _buildSections(
      context,
      t,
      ref,
      appState,
      networkStatus,
      colors,
      isDark,
    );
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? sections
        : sections
              .map(
                (s) => _SettingsSection(
                  label: s.label,
                  items: s.items.where((item) => item.matches(query)).toList(),
                ),
              )
              .where((s) => s.items.isNotEmpty)
              .toList();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      width: double.infinity,
      height: double.infinity,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ProfileHeader(
            firstName: auth.user?.firstName ?? '',
            lastName: auth.user?.lastName ?? '',
            avatarUrl: ref.read(profileProvider).avatarUrlOf(auth.user?.avatar),
            isDark: isDark,
            colors: colors,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: t.translate('search_settings'),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 22,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.55)
                      : AppColors.textLight,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.55)
                              : AppColors.textLight,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF0F2F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (query.isNotEmpty && visible.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  t.translate('no_results'),
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          for (final section in visible) ...[
            const SizedBox(height: 20),
            _SectionHeader(
              label: section.label,
              isDark: isDark,
              colors: colors,
            ),
            const SizedBox(height: 8),
            SettingsCard(
              isDark: isDark,
              children: _withDividers(
                section.items.map((item) => item.builder(context)).toList(),
                isDark,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context, ref, t),
                icon: Icon(LucideIcons.logOut, size: 18, color: errorColor),
                label: Text(
                  t.translate('log_out'),
                  style: TextStyle(
                    color: errorColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: errorColor.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> children, bool isDark) {
    return [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) settingsDivider(isDark),
        children[i],
      ],
    ];
  }

  String _searchText(String title, String? subtitle) =>
      '$title ${subtitle ?? ''}'.toLowerCase();

  List<_SettingsSection> _buildSections(
    BuildContext context,
    AppLocalizations t,
    WidgetRef ref,
    MyAppState? appState,
    NetworkStatus networkStatus,
    ColorScheme colors,
    bool isDark,
  ) {
    final statusLabel = switch (networkStatus) {
      NetworkStatus.online => t.translate('status_online'),
      NetworkStatus.offline => t.translate('status_offline'),
      NetworkStatus.checking => t.translate('status_checking'),
    };

    return [
      _SettingsSection(
        label: t.translate('account'),
        items: [
          _SettingsItem(
            searchText: _searchText(
              t.translate('security'),
              t.translate('security_subtitle'),
            ),
            builder: (ctx) => SettingsTile(
              icon: LucideIcons.shield,
              iconColor: isDark ? Colors.white.withValues(alpha: 0.55) : AppColors.primaryColor,
              title: t.translate('security'),
              subtitle: t.translate('security_subtitle'),
              onTap: () => Navigator.pushNamed(ctx, securityScreenRoute),
              isDark: isDark,
              colors: colors,
            ),
          ),
        ],
      ),
      _SettingsSection(
        label: t.translate('preferences'),
        items: [
          _SettingsItem(
            searchText: _searchText(
              t.translate('theme'),
              _themeModeLabel(appState?.themeMode ?? ThemeMode.system, t),
            ),
            builder: (ctx) => SettingsTile(
              icon: LucideIcons.palette,
              iconColor: isDark ? Colors.white.withValues(alpha: 0.55) : AppColors.primaryColor,
              title: t.translate('theme'),
              subtitle: _themeModeLabel(
                appState?.themeMode ?? ThemeMode.system,
                t,
              ),
              trailing: _ThemeBadge(
                mode: appState?.themeMode ?? ThemeMode.system,
              ),
              onTap: () => _showThemePicker(ctx),
              isDark: isDark,
              colors: colors,
            ),
          ),
          _SettingsItem(
            searchText: _searchText(t.translate('language'), _currentLang(t)),
            builder: (ctx) => SettingsTile(
              icon: LucideIcons.languages,
              iconColor: isDark ? Colors.white.withValues(alpha: 0.55) : AppColors.primaryColor,
              title: t.translate('language'),
              subtitle: _currentLang(t),
              trailing: Text(
                _currentLang(t),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
              ),
              onTap: () => _showLangPicker(ctx),
              isDark: isDark,
              colors: colors,
            ),
          ),
          _SettingsItem(
            searchText: _searchText(
              t.translate('notifications'),
              t.translate('push_notifications'),
            ),
            builder: (ctx) => Consumer(
              builder: (context, ref, _) {
                final count = ref.watch(badgeNotificationCountProvider);
                return SettingsTile(
                  icon: LucideIcons.bell,
                  iconColor: isDark ? Colors.white.withValues(alpha: 0.55) : AppColors.primaryColor,
                  title: t.translate('notifications'),
                  subtitle: t.translate('push_notifications'),
                  trailing: count > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        )
                      : null,
                  onTap: () => Navigator.pushNamed(ctx, notificationsScreenRoute),
                  isDark: isDark,
                  colors: colors,
                );
              },
            ),
          ),
        ],
      ),
      _SettingsSection(
        label: t.translate('storage_data'),
        items: [
          _SettingsItem(
            searchText: _searchText(
              t.translate('downloads'),
              t.translate('manage_downloads'),
            ),
            builder: (ctx) => SettingsTile(
              icon: LucideIcons.download,
              iconColor: isDark ? Colors.white.withValues(alpha: 0.55) : AppColors.primaryColor,
              title: t.translate('downloads'),
              subtitle: t.translate('manage_downloads'),
              onTap: () => Navigator.pushNamed(ctx, downloadsScreenRoute),
              isDark: isDark,
              colors: colors,
            ),
          ),
          _SettingsItem(
            searchText: _searchText(
              t.translate('storage'),
              t.translate('manage_storage'),
            ),
            builder: (ctx) => SettingsTile(
              icon: LucideIcons.folder,
              iconColor: isDark ? Colors.white.withValues(alpha: 0.55) : AppColors.primaryColor,
              title: t.translate('storage'),
              subtitle: t.translate('manage_storage'),
              onTap: () {},
              isDark: isDark,
              colors: colors,
            ),
          ),
          _SettingsItem(
            searchText: _searchText(t.translate('network_status'), statusLabel),
            builder: (ctx) =>
                _networkStatusTile(t, networkStatus, isDark, colors),
          ),
        ],
      ),
      _SettingsSection(
        label: t.translate('support'),
        items: [
          _SettingsItem(
            searchText: _searchText(
              t.translate('about_us'),
              t.translate('about_us_subtitle'),
            ),
            builder: (ctx) => SettingsTile(
              icon: LucideIcons.info,
              iconColor: isDark ? Colors.white.withValues(alpha: 0.55) : AppColors.primaryColor,
              title: t.translate('about_us'),
              subtitle: t.translate('about_us_subtitle'),
              onTap: () => Navigator.pushNamed(ctx, aboutUsScreenRoute),
              isDark: isDark,
              colors: colors,
            ),
          ),
          _SettingsItem(
            searchText: _searchText(
              t.translate('terms_and_conditions'),
              t.translate('terms_and_conditions_subtitle'),
            ),
            builder: (ctx) => SettingsTile(
              icon: LucideIcons.fileText,
              iconColor: isDark ? Colors.white.withValues(alpha: 0.55) : AppColors.primaryColor,
              title: t.translate('terms_and_conditions'),
              subtitle: t.translate('terms_and_conditions_subtitle'),
              onTap: () => Navigator.pushNamed(ctx, termsScreenRoute),
              isDark: isDark,
              colors: colors,
            ),
          ),
        ],
      ),
      _SettingsSection(
        label: t.translate('reviews'),
        items: [
          _SettingsItem(
            searchText: _searchText(
              t.translate('write_review'),
              t.translate('review_hint'),
            ),
            builder: (ctx) => SettingsTile(
              icon: LucideIcons.star,
              iconColor: isDark ? Colors.white.withValues(alpha: 0.55) : AppColors.primaryColor,
              title: t.translate('write_review'),
              subtitle: t.translate('review_hint'),
              onTap: () => Navigator.pushNamed(ctx, writeReviewScreenRoute),
              isDark: isDark,
              colors: colors,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _networkStatusTile(
    AppLocalizations t,
    NetworkStatus status,
    bool isDark,
    ColorScheme colors,
  ) {
    final (icon, label, color) = switch (status) {
      NetworkStatus.online => (
        LucideIcons.wifi,
        t.translate('status_online'),
        AppColors.success,
      ),
      NetworkStatus.offline => (
        LucideIcons.wifiOff,
        t.translate('status_offline'),
        AppColors.error,
      ),
      NetworkStatus.checking => (
        LucideIcons.radar,
        t.translate('status_checking'),
        AppColors.warning,
      ),
    };

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.translate('network_status'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
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
          icon: LucideIcons.smartphone,
          label: t.translate('system'),
          selected: app?.themeMode == ThemeMode.system,
          onTap: () => _setTheme(context, ThemeMode.system),
        ),
        _PickerItem(
          icon: LucideIcons.sun,
          label: t.translate('light'),
          selected: app?.themeMode == ThemeMode.light,
          onTap: () => _setTheme(context, ThemeMode.light),
        ),
        _PickerItem(
          icon: LucideIcons.moon,
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
          icon: LucideIcons.languages,
          label: t.translate('english'),
          selected: t.locale.languageCode == 'en',
          onTap: () => _setLang(context, 'en'),
        ),
        _PickerItem(
          icon: LucideIcons.languages,
          label: t.translate('french'),
          selected: t.locale.languageCode == 'fr',
          onTap: () => _setLang(context, 'fr'),
        ),
        _PickerItem(
          icon: LucideIcons.languages,
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

  void _showLogoutDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations t,
  ) {
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
  const _PickerRow({
    required this.item,
    required this.isDark,
    required this.colors,
  });

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
                    fontWeight: item.selected
                        ? FontWeight.w600
                        : FontWeight.w400,
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
                  child: Icon(LucideIcons.check, size: 13, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final bool isDark;
  final ColorScheme colors;

  const _ProfileHeader({
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final name = '$firstName $lastName'.trim();
    final initials = () {
      final f = firstName.isNotEmpty ? firstName[0] : '';
      final l = lastName.isNotEmpty ? lastName[0] : '';
      final s = '$f$l'.toUpperCase();
      return s.isNotEmpty ? s : '?';
    }();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: isDark ? const Color(0xFF242526) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, profileScreenRoute),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.onSurface.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF242526) : Colors.white,
                    border: Border.all(
                      color: colors.onSurface.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: AuthNetworkImage(
                      url: avatarUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
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
                        name.isNotEmpty ? name : 'Student',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Account',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  final ColorScheme colors;

  const _SectionHeader({
    required this.label,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: colors.onSurface.withValues(alpha: 0.4),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsSection {
  final String label;
  final List<_SettingsItem> items;

  const _SettingsSection({required this.label, required this.items});
}

class _SettingsItem {
  final String searchText;
  final Widget Function(BuildContext context) builder;

  const _SettingsItem({required this.searchText, required this.builder});

  bool matches(String query) => searchText.contains(query);
}

class _ThemeBadge extends StatelessWidget {
  final ThemeMode mode;
  const _ThemeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      ThemeMode.dark => LucideIcons.moon,
      ThemeMode.light => LucideIcons.sun,
      ThemeMode.system => LucideIcons.smartphone,
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
      child: Icon(
        icon,
        size: 16,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}
