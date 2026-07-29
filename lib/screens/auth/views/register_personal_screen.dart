import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/bottom_sheet_selector.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/logic/auth_provider.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/models/models.dart';
import 'package:univ_tiaret/route/route_constants.dart';

class RegisterPersonalScreen extends ConsumerStatefulWidget {
  const RegisterPersonalScreen({super.key});

  @override
  ConsumerState<RegisterPersonalScreen> createState() =>
      _RegisterPersonalScreenState();
}

class _RegisterPersonalScreenState
    extends ConsumerState<RegisterPersonalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  int? _selectedProgramId;
  int? _selectedLevelId;
  int? _selectedSpecialityId;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    ref.read(authProvider.notifier).fetchPrograms();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  AcademicProgram? get _selectedProgram {
    if (_selectedProgramId == null) return null;
    final auth = ref.read(authProvider);
    for (final program in auth.programs) {
      if (program.id == _selectedProgramId) return program;
    }
    return null;
  }

  List<AcademicLevel> get _levelsForProgram {
    return _selectedProgram?.levels ?? [];
  }

  List<AcademicSpeciality> get _specialitiesForProgram {
    return _selectedProgram?.specialities ?? [];
  }

  List<AcademicSpeciality> get _filteredSpecialities {
    final all = _specialitiesForProgram;
    if (_selectedLevelId == null) return all;

    final level = _levelsForProgram.firstWhere(
      (l) => l.id == _selectedLevelId,
      orElse: () => AcademicLevel(id: 0, name: ''),
    );
    final levelName = level.name.toLowerCase();

    if (levelName.contains('m1') || levelName.contains('master 1')) {
      return all.where((s) {
        final n = s.name.toLowerCase();
        return n.contains('ai') ||
            n.contains('cyber') ||
            n.contains('security') ||
            n.contains('software');
      }).toList();
    }

    if (levelName.contains('m2') || levelName.contains('master 2')) {
      return all.where((s) {
        final n = s.name.toLowerCase();
        return n.contains('software') ||
            n.contains('network') ||
            n.contains('telecom') ||
            n.contains('computer') ||
            n.contains('ai');
      }).toList();
    }

    return all;
  }

  bool get _showSpecialityDropdown {
    return _selectedProgram != null && _selectedProgram!.hasSpecialities &&
        _selectedLevelId != null;
  }

  Future<void> _pickGender() async {
    final t = AppLocalizations.of(context);
    final genderMap = {
      'male': t.translate('male'),
      'female': t.translate('female'),
    };
    final result = await showBottomSheetSelector<String>(
      context: context,
      items: genderMap.keys.toList(),
      title: t.translate('select_gender'),
      hintText: t.translate('search_gender'),
      leadingIcon: Icons.wc_rounded,
      selectedName: _selectedGender != null ? genderMap[_selectedGender] : null,
      itemLabelBuilder: (g) => genderMap[g] ?? g,
    );
    if (result != null) setState(() => _selectedGender = result);
  }

  Future<void> _pickProgram() async {
    final t = AppLocalizations.of(context);
    final auth = ref.read(authProvider);
    if (auth.programs.isEmpty) return;
    final result = await showBottomSheetSelector<AcademicProgram>(
      context: context,
      items: auth.programs,
      title: t.translate('academic_program'),
      hintText: t.translate('search_programs'),
      leadingIcon: Icons.backpack_rounded,
      selectedName: _selectedProgram?.name,
      itemLabelBuilder: (p) => p.name,
    );
    if (result != null) {
      setState(() {
        _selectedProgramId = result.id;
        _selectedLevelId = null;
        _selectedSpecialityId = null;
      });
    }
  }

  Future<void> _pickLevel() async {
    final t = AppLocalizations.of(context);
    final levels = _levelsForProgram;
    if (levels.isEmpty) return;
    final result = await showBottomSheetSelector<AcademicLevel>(
      context: context,
      items: levels,
      title: t.translate('select_level'),
      hintText: t.translate('search_levels'),
      leadingIcon: Icons.book_rounded,
      selectedName: _selectedLevelId != null
          ? levels
              .where((l) => l.id == _selectedLevelId)
              .firstOrNull
              ?.name
          : null,
      itemLabelBuilder: (l) => l.name,
    );
    if (result != null) {
      setState(() {
        _selectedLevelId = result.id;
        _selectedSpecialityId = null;
      });
    }
  }

  Future<void> _pickSpeciality() async {
    final t = AppLocalizations.of(context);
    final specialities = _filteredSpecialities;
    if (specialities.isEmpty) return;
    final result = await showBottomSheetSelector<AcademicSpeciality>(
      context: context,
      items: specialities,
      title: t.translate('select_speciality'),
      hintText: t.translate('search_specialities'),
      leadingIcon: Icons.book_rounded,
      selectedName: _selectedSpecialityId != null
          ? specialities
              .where((s) => s.id == _selectedSpecialityId)
              .firstOrNull
              ?.name
          : null,
      itemLabelBuilder: (s) => s.name,
    );
    if (result != null) {
      setState(() => _selectedSpecialityId = result.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('personal_info')),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.translate('tell_us'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: defaultPadding / 2),
              Text(t.translate('register_subtitle')),
              const SizedBox(height: defaultPadding * 2),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _firstNameController,
                      validator: (v) =>
                          v == null || v.isEmpty ? t.translate('required') : null,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: t.translate('first_name'),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 2),
                          child: Icon(
                            Icons.account_circle_rounded,
                            size: 22,
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .color!
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: defaultPadding),
                    TextFormField(
                      controller: _lastNameController,
                      validator: (v) =>
                          v == null || v.isEmpty ? t.translate('required') : null,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: t.translate('last_name'),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 2),
                          child: Icon(
                            Icons.account_circle_rounded,
                            size: 22,
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .color!
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: defaultPadding),
                    _SelectorField(
                      label: _selectedGender != null ? t.translate(_selectedGender!) : t.translate('gender'),
                      isSelected: _selectedGender != null,
                      icon: Icons.wc_rounded,
                      onTap: _pickGender,
                      validator: (v) =>
                          _selectedGender == null ? t.translate('required') : null,
                    ),
                    const SizedBox(height: defaultPadding),
                    _SelectorField(
                      label: auth.loadingLevels
                          ? t.translate('loading_programs')
                          : (_selectedProgram?.name ?? t.translate('academic_program')),
                      isSelected: _selectedProgramId != null,
                      icon: Icons.backpack_rounded,
                      onTap: auth.loadingLevels ? null : _pickProgram,
                      validator: (v) =>
                          _selectedProgramId == null ? t.translate('required') : null,
                    ),
                    const SizedBox(height: defaultPadding),
                    _SelectorField(
                      label: _selectedLevelId != null
                          ? _levelsForProgram
                              .where((l) => l.id == _selectedLevelId)
                              .firstOrNull
                              ?.name ??
                              t.translate('level')
                          : (_selectedProgramId == null
                              ? t.translate('select_program_first')
                              : t.translate('level')),
                      isSelected: _selectedLevelId != null,
                      icon: Icons.book_rounded,
                      onTap: _selectedProgramId != null ? _pickLevel : null,
                      validator: (v) =>
                          _selectedLevelId == null ? t.translate('required') : null,
                    ),
                    if (_showSpecialityDropdown) ...[
                      const SizedBox(height: defaultPadding),
                      _SelectorField(
                        label: _selectedSpecialityId != null
                            ? _filteredSpecialities
                                .where((s) => s.id == _selectedSpecialityId)
                                .firstOrNull
                                ?.name ??
                                t.translate('speciality')
                            : t.translate('speciality'),
                        isSelected: _selectedSpecialityId != null,
                        icon: Icons.book_rounded,
                        onTap: _pickSpeciality,
                        validator: (v) =>
                            _selectedSpecialityId == null
                                ? t.translate('required_for_master')
                                : null,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: defaultPadding * 2),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pushNamed(
                      context,
                      registerAccountScreenRoute,
                      arguments: {
                        'firstName': _firstNameController.text.trim(),
                        'lastName': _lastNameController.text.trim(),
                        'gender': _selectedGender,
                        'levelId': _selectedLevelId,
                        'specialityId': _selectedSpecialityId,
                      },
                    );
                  }
                },
                child: Text(t.translate('continue_btn')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorField extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  const _SelectorField({
    required this.label,
    required this.isSelected,
    required this.icon,
    this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHint = !isSelected;

    return FormField<String>(
      validator: validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTap,
              child: InputDecorator(
                decoration: InputDecoration(
                  errorText: field.errorText,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: defaultPadding * 0.25),
                    child: Icon(
                      icon,
                      size: 24,
                      color: theme.textTheme.bodyLarge!.color!.withValues(alpha: 0.3),
                    ),
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: theme.textTheme.bodyLarge!.color!.withValues(alpha: 0.4), size: 22),
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(maxHeight: 24, maxWidth: 36),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: isHint
                        ? theme.textTheme.bodyLarge!.color!.withValues(alpha: 0.5)
                        : theme.textTheme.bodyLarge!.color,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
