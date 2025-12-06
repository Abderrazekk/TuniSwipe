import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFD7263D); // Deep Red (Tunisian Flag)
  static const Color secondary = Color(0xFF1B4965); // Dark Blue (Mediterranean Sea)
  static const Color accent = Color(0xFFF4D35E); // Sand / Warm Accent
  static const Color background = Color(0xFFEDF2F4); // Light neutral background
  static const Color surface = Color(0xFFFFFFFF); // White surface
  static const Color textPrimary = Color(0xFF2B2D42); // Dark slate text
  static const Color textSecondary = Color(0xFF8D99AE); // Grayish text
  static const Color border = Color(0xFFBFC0C0); // Soft border
  static const Color error = Color(0xFF9D0208); // Strong Red error
  static const Color success = Color(0xFF6A994E); // Olive green success

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD7263D), Color(0xFF9D0208)], // Dark red gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}



//AppColors.primary
//AppColors.secondary
//AppColors.accent
//AppColors.background
//AppColors.surface
//AppColors.textPrimary
//AppColors.textSecondary
//AppColors.border
//AppColors.error
//AppColors.success
//AppColors.primaryGradient