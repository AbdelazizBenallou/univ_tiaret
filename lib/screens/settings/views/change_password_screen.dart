import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/floating_snackbar.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/password_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(passwordProvider.notifier).changePassword(
          oldPassword: _oldPasswordController.text,
          newPassword: _newPasswordController.text,
        );

    if (!mounted) return;

    final t = AppLocalizations.of(context);

    if (success) {
      showFloatingSnackBar(
        context,
        message: t.translate('password_changed'),
        type: SnackBarType.success,
      );
      Navigator.pop(context);
    } else {
      final error =
          ref.read(passwordProvider).error;
      showFloatingSnackBar(
        context,
        message: error != null ? t.translate(error) : t.translate('err_change_password_failed'),
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final pw = ref.watch(passwordProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('change_password')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('change_password'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              t.translate('change_subtitle'),
            ),
            const SizedBox(height: defaultPadding * 2),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _oldPasswordController,
                    validator: (v) =>
                        v == null || v.isEmpty ? t.translate('current_password_required') : null,
                    obscureText: _obscureOld,
                    decoration: InputDecoration(
                      hintText: t.translate('current_password'),
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
                          setState(() => _obscureOld = !_obscureOld);
                        },
                        icon: Icon(
                          _obscureOld
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: defaultPadding),
                  TextFormField(
                    controller: _newPasswordController,
                    validator: passwordValidator(
                      t.translate('password_required'),
                      t.translate('password_min'),
                      t.translate('password_upper'),
                      t.translate('password_lower'),
                      t.translate('password_number'),
                      t.translate('password_special'),
                    ).call,
                    obscureText: _obscureNew,
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
                          setState(() => _obscureNew = !_obscureNew);
                        },
                        icon: Icon(
                          _obscureNew
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
                      if (value != _newPasswordController.text) {
                        return t.translate('passwords_no_match');
                      }
                      return null;
                    },
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      hintText: t.translate('confirm_new_password'),
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
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                        icon: Icon(
                          _obscureConfirm
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
              onPressed: pw.state == PasswordState.loading ? null : _submit,
              child: pw.state == PasswordState.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(t.translate('change_password')),
            ),
          ],
        ),
      ),
    );
  }
}
