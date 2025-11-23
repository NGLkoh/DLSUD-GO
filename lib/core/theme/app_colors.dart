import 'package:flutter/material.dart';

class AppColors {
  // Primary colors based on DLSU branding
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF1B5E20);

  // Background colors
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;

  // Text colors
  static const Color textDark = Color(0xFF212121);
  static const Color textMedium = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);

  // Accent colors
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color successGreen = Color(0xFF4CAF50);

  // Chat colors
  static const Color chatUserBubble = Color(0xFF2E7D32);
  static const Color chatBotBubble = Color(0xFFE8F5E8);

  // Gradient definitions
  static const List<Color> primaryGradient = [
    Color(0xFF2E7D32),
    Color(0xFF1B5E20),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF4CAF50),
    Color(0xFF2E7D32),
  ];

  static const List<Color> headerGradient = [
    Color(0xFF2E7D32),
    Color(0xFF1B5E20),
  ];

  static const List<Color> lilyGradient = [
    Color(0xFF4CAF50),
    Color(0xFF2E7D32),
  ];

  // Create a material swatch for primary green
  static const MaterialColor greenSwatch = MaterialColor(0xFF2E7D32, {
    50: Color(0xFFE8F5E8),
    100: Color(0xFFC8E6C9),
    200: Color(0xFFA5D6A7),
    300: Color(0xFF81C784),
    400: Color(0xFF66BB6A),
    500: Color(0xFF2E7D32),
    600: Color(0xFF43A047),
    700: Color(0xFF388E3C),
    800: Color(0xFF2E7D32),
    900: Color(0xFF1B5E20),
  });
}
