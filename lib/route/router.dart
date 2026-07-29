import 'package:flutter/material.dart';
import 'package:univ_tiaret/entry_point.dart';
import 'package:univ_tiaret/screens/auth/views/login_screen.dart';
import 'package:univ_tiaret/screens/auth/views/register_personal_screen.dart';
import 'package:univ_tiaret/screens/auth/views/register_account_screen.dart';
import 'package:univ_tiaret/screens/auth/views/forgot_password_screen.dart';
import 'package:univ_tiaret/screens/auth/views/code_verification_screen.dart';
import 'package:univ_tiaret/screens/auth/views/reset_password_screen.dart';
import 'package:univ_tiaret/screens/settings/views/change_password_screen.dart';
import 'package:univ_tiaret/screens/home/views/modules_screen.dart';
import 'package:univ_tiaret/screens/home/views/semesters_screen.dart';
import 'package:univ_tiaret/screens/home/views/activities_screen.dart';
import 'package:univ_tiaret/screens/home/views/lesson_files_screen.dart';
import 'package:univ_tiaret/screens/home/views/downloads_screen.dart';
import 'package:univ_tiaret/screens/file_viewer/file_viewer_screen.dart';
import 'package:univ_tiaret/screens/profile/views/profile_screen.dart';
import 'package:univ_tiaret/screens/profile/views/edit_profile_screen.dart';
import 'package:univ_tiaret/screens/subscription/views/subscribe_screen.dart';
import 'package:univ_tiaret/screens/splash/views/splash_screen.dart';
import 'route_constants.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case splashScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      );
    case logInScreenRoute:
      return _buildRoute(settings, const LoginScreen());
    case registerScreenRoute:
      return _buildRoute(settings, const RegisterPersonalScreen());
    case registerAccountScreenRoute:
      return _buildRoute(settings, const RegisterAccountScreen(), customSettings: settings);
    case forgotPasswordScreenRoute:
      return _buildRoute(settings, const ForgotPasswordScreen());
    case codeVerificationScreenRoute:
      return _buildRoute(settings, const CodeVerificationScreen(), customSettings: settings);
    case resetPasswordScreenRoute:
      return _buildRoute(settings, const ResetPasswordScreen(), customSettings: settings);
    case changePasswordScreenRoute:
      return _buildRoute(settings, const ChangePasswordScreen());
    case entryPointScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const EntryPoint(),
      );
    case semestersScreenRoute:
      final args = settings.arguments as Map<String, dynamic>;
      return _buildRoute(
        settings,
        SemestersScreen(
          levelId: args['levelId'] as int,
          seasonId: args['seasonId'] as int,
          seasonName: args['seasonName'] as String,
          seasonIsCurrent: args['seasonIsCurrent'] as bool,
          levelName: args['levelName'] as String?,
          specialityId: args['specialityId'] as int?,
        ),
      );
    case modulesScreenRoute:
      final args = settings.arguments as Map<String, dynamic>;
      return _buildRoute(
        settings,
        ModulesScreen(
          semesterId: args['semesterId'] as int,
          semesterName: args['semesterName'] as String,
          seasonId: args['seasonId'] as int,
          seasonName: args['seasonName'] as String,
          levelName: args['levelName'] as String?,
          specialityId: args['specialityId'] as int?,
        ),
      );
    case activitiesScreenRoute:
      final args = settings.arguments as Map<String, dynamic>;
      return _buildRoute(
        settings,
        ActivitiesScreen(
          moduleId: args['moduleId'] as int,
          moduleName: args['moduleName'] as String,
          seasonId: args['seasonId'] as int,
          semesterName: args['semesterName'] as String,
          seasonName: args['seasonName'] as String,
        ),
      );
    case lessonFilesScreenRoute:
      final args = settings.arguments as Map<String, dynamic>;
      return _buildRoute(
        settings,
        LessonFilesScreen(
          moduleId: args['moduleId'] as int,
          moduleName: args['moduleName'] as String,
          activityTypeId: args['activityTypeId'] as int,
          activityTypeName: args['activityTypeName'] as String,
          seasonId: args['seasonId'] as int,
          seasonName: args['seasonName'] as String,
          semesterName: args['semesterName'] as String,
        ),
      );
    case downloadsScreenRoute:
      return _buildRoute(
        settings,
        Scaffold(
          appBar: AppBar(
            title: const Text('Downloads'),
          ),
          body: const DownloadsScreen(),
        ),
      );
    case profileScreenRoute:
      return _buildRoute(settings, const ProfileScreen());
    case editProfileScreenRoute:
      return _buildRoute(settings, const EditProfileScreen());
    case subscribeScreenRoute:
      return _buildRoute(settings, const SubscribeScreen());
    case fileViewerScreenRoute:
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => FileViewerScreen(
          filePath: args['filePath'] as String,
          fileName: args['fileName'] as String,
          fileType: args['fileType'] as String,
        ),
      );
    default:
      return MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      );
  }
}

Route<dynamic> _buildRoute(
  RouteSettings settings,
  Widget page, {
  RouteSettings? customSettings,
}) {
  return PageRouteBuilder(
    settings: customSettings ?? settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      final fadeTween = Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut));

      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: child,
        ),
      );
    },
  );
}
