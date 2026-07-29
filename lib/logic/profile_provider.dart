import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/db/db.dart';
import 'package:univ_tiaret/logic/auth_provider.dart';

final profileProvider = ChangeNotifierProvider<ProfileProvider>((ref) {
  return ProfileProvider(ref);
});

class ProfileProvider extends ChangeNotifier {
  final Ref _ref;
  Map<String, dynamic>? _profile;
  bool _loading = false;
  String? _error;

  ProfileProvider(this._ref);

  Map<String, dynamic>? get profile => _profile;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final stored = await ProfileRepository.get();
    final authUser = _ref.read(authProvider).user;

    if (stored != null) {
      _profile = stored;
      _loading = false;
      notifyListeners();
      return;
    }

    if (authUser != null) {
      final data = <String, dynamic>{
        'id': authUser.id,
        'email': authUser.email,
        'first_name': authUser.firstName,
        'last_name': authUser.lastName,
        'gender': authUser.gender,
        'student_id': authUser.studentId,
        'phone': authUser.phone,
        'level_id': authUser.levelId,
        'level_name': authUser.levelName,
        'speciality_id': authUser.specialityId,
        'speciality_name': authUser.specialityName,
        'roles': authUser.roles,
        'status': authUser.status,
      };
      await ProfileRepository.upsert(data);
      _profile = data;
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> update({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (phone != null) updates['phone'] = phone;

    if (updates.isEmpty) return;

    await ProfileRepository.updateFields(updates);
    if (_profile != null) {
      _profile!.addAll(updates);
    }
    notifyListeners();
  }

  Future<void> syncFromAuth() async {
    final authUser = _ref.read(authProvider).user;
    if (authUser == null) return;
    final data = <String, dynamic>{
      'id': authUser.id,
      'email': authUser.email,
      'first_name': authUser.firstName,
      'last_name': authUser.lastName,
      'gender': authUser.gender,
      'student_id': authUser.studentId,
      'phone': authUser.phone,
      'level_id': authUser.levelId,
      'level_name': authUser.levelName,
      'speciality_id': authUser.specialityId,
      'speciality_name': authUser.specialityName,
      'roles': authUser.roles,
      'status': authUser.status,
    };
    await ProfileRepository.upsert(data);
    _profile = data;
    notifyListeners();
  }
}
