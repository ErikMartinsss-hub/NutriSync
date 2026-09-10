import 'package:flutter/material.dart';

abstract class AppColors {
  static Brightness _mode = Brightness.light;
  static set mode(Brightness b) => _mode = b;
  static Brightness get mode => _mode;

  static bool get isDark => _mode == Brightness.dark;

  static Color get bg => isDark ? const Color(0xFF0F1412) : const Color(0xFFF5F6FA);
  static Color get card => isDark ? const Color(0xFF171D1A) : const Color(0xFFFFFFFF);
  static Color get cardAlt => isDark ? const Color(0xFF1E261F) : const Color(0xFFF7F8FB);
  static Color get border => isDark ? const Color(0xFF2A332E) : const Color(0xFFE8EAF0);
  static Color get textDark => isDark ? const Color(0xFFE8EDEA) : const Color(0xFF1A1A1A);
  static Color get textMid => isDark ? const Color(0xFF9CA6A1) : const Color(0xFF757575);

  static const primary = Color(0xFF0066FF);
  static const primaryAlt = Color(0xFF007AFF);
  static const premium = Color(0xFFFFC107);
  static const carb = Color(0xFF20B2AA);
  static const fat = Color(0xFF8A2BE2);
  static const protein = Color(0xFFFFA500);
}

abstract class AppRadius {
  static const double card = 16;
  static const double pill = 24;
}

abstract class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
  ];
}

abstract class AppText {
  static TextStyle get title => TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark);
  static TextStyle get appBarTitle => TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark);
  static TextStyle get label => TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMid);
  static TextStyle get value => TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark);
  static TextStyle get small => TextStyle(fontSize: 11, color: AppColors.textMid);
}