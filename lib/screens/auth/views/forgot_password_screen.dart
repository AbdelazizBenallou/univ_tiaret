import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/floating_snackbar.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/logic/password_provider.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/route/route_constants.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    final t = AppLocalizations.of(context);

    setState(() => _isLoading = true);

    final success = await ref
        .read(passwordProvider.notifier)
        .forgotPassword(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      showFloatingSnackBar(
        context,
        message: t.translate('code_sent'),
        type: SnackBarType.success,
      );
      Navigator.pushNamed(
        context,
        codeVerificationScreenRoute,
        arguments: {
          'email': _emailController.text.trim(),
          'purpose': 'passwordReset',
        },
      );
    } else {
      final error = ref.read(passwordProvider).error;
      showFloatingSnackBar(
        context,
        message: error != null ? t.translate(error) : t.translate('err_failed_to_send_reset_code'),
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('forgot_password_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('reset_password'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              t.translate('forgot_subtitle'),
            ),
            const SizedBox(height: defaultPadding * 2),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailController,
                validator: emailValidator(t.translate('email_required'), t.translate('email_invalid')).call,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: t.translate('email'),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 2),
                    child: SvgPicture.asset(
                      "assets/icons/Message.svg",
                      height: 22,
                      width: 22,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .color!
                            .withValues(alpha: 0.3),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: defaultPadding * 2),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendCode,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(t.translate('send_code')),
            ),
          ],
        ),
      ),
    );
  }
}
