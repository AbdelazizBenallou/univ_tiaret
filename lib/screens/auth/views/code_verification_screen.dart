import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:univ_tiaret/components/floating_snackbar.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/logic/verification_provider.dart';
import 'package:univ_tiaret/logic/password_provider.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/route/route_constants.dart';

enum _VerifyState { idle, loading, success, error }

class CodeVerificationScreen extends ConsumerStatefulWidget {
  const CodeVerificationScreen({super.key});

  @override
  ConsumerState<CodeVerificationScreen> createState() =>
      _CodeVerificationScreenState();
}

class _CodeVerificationScreenState
    extends ConsumerState<CodeVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 300;
  int _resendAttempts = 0;
  bool _isLocked = false;
  int _wrongAttempts = 0;

  _VerifyState _verifyState = _VerifyState.idle;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      if (args['purpose'] == 'emailVerification') {
        _autoResendCode();
      }
    });
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 300;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String get _formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (index == 5 && value.isNotEmpty) {
      _submitCode();
    }
  }

  Future<void> _submitCode() async {
    final t = AppLocalizations.of(context);
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) return;

    setState(() => _verifyState = _VerifyState.loading);

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final email = args['email'] as String;
    final purpose = args['purpose'] as String;

    if (purpose == 'emailVerification') {
      final verified = await ref
          .read(verificationProvider.notifier)
          .verifyEmail(email: email, code: code);
      if (verified) {
        _showSuccess();
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            logInScreenRoute,
            (route) => false,
          );
        });
      } else {
        _wrongAttempts++;
        if (_wrongAttempts >= 3) {
          _isLocked = true;
          _startLockoutTimer();
          _wrongAttempts = 0;
        }
        final errorMsg =
            ref.read(verificationProvider).error;
        showFloatingSnackBar(
          context,
          message: errorMsg != null ? t.translate(errorMsg) : t.translate('err_verification_failed'),
          type: SnackBarType.error,
        );
        _showError();
      }
    } else if (purpose == 'passwordReset') {
      final verified = await ref
          .read(passwordProvider.notifier)
          .verifyResetCode(email: email, code: code);
      if (verified) {
        final token = ref.read(passwordProvider).resetToken;
        if (!mounted) return;
        _showSuccess();
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          if (!context.mounted) return;
          Navigator.pushNamed(
            context,
            resetPasswordScreenRoute,
            arguments: {'token': token},
          );
        });
      } else {
        final errorMsg =
            ref.read(passwordProvider).error;
        showFloatingSnackBar(
          context,
          message: errorMsg != null ? t.translate(errorMsg) : t.translate('err_invalid_code'),
          type: SnackBarType.error,
        );
        _showError();
      }
    }
  }

  void _showSuccess() {
    setState(() => _verifyState = _VerifyState.success);
    _animController.forward(from: 0);
  }

  void _showError() {
    setState(() => _verifyState = _VerifyState.error);
    _animController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _verifyState = _VerifyState.idle;
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      });
    });
  }

  Future<void> _autoResendCode() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final email = args['email'] as String;
    await ref.read(verificationProvider.notifier).resendCode(email);
    _startTimer();
  }

  void _resendCode() async {
    if (_isLocked || _resendAttempts >= 3) return;

    final t = AppLocalizations.of(context);
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final email = args['email'] as String;

    _resendAttempts++;

    final result = await ref.read(verificationProvider.notifier).resendCode(email);

    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    _startTimer();

    if (result) {
      showFloatingSnackBar(
        context,
        message: t.translate('code_resent'),
        type: SnackBarType.success,
      );
    } else {
      final error = ref.read(verificationProvider).error;
      showFloatingSnackBar(
        context,
        message: error != null ? t.translate(error) : t.translate('err_failed_to_resend_code'),
        type: SnackBarType.error,
      );
    }

    if (_resendAttempts >= 3) {
      _isLocked = true;
      _startLockoutTimer();
    }
  }

  void _startLockoutTimer() {
    _secondsRemaining = 300;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _isLocked = false;
        _resendAttempts = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.maybePop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                logInScreenRoute,
                (route) => false,
              );
            }
          },
          icon: Icon(
            LucideIcons.arrowLeft,
            size: 24,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
        title: Text(t.translate('verification')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('enter_code'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              t.translate('code_subtitle'),
            ),
            const SizedBox(height: defaultPadding * 2),

            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _verifyState == _VerifyState.loading
                    ? SizedBox(
                        key: const ValueKey('loading'),
                        height: 64,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              t.translate('verifying'),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _verifyState == _VerifyState.success
                        ? ScaleTransition(
                            key: const ValueKey('success'),
                            scale: _scaleAnim,
                            child: SizedBox(
                              height: 64,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: successColor,
                                      shape: BoxShape.circle,
                                    ),
                                        child: Icon(
                                          LucideIcons.checkCircle,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                  Text(
                                    t.translate('verified'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: successColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _verifyState == _VerifyState.error
                            ? ScaleTransition(
                                key: const ValueKey('error'),
                                scale: _scaleAnim,
                                child: SizedBox(
                                  height: 64,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          color: errorColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          LucideIcons.x,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        t.translate('invalid_code'),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: errorColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Directionality(
                                textDirection: TextDirection.ltr,
                                child: Row(
                                  key: const ValueKey('fields'),
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(6, (index) {
                                  return SizedBox(
                                    width: 48,
                                    height: 56,
                                    child: TextFormField(
                                      controller: _controllers[index],
                                      focusNode: _focusNodes[index],
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      maxLength: 1,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: InputDecoration(
                                        counterText: '',
                                        contentPadding: EdgeInsets.zero,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(defaultBorderRadious),
                                          borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.grey),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(defaultBorderRadious),
                                          borderSide: BorderSide(color: (Theme.of(context).dividerTheme.color ?? Colors.grey).withValues(alpha: 0.5)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(defaultBorderRadious),
                                          borderSide: const BorderSide(color: primaryColor, width: 2),
                                        ),
                                      ),
                                      onChanged: (value) =>
                                          _onCodeChanged(index, value),
                                    ),
                                  );
                                }),
                                ),
                              ),
              ),
            ),

            const SizedBox(height: defaultPadding),
            Center(
              child: _isLocked
                  ? Text(
                      "${t.translate('locked')} $_formattedTime",
                      style: const TextStyle(color: errorColor),
                    )
                  : Text(
                      _secondsRemaining > 0
                          ? "${t.translate('resend_code_in')} $_formattedTime"
                          : t.translate('didnt_receive'),
                    ),
            ),
            const SizedBox(height: defaultPadding),
            if (!_isLocked && _secondsRemaining == 0)
              Center(
                child: TextButton(
                  onPressed: _resendCode,
                  child: Text(t.translate('resend_code')),
                ),
              ),
            const SizedBox(height: defaultPadding * 2),
            ElevatedButton(
              onPressed: (_verifyState == _VerifyState.loading ||
                      _verifyState == _VerifyState.success)
                  ? null
                  : _submitCode,
              child: _verifyState == _VerifyState.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(t.translate('verify')),
            ),
          ],
        ),
      ),
    );
  }
}
