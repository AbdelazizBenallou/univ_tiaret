import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:univ_tiaret/components/auth_network_image.dart';
import 'package:univ_tiaret/components/floating_snackbar.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/profile_provider.dart';
import 'package:univ_tiaret/services/api_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _dateOfBirthCtrl;
  late TextEditingController _genderCtrl;
  String? _selectedGender;
  Uint8List? _avatarBytes;
  String? _avatarName;
  final List<Map<String, String>> _socialLinks = [];

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider).profile;
    _firstNameCtrl = TextEditingController(text: p?['first_name'] ?? '');
    _lastNameCtrl = TextEditingController(text: p?['last_name'] ?? '');
    _phoneCtrl = TextEditingController(text: p?['phone'] ?? '');
    _addressCtrl = TextEditingController(text: p?['address'] ?? '');
    _dateOfBirthCtrl = TextEditingController(
      text: _fmtDate(p?['date_of_birth']),
    );
    _selectedGender = p?['gender']?.toString().toLowerCase();
    _genderCtrl = TextEditingController(text: _genderName(_selectedGender));
    for (final link in parseSocialLinks(p?['social_media_links'])) {
      _socialLinks.add({
        'platform': (link['platform'] ?? '').toString(),
        'url': (link['url'] ?? '').toString(),
      });
    }
    debugPrint('[EditProfile] Initialized with profile: '
        'first=${p?['first_name']}, last=${p?['last_name']}, '
        'phone=${p?['phone']}, dob=${p?['date_of_birth']}, '
        'gender=${p?['gender']}, address=${p?['address']}, '
        'avatar=${p?['avatar']}, socialLinks=$_socialLinks');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _dateOfBirthCtrl.dispose();
    _genderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(t.translate('edit_profile')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            _buildHeader(t),
            const SizedBox(height: 20),
            _sectionLabel(t.translate('personal_details')),
            const SizedBox(height: 12),
            _field(
              controller: _firstNameCtrl,
              hint: t.translate('first_name'),
              icon: LucideIcons.user,
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.trim().isEmpty
                  ? t.translate('required')
                  : null,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _lastNameCtrl,
              hint: t.translate('last_name'),
              icon: LucideIcons.userRound,
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.trim().isEmpty
                  ? t.translate('required')
                  : null,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _phoneCtrl,
              hint: t.translate('phone_number'),
              icon: LucideIcons.phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _dateOfBirthCtrl,
              hint: t.translate('date_of_birth'),
              icon: LucideIcons.calendarDays,
              readOnly: true,
              onTap: _pickDate,
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.calendarDays, size: 20),
                onPressed: _pickDate,
              ),
            ),
            const SizedBox(height: 16),
            _field(
              controller: _genderCtrl,
              hint: t.translate('gender_label'),
              icon: LucideIcons.user,
              readOnly: true,
              onTap: _pickGender,
              suffixIcon: const Icon(LucideIcons.chevronDown, size: 20),
            ),
            const SizedBox(height: 16),
            _field(
              controller: _addressCtrl,
              hint: t.translate('address'),
              icon: LucideIcons.mapPin,
              maxLines: 2,
            ),
            const SizedBox(height: 28),
            _sectionLabel(t.translate('social_media')),
            const SizedBox(height: 12),
            if (_socialLinks.isNotEmpty) ...[
              for (var i = 0; i < _socialLinks.length; i++) ...[
                _socialLinkRow(i),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 4),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showSocialLinkDialog(),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: Text(t.translate('add_social_link')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  side: BorderSide(
                    color: AppColors.primaryColor.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: state.saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: state.saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        t.translate('save_changes'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark
                ? Colors.white.withValues(alpha: 0.55)
                : AppColors.primaryColor,
          ),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildHeader(AppLocalizations t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.read(profileProvider).profile;
    final avatarUrl = profile?['avatar'] == null
        ? null
        : ref
            .read(profileProvider)
            .avatarUrlOf(profile!['avatar'] as String?);
    final name =
        '${_capitalize(_firstNameCtrl.text.trim())} ${_capitalize(_lastNameCtrl.text.trim())}'
            .trim();
    final speciality = profile?['speciality_name'] ?? '';
    final level = profile?['level_name'] ?? '';
    final hasSpeciality = speciality.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
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
                  child: SizedBox.expand(
                    child: _avatarBytes != null
                        ? Image.memory(
                            _avatarBytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, _) {
                              debugPrint(
                                  '[EditProfile] Avatar image load FAILED: $e');
                              return _avatarPlaceholder(isDark);
                            },
                          )
                        : AuthNetworkImage(
                            url: avatarUrl,
                            fit: BoxFit.cover,
                            placeholder: _avatarPlaceholder(isDark),
                          ),
                  ),
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.camera,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
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
          if (hasSpeciality || level.isNotEmpty) ...[
            const SizedBox(height: 6),
            Column(
              children: [
                if (hasSpeciality) _headerSubtitle(speciality),
                if (hasSpeciality && level.isNotEmpty)
                  const SizedBox(height: 2),
                if (level.isNotEmpty) _headerSubtitle(_formatLevel(level)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerSubtitle(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

  Widget _avatarPlaceholder(bool isDark) {
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

  Future<void> _pickAvatar() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) {
        debugPrint('[EditProfile] Avatar pick cancelled');
        return;
      }
      final bytes = await file.readAsBytes();
      debugPrint('[EditProfile] Picked avatar: name=${file.name}, '
          'bytes=${bytes.length}');
      if (!mounted) return;
      setState(() {
        _avatarBytes = bytes;
        _avatarName = file.name;
      });
    } catch (e, st) {
      debugPrint('[EditProfile] Avatar pick EXCEPTION: $e\n$st');
      if (!mounted) return;
      showFloatingSnackBar(
        context,
        message: AppLocalizations.of(context).translate('err_network'),
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _pickDate() async {
    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final parsed = _tryParse(_dateOfBirthCtrl.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed ?? DateTime(now.year - 20),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: t.translate('date_of_birth'),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthCtrl.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  String _genderName(String? gender) {
    return gender == 'female' ? 'female' : 'male';
  }

  Future<void> _pickGender() async {
    final t = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(t.translate('male')),
              trailing: _selectedGender != 'female'
                  ? const Icon(
                      LucideIcons.check,
                      color: AppColors.primaryColor,
                    )
                  : null,
              onTap: () => Navigator.pop(context, 'male'),
            ),
            ListTile(
              title: Text(t.translate('female')),
              trailing: _selectedGender == 'female'
                  ? const Icon(
                      LucideIcons.check,
                      color: AppColors.primaryColor,
                    )
                  : null,
              onTap: () => Navigator.pop(context, 'female'),
            ),
          ],
        ),
      ),
    );
    if (choice != null) {
      setState(() {
        _selectedGender = choice;
        _genderCtrl.text = _genderName(choice);
      });
    }
  }

  DateTime? _tryParse(String text) {
    final parts = text.trim().split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        try {
          return DateTime(y, m, d);
        } catch (_) {}
      }
    }
    return null;
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

  static const _socialPlatforms = [
    'Facebook',
    'Instagram',
    'LinkedIn',
    'GitHub',
    'Twitter/X',
    'YouTube',
    'Website',
  ];

  Widget _socialLinkRow(int index) {
    final link = _socialLinks[index];
    final platform = link['platform'] ?? '';
    final url = link['url'] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _linkIcon(platform),
              size: 18,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform.isEmpty ? '-' : platform,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'edit',
            icon: const Icon(Icons.edit_rounded, size: 18),
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            onPressed: () => _showSocialLinkDialog(index),
          ),
          IconButton(
            tooltip: 'delete',
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: Theme.of(context).colorScheme.error,
            onPressed: () => setState(() => _socialLinks.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Future<void> _showSocialLinkDialog([int? index]) async {
    final t = AppLocalizations.of(context);
    final isEdit = index != null;
    final formKey = GlobalKey<FormState>();
    String? platform = isEdit ? _socialLinks[index]['platform'] : null;
    final urlCtrl = TextEditingController(
      text: isEdit ? (_socialLinks[index]['url'] ?? '') : '',
    );
    final colors = Theme.of(context).colorScheme;

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
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
                    isEdit
                        ? t.translate('edit_social_link')
                        : t.translate('add_social_link'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: platform,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: t.translate('platform'),
                  prefixIcon: const Icon(Icons.public, size: 20),
                ),
                items: _socialPlatforms
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p),
                      ),
                    )
                    .toList(),
                onChanged: (v) => platform = v,
                validator: (v) =>
                    v == null ? t.translate('required') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: urlCtrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: t.translate('enter_link'),
                  hintText: 'https://...',
                  prefixIcon: const Icon(Icons.link, size: 20),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? t.translate('required')
                    : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(t.translate('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final url = urlCtrl.text.trim();
                        final normalized = url.startsWith('http://') ||
                                url.startsWith('https://')
                            ? url
                            : 'https://$url';
                        Navigator.pop(sheetContext, {
                          'platform': platform!,
                          'url': normalized,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(t.translate('save')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isEdit) {
          _socialLinks[index] = result;
        } else {
          _socialLinks.add(result);
        }
      });
      debugPrint('[EditProfile] socialLinks now: $_socialLinks');
    }
  }

  IconData _linkIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.movie;
      case 'linkedin':
        return Icons.business_center;
      case 'github':
        return Icons.code;
      case 'twitter/x':
        return Icons.tag;
      case 'youtube':
        return Icons.smart_display;
      default:
        return Icons.public;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    debugPrint('[EditProfile] _save() start '
        '(baseUrl=${ApiService.baseUrl})');

    final fields = <String, dynamic>{
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
    };
    if (_selectedGender != null) {
      fields['gender'] = _selectedGender == 'female' ? 'Female' : 'Male';
    }
    if (_phoneCtrl.text.trim().isNotEmpty) {
      fields['phone'] = _phoneCtrl.text.trim();
    }
    if (_addressCtrl.text.trim().isNotEmpty) {
      fields['address'] = _addressCtrl.text.trim();
    }
    final dob = _tryParse(_dateOfBirthCtrl.text);
    if (dob != null) {
      fields['date_of_birth'] =
          '${dob.year.toString().padLeft(4, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
    }
    fields['social_media_links'] = _socialLinks;
    debugPrint('[EditProfile] Fields to send: $fields, '
        'newAvatar=${_avatarBytes != null ? '${_avatarBytes!.length} bytes' : 'none'}');

    if (_avatarBytes != null) {
      final result = await ref
          .read(profileProvider.notifier)
          .uploadAvatar(_avatarBytes!, _avatarName ?? 'avatar.png');
      if (result.error != null) {
        debugPrint('[EditProfile] Upload error: ${result.error}');
        if (!mounted) return;
        final t = AppLocalizations.of(context);
        showFloatingSnackBar(
          context,
          message: t.translate(result.error!),
          type: SnackBarType.error,
        );
        return;
      }
      fields['avatar'] = result.id;
      debugPrint('[EditProfile] Avatar uploaded, id=${result.id}');
    }

    if (!mounted) return;
    final msg = await ref.read(profileProvider.notifier).update(fields);
    debugPrint('[EditProfile] update() result: '
        '${msg == null ? 'SUCCESS' : 'FAILED: $msg'}');

    if (!mounted) return;
    final t = AppLocalizations.of(context);
    if (msg == null) {
      showFloatingSnackBar(
        context,
        message: t.translate('profile_updated'),
        type: SnackBarType.success,
      );
      Navigator.pop(context);
    } else {
      showFloatingSnackBar(
        context,
        message: t.translate(msg),
        type: SnackBarType.error,
      );
    }
  }

  String _fmtDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
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
}
