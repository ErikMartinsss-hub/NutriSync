import 'package:flutter/material.dart';

abstract class AppColors {
  static const bg = Color(0xFFF5F6FA);
  static const card = Color(0xFFFFFFFF);
  static const primary = Color(0xFF0066FF);
  static const primaryAlt = Color(0xFF007AFF);
  static const premium = Color(0xFFFFC107);
  static const carb = Color(0xFF20B2AA);
  static const fat = Color(0xFF8A2BE2);
  static const protein = Color(0xFFFFA500);
  static const textDark = Color(0xFF1A1A1A);
  static const textMid = Color(0xFF757575);
  static const border = Color(0xFFE8EAF0);
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
  static const title = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark);
  static const appBarTitle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark);
  static const label = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMid);
  static const value = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark);
  static const small = TextStyle(fontSize: 11, color: AppColors.textMid);
}
