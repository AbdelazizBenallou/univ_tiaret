import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/floating_snackbar.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/logic/auth_provider.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/route/route_constants.dart';

class RegisterAccountScreen extends ConsumerStatefulWidget {
  const RegisterAccountScreen({super.key});

  @override
  ConsumerState<RegisterAccountScreen> createState() =>
      _RegisterAccountScreenState();
}

class _RegisterAccountScreenState extends ConsumerState<RegisterAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register(String firstName, String lastName, String gender,
      int? levelId, int? specialityId) async {
    final t = AppLocalizations.of(context);
    await ref.read(authProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: firstName,
          lastName: lastName,
          gender: gender,
          levelId: levelId,
          specialityId: specialityId,
        );

    if (!mounted) return;

    final auth = ref.read(authProvider);

    switch (auth.state) {
      case AuthState.pending:
        Navigator.pushNamedAndRemoveUntil(
          context,
          codeVerificationScreenRoute,
          (route) => false,
          arguments: {
            'email': _emailController.text.trim(),
            'purpose': 'emailVerification',
          },
        );
        break;
      case AuthState.authenticated:
        Navigator.pushNamedAndRemoveUntil(
          context,
          entryPointScreenRoute,
          (route) => false,
        );
        break;
      default:
        if (auth.error != null) {
          final type = auth.state == AuthState.deviceOccupied
              ? SnackBarType.warning
              : SnackBarType.error;
          showFloatingSnackBar(
            context,
            message: t.translate(auth.error!),
            type: type,
            duration: auth.state == AuthState.deviceOccupied
                ? const Duration(seconds: 5)
                : const Duration(seconds: 3),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final t = AppLocalizations.of(context);
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final firstName = args['firstName'] as String;
    final lastName = args['lastName'] as String;
    final gender = args['gender'] as String;
    final levelId = args['levelId'] as int?;
    final specialityId = args['specialityId'] as int?;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('account_info')),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.translate('create_account'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: defaultPadding / 2),
              Text(t.translate('register_subtitle2')),
              const SizedBox(height: defaultPadding * 2),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      validator: emailValidator(t.translate('email_required'), t.translate('email_invalid')).call,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
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
                    const SizedBox(height: defaultPadding),
                    TextFormField(
                      controller: _passwordController,
                      validator: passwordValidator(t.translate('password_required'), t.translate('password_min'), t.translate('password_special')).call,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: t.translate('password'),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 2),
                          child: SvgPicture.asset(
                            "assets/icons/Lock.svg",
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
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .color!
                                .withValues(alpha: 0.4),
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
                          child: SvgPicture.asset(
                            "assets/icons/Lock.svg",
                            height: 24,
                            width: 24,
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
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .color!
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: defaultPadding * 2),
              ElevatedButton(
                onPressed: auth.state == AuthState.loading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _register(firstName, lastName, gender, levelId, specialityId);
                        }
                      },
                child: auth.state == AuthState.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(t.translate('sign_up')),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t.translate('has_account')),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, logInScreenRoute);
                    },
                    child: Text(t.translate('login')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
