import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/server_config_dialog.dart';
import 'package:univ_tiaret/components/floating_snackbar.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/logic/auth_provider.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/route/route_constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final t = AppLocalizations.of(context);

    await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    final auth = ref.read(authProvider);

    switch (auth.state) {
      case AuthState.authenticated:
        Navigator.pushNamedAndRemoveUntil(
          context,
          entryPointScreenRoute,
          (route) => false,
        );
        break;
      case AuthState.pending:
        Navigator.pushNamed(
          context,
          codeVerificationScreenRoute,
          arguments: {
            'email': _emailController.text.trim(),
            'purpose': 'emailVerification',
          },
        );
        break;
      default:
        if (auth.error != null) {
          showFloatingSnackBar(
            context,
            message: t.translate(auth.error!),
            type: SnackBarType.error,
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final t = AppLocalizations.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: size.height * 0.32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        "assets/icons/Shop.svg",
                        height: 48,
                        width: 48,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(height: defaultPadding),
                    const Text(
                      "Univ Tiaret",
                      style: TextStyle(
                        fontFamily: grandisExtendedFont,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.translate('university_companion'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.translate('welcome_back'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Text(t.translate('login_subtitle')),
                  const SizedBox(height: defaultPadding),
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
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          ServerConfigDialog.show(context);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              "assets/icons/Setting.svg",
                              height: 16,
                              width: 16,
                              colorFilter: const ColorFilter.mode(
                                primaryColor,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(t.translate('server_config')),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, forgotPasswordScreenRoute);
                        },
                        child: Text(t.translate('forgot_password')),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: size.height > 700
                        ? size.height * 0.06
                        : defaultPadding,
                  ),
                  ElevatedButton(
                    onPressed: auth.state == AuthState.loading ? null : _login,
                    child: auth.state == AuthState.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(t.translate('login')),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.translate('no_account')),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, registerScreenRoute);
                        },
                        child: Text(t.translate('sign_up')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
