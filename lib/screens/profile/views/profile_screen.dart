import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/auth_network_image.dart';
import 'package:univ_tiaret/components/avatar_viewer.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:univ_tiaret/logic/profile_provider.dart';
import 'package:univ_tiaret/route/route_constants.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('[Profile] initState -> loading profile');
    Future.microtask(() => ref.read(profileProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(profileProvider);
    final profile = state.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final socialLinks = parseSocialLinks(profile?['social_media_links']);

    final avatarUrl = profile?['avatar'] == null
        ? null
        : ref.read(profileProvider).avatarUrlOf(profile!['avatar'] as String?);
    debugPrint('[Profile] build: loading=${state.loading}, '
        'error=${state.error}, avatarUrl=$avatarUrl, '
        'socialLinks=${socialLinks.length}');

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(t.translate('profile')),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, editProfileScreenRoute),
            icon: const Icon(LucideIcons.pencil, size: 22),
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.alertCircle,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.translate(state.error!),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.read(profileProvider.notifier).load(),
                      icon: const Icon(LucideIcons.refreshCw, size: 18),
                      label: Text(t.translate('try_again')),
                    ),
                  ],
                ),
              ),
            )
          : profile == null
          ? const Center(child: Text('No profile data'))
          : ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                _ProfileHeader(
                  firstName: profile['first_name'] ?? '',
                  lastName: profile['last_name'] ?? '',
                  specialityName: profile['speciality_name'] ?? '',
                  levelName: profile['level_name'] ?? '',
                  avatarUrl: avatarUrl,
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _sectionLabel(t.translate('personal_details')),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _card(
                    isDark,
                    children: [
                      _InfoTile(
                        icon: LucideIcons.mail,
                        label: t.translate('email'),
                        value: profile['email'] ?? '-',
                      ),
                      _divider(isDark),
                      _InfoTile(
                        icon: LucideIcons.phone,
                        label: t.translate('phone_number'),
                        value: profile['phone'] ?? '-',
                      ),
                      _divider(isDark),
                      _InfoTile(
                        icon: LucideIcons.calendarDays,
                        label: t.translate('date_of_birth'),
                        value: _fmtDate(profile['date_of_birth']),
                      ),
                      _divider(isDark),
                      _InfoTile(
                        icon: LucideIcons.user,
                        label: t.translate('gender_label'),
                        value: _genderText(profile['gender'], t),
                      ),
                      _divider(isDark),
                      _InfoTile(
                        icon: LucideIcons.mapPin,
                        label: t.translate('address'),
                        value: profile['address'] ?? '-',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                if (socialLinks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _sectionLabel(t.translate('social_media')),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _card(
                      isDark,
                      children: [
                        for (var i = 0; i < socialLinks.length; i++) ...[
                          if (i > 0) _divider(isDark),
                          _SocialLinkTile(
                            link: socialLinks[i],
                            isLast: i == socialLinks.length - 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  String _genderText(dynamic gender, AppLocalizations t) {
    final raw = gender?.toString().trim();
    if (raw == null || raw.isEmpty) return '-';
    final lower = raw.toLowerCase();
    if (lower == 'female' || lower == 'f') return t.translate('female');
    if (lower == 'male' || lower == 'm') return t.translate('male');
    return raw;
  }

  String _fmtDate(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      indent: 68,
      endIndent: 16,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String specialityName;
  final String levelName;
  final String? avatarUrl;

  const _ProfileHeader({
    required this.firstName,
    required this.lastName,
    required this.specialityName,
    required this.levelName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final name = '${_capitalize(firstName)} ${_capitalize(lastName)}'.trim();
    final hasSpeciality = specialityName.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => showAvatarViewer(context, url: avatarUrl),
            child: Container(
              width: 128,
              height: 128,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDark
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: ClipOval(
                child: AuthNetworkImage(
                  url: avatarUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: _avatarPlaceholder(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasSpeciality || levelName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Column(
              children: [
                if (hasSpeciality)
                  _headerSubtitle(context, specialityName, isDark),
                if (hasSpeciality && levelName.isNotEmpty)
                  const SizedBox(height: 2),
                if (levelName.isNotEmpty)
                  _headerSubtitle(context, _formatLevel(levelName), isDark),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerSubtitle(BuildContext context, String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: isDark
            ? Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7)
            : Colors.black26,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _avatarPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: Icon(
        LucideIcons.user,
        size: 44,
        color: AppColors.primaryColor,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.55)
                  : AppColors.primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialLinkTile extends StatelessWidget {
  final Map<String, dynamic> link;
  final bool isLast;
  const _SocialLinkTile({required this.link, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final platform = (link['platform'] ?? '').toString().trim();
    final url = (link['url'] ?? '').toString().trim();

    return InkWell(
      onTap: url.isEmpty ? null : () => _openUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: isLast
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _socialIcon(platform),
                size: 20,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform.isEmpty ? '-' : platform,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  if (url.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: colors.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _card(bool isDark, {required List<Widget> children}) {
  return Container(
    decoration: BoxDecoration(
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.transparent
              : Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(children: children),
  );
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String _formatLevel(String level) {
  if (level.isEmpty) return level;
  final first = level[0].toUpperCase();
  final rest = level.substring(1).trim();
  final prefix = switch (first) {
    'M' => 'Master',
    'L' => 'Level',
    _ => null,
  };
  if (prefix == null) return level;
  return rest.isEmpty ? prefix : '$prefix $rest';
}

IconData _socialIcon(String platform) {
  switch (platform.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
    case 'instagram':
      return Icons.movie;
    case 'linkedin':
      return Icons.business_center;
    case 'github':
      return Icons.code;
    case 'twitter':
    case 'x':
      return Icons.tag;
    case 'youtube':
      return Icons.smart_display;
    default:
      return Icons.public;
  }
}

Future<void> _openUrl(String url) async {
  var uri = Uri.tryParse(url);
  if (uri == null) {
    debugPrint('[Profile] Invalid URL: $url');
    return;
  }
  if (!uri.hasScheme) {
    uri = Uri.parse('https://$url');
  }
  debugPrint('[Profile] Opening URL: $uri');
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  debugPrint('[Profile] launchUrl result: ${ok ? 'SUCCESS' : 'FAILED'}');
}
