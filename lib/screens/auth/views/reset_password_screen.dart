import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/floating_snackbar.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/password_provider.dart';
import 'package:univ_tiaret/route/route_constants.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(passwordProvider.notifier).resetPassword(
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      showFloatingSnackBar(
        context,
        message: AppLocalizations.of(context).translate('password_reset_success'),
        type: SnackBarType.success,
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        logInScreenRoute,
        (route) => false,
      );
    } else {
      final t = AppLocalizations.of(context);
      final error = ref.read(passwordProvider).error;
      showFloatingSnackBar(
        context,
        message: error != null ? t.translate(error) : t.translate('err_reset_failed'),
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pw = ref.watch(passwordProvider);
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('reset_password')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('new_password'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              t.translate('new_password_subtitle'),
            ),
            const SizedBox(height: defaultPadding * 2),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _passwordController,
                    validator: passwordValidator(
                      t.translate('password_required'),
                      t.translate('password_min'),
                      t.translate('password_upper'),
                      t.translate('password_lower'),
                      t.translate('password_number'),
                      t.translate('password_special'),
                    ).call,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: t.translate('new_password'),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 22,
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .color!
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: defaultPadding),
                  TextFormField(
                    controller: _confirmPasswordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return t.translate('confirm_password_hint');
                      }
                      if (value != _passwordController.text) {
                        return t.translate('passwords_no_match');
                      }
                      return null;
                    },
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: t.translate('confirm_password'),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 24,
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .color!
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: defaultPadding * 2),
            ElevatedButton(
              onPressed: pw.state == PasswordState.loading
                  ? null
                  : _resetPassword,
              child: pw.state == PasswordState.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(t.translate('reset_password')),
            ),
          ],
        ),
      ),
    );
  }
}
