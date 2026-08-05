import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/floating_snackbar.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/profile_provider.dart';

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

  String get _initials {
    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    final f = first.isNotEmpty ? first[0] : '';
    final l = last.isNotEmpty ? last[0] : '';
    final s = '$f$l'.toUpperCase();
    return s.isNotEmpty ? s : '?';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(t.translate('edit_profile'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            _buildHeader(t, isDark),
            const SizedBox(height: 20),
            _sectionLabel(t.translate('personal_details')),
            const SizedBox(height: 12),
            _field(
              controller: _firstNameCtrl,
              hint: t.translate('first_name'),
              icon: Icons.person_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.trim().isEmpty
                  ? t.translate('required')
                  : null,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _lastNameCtrl,
              hint: t.translate('last_name'),
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.trim().isEmpty
                  ? t.translate('required')
                  : null,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _phoneCtrl,
              hint: t.translate('phone_number'),
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _dateOfBirthCtrl,
              hint: t.translate('date_of_birth'),
              icon: Icons.cake_rounded,
              readOnly: true,
              onTap: _pickDate,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_month_rounded),
                onPressed: _pickDate,
              ),
            ),
            const SizedBox(height: 16),
            _field(
              controller: _genderCtrl,
              hint: t.translate('gender_label'),
              icon: Icons.wc_rounded,
              readOnly: true,
              onTap: _pickGender,
              suffixIcon: const Icon(Icons.expand_more_rounded),
            ),
            const SizedBox(height: 16),
            _field(
              controller: _addressCtrl,
              hint: t.translate('address'),
              icon: Icons.home_rounded,
              maxLines: 2,
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
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryColor),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildHeader(AppLocalizations t, bool isDark) {
    final email = ref.read(profileProvider).profile?['email'];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.secondaryColor.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
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
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: 2,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (email != null) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
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
                  ? const Icon(Icons.check_rounded, color: AppColors.primaryColor)
                  : null,
              onTap: () => Navigator.pop(context, 'male'),
            ),
            ListTile(
              title: Text(t.translate('female')),
              trailing: _selectedGender == 'female'
                  ? const Icon(Icons.check_rounded, color: AppColors.primaryColor)
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final fields = <String, dynamic>{
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'gender': _selectedGender,
    };
    if (_phoneCtrl.text.trim().isNotEmpty) {
      fields['phone'] = _phoneCtrl.text.trim();
    }
    if (_addressCtrl.text.trim().isNotEmpty) {
      fields['address'] = _addressCtrl.text.trim();
    }
    if (_dateOfBirthCtrl.text.trim().isNotEmpty) {
      fields['date_of_birth'] = _dateOfBirthCtrl.text.trim();
    }

    final msg = await ref.read(profileProvider.notifier).update(fields);

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
      showFloatingSnackBar(context, message: msg, type: SnackBarType.error);
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
}
