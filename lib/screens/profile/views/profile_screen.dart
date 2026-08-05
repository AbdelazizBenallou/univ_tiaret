import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
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
    Future.microtask(() => ref.read(profileProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(profileProvider);
    final profile = state.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(t.translate('profile'))),
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
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.error!,
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
                      icon: const Icon(Icons.refresh_rounded, size: 18),
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
                  email: profile['email'] ?? '',
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
                        icon: Icons.person_rounded,
                        label: t.translate('first_name'),
                        value:
                            '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'
                                .trim(),
                      ),
                      _divider(isDark),
                      _InfoTile(
                        icon: Icons.email_rounded,
                        label: t.translate('email'),
                        value: profile['email'] ?? '-',
                      ),
                      _divider(isDark),
                      _InfoTile(
                        icon: Icons.phone_rounded,
                        label: t.translate('phone_number'),
                        value: profile['phone'] ?? '-',
                      ),
                      _divider(isDark),
                      _InfoTile(
                        icon: Icons.cake_rounded,
                        label: t.translate('date_of_birth'),
                        value: _fmtDate(profile['date_of_birth']),
                      ),
                      _divider(isDark),
                      _InfoTile(
                        icon: Icons.wc_rounded,
                        label: t.translate('gender_label'),
                        value: _genderText(profile['gender'], t),
                      ),
                      _divider(isDark),
                      _InfoTile(
                        icon: Icons.home_rounded,
                        label: t.translate('address'),
                        value: profile['address'] ?? '-',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _sectionLabel(t.translate('academic_info')),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _card(
                    isDark,
                    children: [
                      _InfoTile(
                        icon: Icons.badge_rounded,
                        label: t.translate('student_id'),
                        value: profile['student_id'] ?? '-',
                      ),
                      _divider(isDark),
                      _InfoTile(
                        icon: Icons.school_rounded,
                        label: t.translate('level_name'),
                        value: profile['level_name'] ?? '-',
                      ),
                      _divider(isDark),
                      _InfoTile(
                        icon: Icons.book_rounded,
                        label: t.translate('speciality_name'),
                        value: profile['speciality_name'] ?? '-',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, editProfileScreenRoute),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: Text(
                        t.translate('edit_profile'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
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
  final String email;

  const _ProfileHeader({
    required this.firstName,
    required this.lastName,
    required this.email,
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

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryColor, AppColors.secondaryColor],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              backgroundColor: AppColors.primaryColor,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
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
              color: AppColors.primaryColor.withValues(
                alpha: isDark ? 0.25 : 0.1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryColor),
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
