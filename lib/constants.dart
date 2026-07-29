import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';

const grandisExtendedFont = "Grandis Extended";

class AppColors {
  static const primary = Color(0xFF125488);
  static const primaryColor = Color(0xFF125488);
  static const secondaryColor = Color(0xFF2A93D5);
  static const backgroundLight = Colors.white;
  static const backgroundDark = Color(0xFF000000);
  static const surfaceLight = Color(0xFFF8F8F9);
  static const surfaceDark = Color(0xFF2B2F3A);
  static const cardDark = Color(0xFF353A47);
  static const textLight = Color(0xFF16161E);
  static const textDark = Color(0xFFE8E8EC);
  static const textDarkSecondary = Color(0xFFB0B3BA);
  static const greenAccent = Color(0xFF2A93D5);
  static const greenLight = Color(0xFF64B5F6);
  static const success = Color(0xFF2ED573);
  static const warning = Color(0xFFFFBE21);
  static const error = Color(0xFFEA5B5B);
  static const dividerDark = Color(0xFF444955);
  static const inputFillDark = Color(0xFF3E4350);
  static const hintDark = Color(0xFF8A8E97);
}

const Color primaryColor = AppColors.primaryColor;
const Color secondaryColor = AppColors.secondaryColor;

const MaterialColor primaryMaterialColor = MaterialColor(0xFF2A93D5, <int, Color>{
  50: Color(0xFFE3F2FD),
  100: Color(0xFFBBDEFB),
  200: Color(0xFF90CAF9),
  300: Color(0xFF64B5F6),
  400: Color(0xFF42A5F5),
  500: Color(0xFF2A93D5),
  600: Color(0xFF1E88C5),
  700: Color(0xFF1565C0),
  800: Color(0xFF125488),
  900: Color(0xFF0D47A1),
});

const Color blackColor = Color(0xFF16161E);
const Color blackColor80 = Color(0xFF45454B);
const Color blackColor60 = Color(0xFF737378);
const Color blackColor40 = Color(0xFFA2A2A5);
const Color blackColor20 = Color(0xFFD0D0D2);
const Color blackColor10 = Color(0xFFE8E8E9);
const Color blackColor5 = Color(0xFFF3F3F4);

const Color whiteColor = Colors.white;
const Color greyColor = Color(0xFFB8B5C3);
const Color lightGreyColor = Color(0xFFF8F8F9);
const Color darkGreyColor = Color(0xFF1C1C25);

const Color successColor = AppColors.success;
const Color warningColor = AppColors.warning;
const Color errorColor = AppColors.error;

const double defaultPadding = 16.0;
const double defaultBorderRadious = 12.0;
const Duration defaultDuration = Duration(milliseconds: 300);

const String baseUrl = "http://localhost:3000";

MultiValidator passwordValidator(String requiredMsg, String minLengthMsg, String upperMsg, String lowerMsg, String numberMsg, String specialMsg) => MultiValidator([
  RequiredValidator(errorText: requiredMsg),
  MinLengthValidator(8, errorText: minLengthMsg),
  PatternValidator(r'(?=.*?[A-Z])', errorText: upperMsg),
  PatternValidator(r'(?=.*?[a-z])', errorText: lowerMsg),
  PatternValidator(r'(?=.*?[0-9])', errorText: numberMsg),
  PatternValidator(r'(?=.*?[#?!@$%^&*-])', errorText: specialMsg),
]);

MultiValidator emailValidator(String requiredMsg, String invalidMsg) => MultiValidator([
  RequiredValidator(errorText: requiredMsg),
  EmailValidator(errorText: invalidMsg),
]);

const pasNotMatchErrorText = "Passwords do not match";
