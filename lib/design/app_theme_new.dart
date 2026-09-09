import 'package:flutter/material.dart';
import 'tokens.dart';

ThemeData appLightTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bg,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light, primary: AppColors.primary),
  cardTheme: CardThemeData(
    color: AppColors.card,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
    shadowColor: Colors.black12,
  ),
  appBarTheme: const AppBarTheme(backgroundColor: AppColors.bg, elevation: 0, scrolledUnderElevation: 0, centerTitle: false),
  textTheme: const TextTheme(titleLarge: AppText.title, bodySmall: AppText.label),
);
