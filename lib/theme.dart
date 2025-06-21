import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color mintGreen = Color(0xFFA8EDEA);    // 🟢 Start Color
  static const Color skyBlue = Color(0xFFDCEDF8);      // 🔵 Middle Color  
  static const Color lightLavender = Color(0xFFE0C3FC); // 🟣 End Color

  // Additional App Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color darkGrey = Color(0xFF424242);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2D2D2D);
  static const Color darkPrimary = Color(0xFF64B5F6);
  static const Color darkOnBackground = Color(0xFFE0E0E0);
  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color darkMintGreen = Color(0xFF4A9B8E);
  static const Color darkSkyBlue = Color(0xFF5A8CAF);
  static const Color darkLavender = Color(0xFF8A6FB0);

  // App Gradient - Light Theme
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      mintGreen,      // 🟢 Start Color - Mint Green
      skyBlue,        // 🔵 Middle Color - Sky Blue
      lightLavender,  // 🟣 End Color - Light Lavender
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // App Gradient - Dark Theme
  static const LinearGradient darkPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      darkMintGreen,
      darkSkyBlue,
      darkLavender,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Subtle gradient for backgrounds
  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8FDFC),  // Very light mint
      Color(0xFFF9FCFE),  // Very light sky blue
      Color(0xFFFBF9FE),  // Very light lavender
    ],
  );

  // Subtle gradient for backgrounds - Dark Theme
  static const LinearGradient darkSubtleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A1A),  // Very dark mint
      Color(0xFF1C1C1E),  // Very dark sky blue
      Color(0xFF1E1A1E),  // Very dark lavender
    ],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.white,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkGrey),
        titleTextStyle: TextStyle(
          color: AppColors.darkGrey,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.darkGrey,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.darkGrey,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGrey,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.darkGrey,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.darkGrey,
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkOnSurface),
        titleTextStyle: TextStyle(
          color: AppColors.darkOnSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.darkOnSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.darkOnSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkOnSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.darkOnBackground,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.darkOnBackground,
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkBackground,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkCard),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.darkSurface,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.darkCard,
      ),
    );
  }
}

// Extension for easy gradient access
extension GradientExtension on Widget {
  Widget applyGradient({LinearGradient? gradient, bool isDark = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? (isDark ? AppColors.darkPrimaryGradient : AppColors.primaryGradient),
      ),
      child: this,
    );
  }
}
