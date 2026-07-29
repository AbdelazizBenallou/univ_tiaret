import 'package:flutter/material.dart';
import '../constants.dart';

const InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  fillColor: lightGreyColor,
  filled: true,
  hintStyle: TextStyle(color: greyColor),
  prefixIconConstraints: BoxConstraints(minWidth: 44, minHeight: 0),
  suffixIconConstraints: BoxConstraints(minWidth: 44, minHeight: 0),
  border: outlineInputBorder,
  enabledBorder: outlineInputBorder,
  focusedBorder: focusedOutlineInputBorder,
  errorBorder: errorOutlineInputBorder,
);

const InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  fillColor: AppColors.inputFillDark,
  filled: true,
  hintStyle: TextStyle(color: AppColors.hintDark),
  prefixIconConstraints: BoxConstraints(minWidth: 44, minHeight: 0),
  suffixIconConstraints: BoxConstraints(minWidth: 44, minHeight: 0),
  border: outlineInputBorder,
  enabledBorder: outlineInputBorder,
  focusedBorder: focusedOutlineInputBorder,
  errorBorder: errorOutlineInputBorder,
);

const OutlineInputBorder outlineInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(defaultBorderRadious)),
  borderSide: BorderSide(color: Colors.transparent),
);

const OutlineInputBorder focusedOutlineInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(defaultBorderRadious)),
  borderSide: BorderSide(color: primaryColor),
);

const OutlineInputBorder errorOutlineInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(defaultBorderRadious)),
  borderSide: BorderSide(color: errorColor),
);
