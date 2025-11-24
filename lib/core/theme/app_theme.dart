import 'package:flutter/material.dart';

// First, define your custom colors as a theme extension
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.primaryGreen,
    required this.lightGreen,
    required this.darkGreen,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardBackground,
    required this.textDark,
    required this.textMedium,
    required this.textLight,
    required this.accentBlue,
    required this.errorRed,
    required this.warningOrange,
    required this.successGreen,
    required this.chatUserBubble,
    required this.chatBotBubble,
  });

  final Color? primaryGreen;
  final Color? lightGreen;
  final Color? darkGreen;
  final Color? backgroundColor;
  final Color? surfaceColor;
  final Color? cardBackground;
  final Color? textDark;
  final Color? textMedium;
  final Color? textLight;
  final Color? accentBlue;
  final Color? errorRed;
  final Color? warningOrange;
  final Color? successGreen;
  final Color? chatUserBubble;
  final Color? chatBotBubble;

  @override
  AppColorsExtension copyWith({
    Color? primaryGreen,
    Color? lightGreen,
    Color? darkGreen,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? cardBackground,
    Color? textDark,
    Color? textMedium,
    Color? textLight,
    Color? accentBlue,
    Color? errorRed,
    Color? warningOrange,
    Color? successGreen,
    Color? chatUserBubble,
    Color? chatBotBubble,
  }) {
    return AppColorsExtension(
      primaryGreen: primaryGreen ?? this.primaryGreen,
      lightGreen: lightGreen ?? this.lightGreen,
      darkGreen: darkGreen ?? this.darkGreen,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      cardBackground: cardBackground ?? this.cardBackground,
      textDark: textDark ?? this.textDark,
      textMedium: textMedium ?? this.textMedium,
      textLight: textLight ?? this.textLight,
      accentBlue: accentBlue ?? this.accentBlue,
      errorRed: errorRed ?? this.errorRed,
      warningOrange: warningOrange ?? this.warningOrange,
      successGreen: successGreen ?? this.successGreen,
      chatUserBubble: chatUserBubble ?? this.chatUserBubble,
      chatBotBubble: chatBotBubble ?? this.chatBotBubble,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      primaryGreen: Color.lerp(primaryGreen, other.primaryGreen, t),
      lightGreen: Color.lerp(lightGreen, other.lightGreen, t),
      darkGreen: Color.lerp(darkGreen, other.darkGreen, t),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t),
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t),
      textDark: Color.lerp(textDark, other.textDark, t),
      textMedium: Color.lerp(textMedium, other.textMedium, t),
      textLight: Color.lerp(textLight, other.textLight, t),
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t),
      errorRed: Color.lerp(errorRed, other.errorRed, t),
      warningOrange: Color.lerp(warningOrange, other.warningOrange, t),
      successGreen: Color.lerp(successGreen, other.successGreen, t),
      chatUserBubble: Color.lerp(chatUserBubble, other.chatUserBubble, t),
      chatBotBubble: Color.lerp(chatBotBubble, other.chatBotBubble, t),
    );
  }
}

// Now, define your theme class
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: const Color(0xFF2E7D32),
      scaffoldBackgroundColor: Colors.white,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2E7D32),
        secondary: Color(0xFF4CAF50),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppColorsExtension(
          primaryGreen: Color(0xFF2E7D32),
          lightGreen: Color(0xFF4CAF50),
          darkGreen: Color(0xFF1B5E20),
          backgroundColor: Colors.white,
          surfaceColor: Color(0xFFF5F5F5),
          cardBackground: Colors.white,
          textDark: Color(0xFF212121),
          textMedium: Color(0xFF757575),
          textLight: Color(0xFF9E9E9E),
          accentBlue: Color(0xFF2196F3),
          errorRed: Color(0xFFD32F2F),
          warningOrange: Color(0xFFFF9800),
          successGreen: Color(0xFF4CAF50),
          chatUserBubble: Color(0xFF2E7D32),
          chatBotBubble: Color(0xFFE8F5E8),
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: const Color(0xFF2E7D32),
      scaffoldBackgroundColor: const Color(0xFF121212),
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF66BB6A), // A lighter green for dark mode
        secondary: Color(0xFF81C784),
        background: Color(0xFF121212),
        surface: Color(0xFF1E1E1E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppColorsExtension(
          primaryGreen: Color(0xFF66BB6A),
          lightGreen: Color(0xFF81C784),
          darkGreen: Color(0xFFA5D6A7),
          backgroundColor: Color(0xFF121212),
          surfaceColor: Color(0xFF1E1E1E),
          cardBackground: Color(0xFF1E1E1E),
          textDark: Colors.white,
          textMedium: Colors.white70,
          textLight: Colors.white60,
          accentBlue: Color(0xFF64B5F6),
          errorRed: Color(0xFFE57373),
          warningOrange: Color(0xFFFFB74D),
          successGreen: Color(0xFF81C784),
          chatUserBubble: Color(0xFF2E7D32), // Keeping user bubble the same
          chatBotBubble: Color(0xFF2A2A2A), // Darker bot bubble
        ),
      ],
    );
  }
}
