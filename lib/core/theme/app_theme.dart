import 'package:flutter/material.dart';
import '../../design/tokens.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light, primary: AppColors.primary),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
          shadowColor: Colors.black12,
        ),
        appBarTheme: AppBarTheme(backgroundColor: AppColors.bg, elevation: 0, scrolledUnderElevation: 0),
      );
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.dark, primary: AppColors.primary, surface: AppColors.card, onSurface: AppColors.textDark),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        ),
        appBarTheme: AppBarTheme(backgroundColor: AppColors.bg, elevation: 0, scrolledUnderElevation: 0),
      );
}