import 'package:flutter/material.dart';
import 'package:univ_tiaret/theme/button_theme.dart';
import 'package:univ_tiaret/theme/input_decoration_theme.dart';
import '../constants.dart';

class AppTheme {
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: false,
      fontFamily: "Plus Jakarta",
      primarySwatch: primaryMaterialColor,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      iconTheme: const IconThemeData(color: AppColors.textLight),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: blackColor40),
        bodyLarge: TextStyle(color: AppColors.textLight),
        bodySmall: TextStyle(color: blackColor40),
        headlineSmall: TextStyle(color: AppColors.textLight),
        headlineMedium: TextStyle(color: AppColors.textLight),
        titleSmall: TextStyle(color: AppColors.textLight),
        titleMedium: TextStyle(color: AppColors.textLight),
      ),
      elevatedButtonTheme: elevatedButtonThemeData,
      textButtonTheme: textButtonThemeData,
      outlinedButtonTheme: outlinedButtonTheme(),
      inputDecorationTheme: lightInputDecorationTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textLight),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textLight,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: blackColor10,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: false,
      fontFamily: "Plus Jakarta",
      primarySwatch: primaryMaterialColor,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      iconTheme: const IconThemeData(color: AppColors.textDark),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: AppColors.textDarkSecondary),
        bodyLarge: TextStyle(color: AppColors.textDark),
        bodySmall: TextStyle(color: AppColors.textDarkSecondary),
        headlineSmall: TextStyle(color: AppColors.textDark),
        headlineMedium: TextStyle(color: AppColors.textDark),
        titleSmall: TextStyle(color: AppColors.textDark),
        titleMedium: TextStyle(color: AppColors.textDark),
      ),
      elevatedButtonTheme: elevatedButtonThemeData,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.greenLight),
      ),
      outlinedButtonTheme: outlinedButtonTheme(borderColor: AppColors.dividerDark),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        fillColor: AppColors.inputFillDark,
        filled: true,
        hintStyle: const TextStyle(color: AppColors.hintDark),
        prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 0),
        suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 0),
        border: outlineInputBorder,
        enabledBorder: outlineInputBorder,
        focusedBorder: focusedOutlineInputBorder,
        errorBorder: errorOutlineInputBorder,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
      ),
      cardTheme: CardThemeData(
        color: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardDark,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
