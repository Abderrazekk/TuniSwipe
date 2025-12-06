import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFFD7263D); // Deep Red
  static const Color primaryLight = Color(0xFFE5455A); // Lighter Red
  static const Color primaryDark = Color(0xFF9D0208); // Darker Red
  
  // Secondary Colors
  static const Color secondary = Color(0xFF1B4965); // Dark Blue
  static const Color secondaryLight = Color(0xFF2A5F7F); // Lighter Blue
  static const Color secondaryDark = Color(0xFF0A2E43); // Darker Blue
  
  // Accent Colors
  static const Color accent = Color(0xFFF4D35E); // Sand / Gold
  static const Color accentLight = Color(0xFFFFE082); // Lighter Gold
  static const Color accentDark = Color(0xFFD4B74A); // Darker Gold
  
  // Neutral Colors
  static const Color background = Color(0xFFF8FAFD); // Light background
  static const Color surface = Color(0xFFFFFFFF); // White surface
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Light gray surface
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B); // Dark slate
  static const Color textSecondary = Color(0xFF64748B); // Medium gray
  static const Color textTertiary = Color(0xFF94A3B8); // Light gray
  static const Color textInverse = Color(0xFFFFFFFF); // White text
  
  // Status Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color successLight = Color(0xFFD1FAE5); // Light Emerald
  static const Color error = Color(0xFFEF4444); // Red
  static const Color errorLight = Color(0xFFFEE2E2); // Light Red
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFEF3C7); // Light Amber
  static const Color info = Color(0xFF3B82F6); // Blue
  static const Color infoLight = Color(0xFFDBEAFE); // Light Blue
  
  // Border Colors
  static const Color border = Color(0xFFE2E8F0); // Light border
  static const Color borderDark = Color(0xFFCBD5E1); // Darker border
  
  // Special Colors
  static const Color pink = Color(0xFFEC4899); // Pink
  static const Color purple = Color(0xFF8B5CF6); // Purple
  static const Color teal = Color(0xFF14B8A6); // Teal
  
  // Shadows
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.05),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.12),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF8FAFD), Color(0xFFF1F5F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFD)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Glass Effect
  static Color glassBackground = Colors.white.withOpacity(0.95);
  static Color glassBorder = Colors.white.withOpacity(0.2);
  
  // Animation Colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
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
//AppColors.shadowMedium
//AppColors.glassBackground
//AppColors.glassBorder
//AppColors.shimmerBase
//AppColors.shimmerHighlight
// etc.