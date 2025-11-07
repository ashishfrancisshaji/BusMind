import 'package:flutter/material.dart';

class AppTheme {
  // Color palette
  static const Color primaryColor = Color(0xFFFF3B30); // Red accent
  static const Color secondaryColor = Color(0xFFFF2D55); // Lighter red
  static const Color backgroundColor = Colors.black;
  static const Color darkBackgroundColor = Colors.black;
  static const Color surfaceColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFE0E0E0);
  static const Color errorColor = Color(0xFFFF3B30);
  static const Color successColor = Color(0xFF34C759);
  static const Color accentColor = Color(0xFFFF3B30); // Same as primaryColor
  static const Color warningColor = Color(0xFFFF9500);
  static const Color infoColor = Color(0xFF007AFF);
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color darkCardColor = Color(0xFF242424);

  // Dark mode colors
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFE0E0E0);

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFFFE5E3),
      onPrimaryContainer: primaryColor,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFE6EE),
      onSecondaryContainer: secondaryColor,
      error: errorColor,
      onError: Colors.white,
      errorContainer: Color(0xFFFFE5E3),
      onErrorContainer: errorColor,
      surface: Colors.white,
      onSurface: Colors.black87,
      surfaceContainerHighest: Color(0xFFF5F5F7),
      onSurfaceVariant: Colors.black54,
      outline: Color(0xFFBDBDBD),
      outlineVariant: Color(0xFFE0E0E0),
      shadow: Colors.black26,
      scrim: Colors.black26,
      surfaceTint: primaryColor,
      inverseSurface: Colors.black,
      onInverseSurface: Colors.white,
    );

    final theme = ThemeData.light(useMaterial3: true).copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
    );

    return theme.copyWith(
      cardTheme: theme.cardTheme.copyWith(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: 'Roboto',
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: 'Roboto',
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontFamily: 'Roboto',
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontFamily: 'Roboto',
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontFamily: 'Roboto',
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontFamily: 'Roboto',
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontFamily: 'Roboto',
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
          fontFamily: 'Roboto',
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.black54,
          fontFamily: 'Roboto',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
          fontFamily: 'Roboto',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
          fontFamily: 'Roboto',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.black54,
          fontFamily: 'Roboto',
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: 'Roboto',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF6F6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      // Core colors
      brightness: Brightness.dark,
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: primaryColor.withValues(alpha: 0.7), // ~70% opacity
      onPrimaryContainer: Colors.white,
      
      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: secondaryColor.withValues(alpha: 0.7), // ~70% opacity
      onSecondaryContainer: Colors.white,
      
      // Error colors
      error: errorColor,
      onError: Colors.white,
      errorContainer: errorColor.withValues(alpha: 0.7), // ~70% opacity
      onErrorContainer: Colors.white,
      
      // Background/surface colors
      surface: darkSurfaceColor,
      onSurface: darkTextPrimary,
      surfaceContainerHighest: const Color(0xFF2D2D2D),
      onSurfaceVariant: darkTextSecondary,
      
      // Outline colors
      outline: const Color(0xFF9E9E9E),
      outlineVariant: const Color(0xFF424242),
      
      // Other colors
      shadow: Colors.black54,
      scrim: Colors.black54,
      surfaceTint: primaryColor,
      inverseSurface: Colors.white,
      onInverseSurface: Colors.black87,
    );
    
    final theme = ThemeData.dark(useMaterial3: true);
    
    return theme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackgroundColor,
      cardTheme: theme.cardTheme.copyWith(
        color: colorScheme.surface,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
          fontFamily: 'Roboto',
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
          fontFamily: 'Roboto',
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          fontFamily: 'Roboto',
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          fontFamily: 'Roboto',
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          fontFamily: 'Roboto',
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          fontFamily: 'Roboto',
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          fontFamily: 'Roboto',
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
          fontFamily: 'Roboto',
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkTextSecondary,
          fontFamily: 'Roboto',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: darkTextPrimary,
          fontFamily: 'Roboto',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: darkTextPrimary,
          fontFamily: 'Roboto',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: darkTextSecondary,
          fontFamily: 'Roboto',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
