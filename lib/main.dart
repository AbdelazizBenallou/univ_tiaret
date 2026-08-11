import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:univ_tiaret/l10n/localizations_delegate.dart';
import 'package:univ_tiaret/l10n/locale_preferences.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/preferences/theme_preferences.dart';
import 'package:univ_tiaret/route/route_constants.dart';
import 'package:univ_tiaret/route/router.dart' as router;
import 'package:univ_tiaret/theme/app_theme.dart';
import 'package:univ_tiaret/services/api_service.dart';
import 'package:univ_tiaret/services/notification_service.dart';
import 'package:univ_tiaret/logic/notification_history_provider.dart';
import 'package:univ_tiaret/db/db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  ApiService.initialize(apiBaseUrl);
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();
  await DatabaseHelper.instance.database;
  await NotificationHistoryProvider().init();
  await NotificationService.instance.refreshPendingCount();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  static MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<MyAppState>();
  }

  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => MyAppState();
}

class MyAppState extends ConsumerState<MyApp> {
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final localeCode = await LocalePreferences.getLocale();
    final themeModeStr = await ThemePreferences.getThemeMode();
    setState(() {
      _locale = Locale(localeCode);
      _themeMode = _parseThemeMode(themeModeStr);
    });
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
    LocalePreferences.setLocale(locale.languageCode);
  }

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    String modeStr = 'system';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    if (mode == ThemeMode.light) modeStr = 'light';
    ThemePreferences.setThemeMode(modeStr);
  }

  ThemeData _buildTheme(bool dark) {
    final base = dark ? AppTheme.darkTheme(context) : AppTheme.lightTheme(context);
    final font = _locale.languageCode == 'ar' ? 'Cairo' : 'Plus Jakarta';
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: font),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(fontFamily: font),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Univ Tiaret',
      locale: _locale,
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _buildTheme(false),
      darkTheme: _buildTheme(true),
      themeMode: _themeMode,
      onGenerateRoute: router.generateRoute,
      initialRoute: splashScreenRoute,
    );
  }
}
