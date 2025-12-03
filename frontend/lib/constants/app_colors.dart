import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF7C3AED); // Purple
  static const Color secondary = Color(0xFF10B981); // Green
  static const Color accent = Color(0xFFF59E0B); // Amber
  static const Color background = Color(0xFFF8FAFC); // Light background
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color textPrimary = Color(0xFF1E293B); // Dark blue-gray
  static const Color textSecondary = Color(0xFF64748B); // Gray
  static const Color border = Color(0xFFE2E8F0); // Light border
  static const Color error = Color(0xFFEF4444); // Red
  static const Color success = Color(0xFF10B981); // Green

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
