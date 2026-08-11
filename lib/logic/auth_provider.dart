import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/db/repositories/profile_repository.dart';
import 'package:univ_tiaret/services/api_service.dart';
import 'package:univ_tiaret/services/auth_service.dart';
import 'package:univ_tiaret/models/models.dart';

final authProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider();
});

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  pending,
  deviceOccupied,
}

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _error;
  bool _isDisposed = false;

  List<AcademicProgram> _programs = [];
  List<AcademicLevel> _currentLevels = [];
  List<AcademicSpeciality> _currentSpecialities = [];
  bool _loadingLevels = false;
  bool _loadingSpecialities = false;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get error => _error;
  List<AcademicProgram> get programs => _programs;
  List<AcademicLevel> get currentLevels => _currentLevels;
  List<AcademicSpeciality> get currentSpecialities => _currentSpecialities;
  bool get loadingLevels => _loadingLevels;
  bool get loadingSpecialities => _loadingSpecialities;

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // ── Helper: save auth from response ────────────────────────
  Future<bool> _saveAuthFromResponse(Map<String, dynamic> response) async {
    final authData = ApiService.extractAuthData(response);
    final accessToken = authData['accessToken'] as String?;
    final refreshToken = authData['refreshToken'] as String?;
    final userData = authData['user'];

    if (accessToken != null) {
      await AuthService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
      );
      if (userData is Map<String, dynamic>) {
        _user = UserModel.fromJson(userData);
        await AuthService.saveUser(_user!);
      }
      return true;
    }
    return false;
  }

  Future<void> _syncProfileToDb() async {
    if (_user == null) return;
    final data = <String, dynamic>{
      'id': _user!.id,
      'email': _user!.email,
      'first_name': _user!.firstName,
      'last_name': _user!.lastName,
      'gender': _user!.gender,
      'student_id': _user!.studentId,
      'phone': _user!.phone,
      'avatar': _user!.avatar,
      'level_id': _user!.levelId,
      'level_name': _user!.levelName,
      'speciality_id': _user!.specialityId,
      'speciality_name': _user!.specialityName,
      'roles': jsonEncode(_user!.roles),
      'status': _user!.status,
    };
    await ProfileRepository.upsert(data);
  }

  /// Syncs profile edits (name, phone, avatar, ...) back into the auth user
  /// so UI that reads `auth.user` (e.g. settings header) updates immediately.
  Future<void> syncUserFromProfile(Map<String, dynamic> profile) async {
    if (_user == null) return;
    _user = _user!.copyWith(
      firstName: profile['first_name'] as String?,
      lastName: profile['last_name'] as String?,
      gender: profile['gender'] as String?,
      phone: profile['phone'] as String?,
      avatar: profile['avatar'] as String?,
      levelId: profile['level_id'] as int?,
      levelName: profile['level_name'] as String?,
      specialityId: profile['speciality_id'] as int?,
      specialityName: profile['speciality_name'] as String?,
    );
    await AuthService.saveUser(_user!);
    await _syncProfileToDb();
    _safeNotify();
  }

  Future<void> init() async {
    final isAuth = await AuthService.isAuthenticated();
    if (isAuth) {
      _user = await AuthService.getUser();
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }
    _safeNotify();
  }

  // ── Fetch Academic Programs (with nested levels + specialities)
  Future<void> fetchPrograms() async {
    _loadingLevels = true;
    _safeNotify();
    try {
      final response = await ApiService.get(
        '/v1/academic-programs',
        includeAuth: false,
      );
      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          _programs = data.map((e) => AcademicProgram.fromJson(e)).toList();
          _currentLevels = [];
          for (final program in _programs) {
            _currentLevels.addAll(program.levels);
          }
        }
      }
    } catch (e) {
      debugPrint('fetchPrograms error: $e');
    }
    _loadingLevels = false;
    _safeNotify();
  }

  void setSpecialitiesForProgram(int programId) {
    _loadingSpecialities = true;
    _safeNotify();
    final program = _programs.where((p) => p.id == programId).toList();
    if (program.isNotEmpty) {
      _currentSpecialities = program.first.specialities;
    } else {
      _currentSpecialities = [];
    }
    _loadingSpecialities = false;
    _safeNotify();
  }

  // ── Login ──────────────────────────────────────────────────
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _error = null;
    _safeNotify();

    try {
      final fingerprint = await AuthService.getDeviceFingerprint();
      final response = await ApiService.post(
        '/v1/auth/login',
        body: {
          'email': email,
          'password': password,
          'device_fingerprint': fingerprint,
        },
        includeAuth: false,
      );

      if (response['success'] == true) {
        final saved = await _saveAuthFromResponse(response);
        if (saved) {
          await _syncProfileToDb();
          _state = AuthState.authenticated;
          _safeNotify();
          return;
        }
      }

      final userState = AuthService.detectUserState(response);
      if (userState == 'pending') {
        _state = AuthState.pending;
        _error = 'err_account_not_active';
        _safeNotify();
        return;
      }
      if (userState == 'wrong_device') {
        _error = 'err_device_not_recognized';
        _state = AuthState.unauthenticated;
        _safeNotify();
        return;
      }

      _error = 'err_invalid_credentials';
      _state = AuthState.unauthenticated;
      _safeNotify();
    } catch (e) {
      _error = 'err_network';
      _state = AuthState.unauthenticated;
      _safeNotify();
    }
  }

  // ── Register ───────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    int? levelId,
    int? specialityId,
  }) async {
    _state = AuthState.loading;
    _error = null;
    _safeNotify();

    try {
      final fingerprint = await AuthService.getDeviceFingerprint();
      final deviceName = await AuthService.getDeviceName();

      final body = <String, dynamic>{
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender[0].toUpperCase() + gender.substring(1),
        'level_id': levelId,
        'device_fingerprint': fingerprint,
        'device_name': deviceName,
      };
      if (specialityId != null) {
        body['speciality_id'] = specialityId;
      }

      final response = await ApiService.post(
        '/v1/auth/register',
        body: body,
        includeAuth: false,
      );

      if (response['success'] == true) {
        _state = AuthState.pending;
        _error = null;
        _safeNotify();
        return true;
      }

      final userState = AuthService.detectUserState(response);

      if (userState == 'device_occupied') {
        _state = AuthState.deviceOccupied;
        _error = 'err_device_occupied';
        _safeNotify();
        return false;
      }

      if (userState == 'pending') {
        _state = AuthState.pending;
        _error = null;
        _safeNotify();
        return true;
      }

      if (userState == 'active') {
        _state = AuthState.unauthenticated;
        _error = 'err_email_registered';
        _safeNotify();
        return false;
      }

      _error = 'err_registration_failed';
      _state = AuthState.unauthenticated;
      _safeNotify();
      return false;
    } catch (e) {
      _error = 'err_network';
      _state = AuthState.unauthenticated;
      _safeNotify();
      return false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      final refreshToken = await AuthService.getRefreshToken();
      await ApiService.post(
        '/v1/auth/logout',
        body: refreshToken != null ? {'refreshToken': refreshToken} : null,
      );
    } catch (e) {
      debugPrint('logout error: $e');
    }
    await AuthService.clearAuth();
    _user = null;
    _state = AuthState.unauthenticated;
    _safeNotify();
  }

  void clearError() {
    _error = null;
    _safeNotify();
  }
}
