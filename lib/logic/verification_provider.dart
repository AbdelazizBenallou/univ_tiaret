import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/services/api_service.dart';

final verificationProvider = ChangeNotifierProvider<VerificationProvider>((ref) {
  return VerificationProvider();
});

enum VerificationState { initial, loading, success, error }

class VerificationProvider extends ChangeNotifier {
  VerificationState _state = VerificationState.initial;
  String? _error;
  bool _isDisposed = false;

  VerificationState get state => _state;
  String? get error => _error;

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

  // ── Verify Email ───────────────────────────────────────────
  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    _state = VerificationState.loading;
    _error = null;
    _safeNotify();

    try {
      final response = await ApiService.post(
        '/v1/auth/verify-email',
        body: {'email': email, 'code': code},
        includeAuth: false,
      );

      if (response['success'] == true) {
        _state = VerificationState.success;
        _error = null;
        _safeNotify();
        return true;
      }

      _error = 'err_verification_failed';
      _state = VerificationState.error;
      _safeNotify();
      return false;
    } catch (e) {
      _error = 'err_network';
      _state = VerificationState.error;
      _safeNotify();
      return false;
    }
  }

  // ── Resend Code ────────────────────────────────────────────
  Future<bool> resendCode(String email) async {
    _state = VerificationState.loading;
    _error = null;
    _safeNotify();

    try {
      final response = await ApiService.post(
        '/v1/auth/resend-code',
        body: {'email': email},
        includeAuth: false,
      );

      if (response['success'] == true) {
        _state = VerificationState.initial;
        _error = null;
        _safeNotify();
        return true;
      }

      _error = 'err_failed_to_resend_code';
      _state = VerificationState.error;
      _safeNotify();
      return false;
    } catch (e) {
      _error = 'err_network';
      _state = VerificationState.error;
      _safeNotify();
      return false;
    }
  }
}
