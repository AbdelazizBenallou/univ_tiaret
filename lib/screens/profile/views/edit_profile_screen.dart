import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/subscription_guard.dart';
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
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider).profile;
    _firstNameCtrl = TextEditingController(text: p?['first_name'] ?? '');
    _lastNameCtrl = TextEditingController(text: p?['last_name'] ?? '');
    _phoneCtrl = TextEditingController(text: p?['phone'] ?? '');
    _addressCtrl = TextEditingController(text: p?['address'] ?? '');
    _dateOfBirthCtrl = TextEditingController(text: _fmtDate(p?['date_of_birth']));
    _selectedGender = p?['gender'];
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _dateOfBirthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.translate('edit_profile'))),
      body: SubscriptionGuard(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              const SizedBox(height: 8),
              _SectionCard(
                isDark: isDark,
                title: t.translate('personal_details'),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: TextFormField(
                      controller: _firstNameCtrl,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      decoration: const InputDecoration(hintText: 'First Name'),
                    ),
                  ),
                  _divider(isDark),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: TextFormField(
                      controller: _lastNameCtrl,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      decoration: const InputDecoration(hintText: 'Last Name'),
                    ),
                  ),
                  _divider(isDark),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: 'Phone'),
                    ),
                  ),
                  _divider(isDark),
                  _GenderSelector(
                    selectedGender: _selectedGender,
                    isDark: isDark,
                    colors: colors,
                    t: t,
                    onChanged: (v) => setState(() => _selectedGender = v),
                  ),
                  _divider(isDark),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: TextFormField(
                      controller: _dateOfBirthCtrl,
                      decoration: const InputDecoration(hintText: 'Date of Birth'),
                    ),
                  ),
                  _divider(isDark),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(hintText: 'Address'),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.saving ? null : _save,
                  child: state.saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(t.translate('save_changes')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final fields = <String, dynamic>{
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
    };
    if (_phoneCtrl.text.trim().isNotEmpty) fields['phone'] = _phoneCtrl.text.trim();
    if (_addressCtrl.text.trim().isNotEmpty) fields['address'] = _addressCtrl.text.trim();
    if (_dateOfBirthCtrl.text.trim().isNotEmpty) fields['date_of_birth'] = _dateOfBirthCtrl.text.trim();
    if (_selectedGender != null) fields['gender'] = _selectedGender;

    final msg = await ref.read(profileProvider.notifier).update(fields);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg ?? AppLocalizations.of(context).translate('profile_updated'))),
      );
      if (msg == null) Navigator.pop(context);
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

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.isDark, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
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
        ),
      ],
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final String? selectedGender;
  final bool isDark;
  final ColorScheme colors;
  final AppLocalizations t;
  final ValueChanged<String> onChanged;

  const _GenderSelector({
    required this.selectedGender,
    required this.isDark,
    required this.colors,
    required this.t,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = ['Male', 'Female'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.greenLight, AppColors.greenAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.wc_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          ...options.map((g) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(g, style: TextStyle(fontSize: 13, color: selectedGender == g ? Colors.white : colors.onSurface)),
              selected: selectedGender == g,
              onSelected: (v) => onChanged(g),
              selectedColor: AppColors.greenAccent,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          )),
        ],
      ),
    );
  }
}
