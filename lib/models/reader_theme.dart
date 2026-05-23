import 'package:flutter/material.dart';

enum ReaderThemeType {
  sepia,
  solarizedDark,
  sageGreen,
  charcoalNight,
  warmCream,
}

class ReaderTheme {
  final ReaderThemeType type;
  final String name;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color subtextColor;
  final Color accentColor;
  final Color buttonTextColor;
  final Brightness brightness;
  final bool isDark;

  const ReaderTheme({
    required this.type,
    required this.name,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.subtextColor,
    required this.accentColor,
    required this.buttonTextColor,
    required this.brightness,
    required this.isDark,
  });

  static List<ReaderTheme> get allThemes => [
        const ReaderTheme(
          type: ReaderThemeType.sepia,
          name: 'Sepia Paper',
          backgroundColor: Color(0xFFF4ECD8),
          surfaceColor: Color(0xFFEFE6D0),
          textColor: Color(0xFF433422),
          subtextColor: Color(0xFF6E5843),
          accentColor: Color(0xFF8B5E3C),
          buttonTextColor: Colors.white,
          brightness: Brightness.light,
          isDark: false,
        ),
        const ReaderTheme(
          type: ReaderThemeType.solarizedDark,
          name: 'Solarized Dark',
          backgroundColor: Color(0xFF002B36),
          surfaceColor: Color(0xFF073642),
          textColor: Color(0xFF93A1A1),
          subtextColor: Color(0xFF586E75),
          accentColor: Color(0xFF2AA198),
          buttonTextColor: Colors.white,
          brightness: Brightness.dark,
          isDark: true,
        ),
        const ReaderTheme(
          type: ReaderThemeType.sageGreen,
          name: 'Sage Calming',
          backgroundColor: Color(0xFFF1F5F2),
          surfaceColor: Color(0xFFE3EAE5),
          textColor: Color(0xFF20352A),
          subtextColor: Color(0xFF4A5F54),
          accentColor: Color(0xFF4E775B),
          buttonTextColor: Colors.white,
          brightness: Brightness.light,
          isDark: false,
        ),
        const ReaderTheme(
          type: ReaderThemeType.charcoalNight,
          name: 'Charcoal Night',
          backgroundColor: Color(0xFF121212),
          surfaceColor: Color(0xFF1E1E1E),
          textColor: Color(0xFFE0E0E0),
          subtextColor: Color(0xFF9E9E9E),
          accentColor: Color(0xFFBB86FC),
          buttonTextColor: Colors.black,
          brightness: Brightness.dark,
          isDark: true,
        ),
        const ReaderTheme(
          type: ReaderThemeType.warmCream,
          name: 'Warm Cream',
          backgroundColor: Color(0xFFFAF6EE),
          surfaceColor: Color(0xFFF3EDE0),
          textColor: Color(0xFF2C3E50),
          subtextColor: Color(0xFF7F8C8D),
          accentColor: Color(0xFFD35400),
          buttonTextColor: Colors.white,
          brightness: Brightness.light,
          isDark: false,
        ),
      ];

  ThemeData toThemeData() {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: accentColor,
      onPrimary: buttonTextColor,
      secondary: accentColor,
      onSecondary: buttonTextColor,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: surfaceColor,
      onSurface: textColor,
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: textColor),
        bodyLarge: TextStyle(color: textColor, fontSize: 16),
        titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: textColor),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surfaceColor),
        ),
      ),
    );
  }
}
