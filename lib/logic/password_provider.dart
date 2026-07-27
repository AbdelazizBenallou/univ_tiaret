import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/services/api_service.dart';

final passwordProvider = ChangeNotifierProvider<PasswordProvider>((ref) {
  return PasswordProvider();
});

enum PasswordState { initial, loading, success, error }

class PasswordProvider extends ChangeNotifier {
  PasswordState _state = PasswordState.initial;
  String? _error;
  String? _resetToken;
  bool _isDisposed = false;

  PasswordState get state => _state;
  String? get error => _error;
  String? get resetToken => _resetToken;

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void clearError() {
    _error = null;
    _safeNotify();
  }

  // ── Forgot Password ────────────────────────────────────────
  Future<bool> forgotPassword(String email) async {
    _state = PasswordState.loading;
    _error = null;
    _safeNotify();

    try {
      final response = await ApiService.post(
        '/v1/auth/forgot-password',
        body: {'email': email},
        includeAuth: false,
      );

      if (response['success'] == true) {
        _state = PasswordState.initial;
        _error = null;
        _safeNotify();
        return true;
      }

      _error = 'err_failed_to_send_reset_code';
      _state = PasswordState.error;
      _safeNotify();
      return false;
    } catch (e) {
      _error = 'err_network';
      _state = PasswordState.error;
      _safeNotify();
      return false;
    }
  }

  // ── Verify Reset Code ──────────────────────────────────────
  Future<bool> verifyResetCode({
    required String email,
    required String code,
  }) async {
    _state = PasswordState.loading;
    _error = null;
    _safeNotify();

    try {
      final response = await ApiService.post(
        '/v1/auth/verify-reset-code',
        body: {'email': email, 'code': code},
        includeAuth: false,
      );

      if (response['success'] == true) {
        final data = response['data'];
        _resetToken = data?['resetToken'] as String?;
        _state = PasswordState.initial;
        _error = null;
        _safeNotify();
        return true;
      }

      _error = 'err_invalid_code';
      _state = PasswordState.error;
      _safeNotify();
      return false;
    } catch (e) {
      _error = 'err_network';
      _state = PasswordState.error;
      _safeNotify();
      return false;
    }
  }

  // ── Reset Password (with token from verify-reset-code) ─────
  Future<bool> resetPassword({
    required String password,
  }) async {
    if (_resetToken == null) {
      _error = 'err_no_reset_token';
      _safeNotify();
      return false;
    }

    _state = PasswordState.loading;
    _error = null;
    _safeNotify();

    try {
      final response = await ApiService.post(
        '/v1/auth/reset-password',
        body: {'token': _resetToken, 'password': password},
        includeAuth: false,
      );

      if (response['success'] == true) {
        _resetToken = null;
        _state = PasswordState.success;
        _error = null;
        _safeNotify();
        return true;
      }

      _error = 'err_reset_failed';
      _state = PasswordState.error;
      _safeNotify();
      return false;
    } catch (e) {
      _error = 'err_network';
      _state = PasswordState.error;
      _safeNotify();
      return false;
    }
  }

  // ── Change Password (from Settings) ────────────────────────
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _state = PasswordState.loading;
    _error = null;
    _safeNotify();

    try {
      final response = await ApiService.post(
        '/v1/auth/change-password',
        body: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );

      if (response['success'] == true) {
        _state = PasswordState.success;
        _error = null;
        _safeNotify();
        return true;
      }

      _error = 'err_change_password_failed';
      _state = PasswordState.error;
      _safeNotify();
      return false;
    } catch (e) {
      _error = 'err_network';
      _state = PasswordState.error;
      _safeNotify();
      return false;
    }
  }
}
