import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

  static const _levelSpecialities = {
    4: {
      4,
      5,
      6,
    }, // M1 → Software Engineering, Cyber Security, Artificial Intelligence
    5: {
      1,
      2,
      3,
      4,
    }, // M2 → Networks & Telecom, IAD, Computer Engineering, Software Engineering
  };

  List<AcademicSpeciality> get _filteredSpecialities {
    final all = _specialitiesForProgram;
    if (_selectedLevelId == null) return all;

    final allowedIds = _levelSpecialities[_selectedLevelId];
    if (allowedIds == null) return all;

    return all.where((s) => allowedIds.contains(s.id)).toList();
  }

  bool get _showSpecialityDropdown {
    return _selectedProgram != null &&
        _selectedProgram!.hasSpecialities &&
        _selectedLevelId != null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final t = AppLocalizations.of(context);
    final genderMap = {
      'male': t.translate('male'),
      'female': t.translate('female'),
    };

    return Scaffold(
      appBar: AppBar(title: Text(t.translate('personal_info'))),
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
                      validator: (v) => v == null || v.isEmpty
                          ? t.translate('required')
                          : null,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: t.translate('first_name'),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Icon(
                            LucideIcons.circleUser,
                            size: 22,
                            color: Theme.of(context).textTheme.bodyLarge!.color!
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: defaultPadding),
                    TextFormField(
                      controller: _lastNameController,
                      validator: (v) => v == null || v.isEmpty
                          ? t.translate('required')
                          : null,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: t.translate('last_name'),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Icon(
                            LucideIcons.circleUser,
                            size: 22,
                            color: Theme.of(context).textTheme.bodyLarge!.color!
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: defaultPadding),
                    _DropdownField<String>(
                      id: 'gender',
                      value: _selectedGender,
                      hint: t.translate('gender'),
                      icon: LucideIcons.venus,
                      items: genderMap.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedGender = v),
                      validator: (v) =>
                          v == null ? t.translate('required') : null,
                    ),
                    const SizedBox(height: defaultPadding),
                    _DropdownField<int>(
                      id: 'program',
                      value: _selectedProgramId,
                      hint: auth.loadingLevels
                          ? t.translate('loading_programs')
                          : t.translate('academic_program'),
                      icon: LucideIcons.backpack,
                      items: auth.programs
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                p.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: auth.loadingLevels
                          ? null
                          : (v) => setState(() {
                              _selectedProgramId = v;
                              _selectedLevelId = null;
                              _selectedSpecialityId = null;
                            }),
                      validator: (v) =>
                          v == null ? t.translate('required') : null,
                    ),
                    const SizedBox(height: defaultPadding),
                    _DropdownField<int>(
                      id: 'level',
                      value: _selectedLevelId,
                      hint: _selectedProgramId == null
                          ? t.translate('select_program_first')
                          : t.translate('level'),
                      icon: LucideIcons.book,
                      items: _levelsForProgram
                          .map(
                            (l) => DropdownMenuItem(
                              value: l.id,
                              child: Text(l.name),
                            ),
                          )
                          .toList(),
                      onChanged: _selectedProgramId == null
                          ? null
                          : (v) => setState(() {
                              _selectedLevelId = v;
                              _selectedSpecialityId = null;
                            }),
                      validator: (v) =>
                          v == null ? t.translate('required') : null,
                    ),
                    if (_showSpecialityDropdown) ...[
                      const SizedBox(height: defaultPadding),
                      _DropdownField<int>(
                        id: 'speciality',
                        value: _selectedSpecialityId,
                        hint: t.translate('speciality'),
                        icon: LucideIcons.book,
                        items: _filteredSpecialities
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  s.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedSpecialityId = v),
                        validator: (v) => v == null
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

class _DropdownField<T> extends StatelessWidget {
  final String id;
  final T? value;
  final String hint;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;

  const _DropdownField({
    required this.id,
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<T>(
      key: ValueKey('$id-$value'),
      initialValue: value,
      hint: Text(
        hint,
        style: TextStyle(
          fontSize: 15,
          color: theme.textTheme.bodyLarge!.color!.withValues(alpha: 0.5),
        ),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.4,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Icon(
            icon,
            size: 24,
            color: theme.textTheme.bodyLarge!.color!.withValues(alpha: 0.3),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
