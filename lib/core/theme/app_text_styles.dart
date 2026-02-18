import 'package:flutter/material.dart';
import 'app_colors.dart';

/// LoadRunner Admin Dashboard Typography
/// Based on Material Design 3 type scale
class AppTextStyles {
  AppTextStyles._();

  // ============================================
  // FONT FAMILY
  // ============================================
  
  static const String fontFamily = 'Roboto';

  // ============================================
  // LIGHT MODE TEXT STYLES
  // ============================================
  
  static const TextTheme lightTextTheme = TextTheme(
    // Display styles - Large headlines
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      color: AppColors.textPrimaryLight,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: AppColors.textPrimaryLight,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: AppColors.textPrimaryLight,
    ),
    
    // Headline styles - Section headers
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      color: AppColors.textPrimaryLight,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.25,
      color: AppColors.textPrimaryLight,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      color: AppColors.textPrimaryLight,
    ),
    
    // Title styles - Card titles, list titles
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      letterSpacing: 0,
      color: AppColors.textPrimaryLight,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: AppColors.textPrimaryLight,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: AppColors.textPrimaryLight,
    ),
    
    // Body styles - Main content
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: AppColors.textSecondaryLight,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: AppColors.textSecondaryLight,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: AppColors.textTertiaryLight,
    ),
    
    // Label styles - Buttons, chips, form labels
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: AppColors.textPrimaryLight,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: AppColors.textSecondaryLight,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: AppColors.textTertiaryLight,
    ),
  );

  // ============================================
  // DARK MODE TEXT STYLES
  // ============================================
  
  static const TextTheme darkTextTheme = TextTheme(
    // Display styles
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      color: AppColors.textPrimaryDark,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: AppColors.textPrimaryDark,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: AppColors.textPrimaryDark,
    ),
    
    // Headline styles
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      color: AppColors.textPrimaryDark,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.25,
      color: AppColors.textPrimaryDark,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      color: AppColors.textPrimaryDark,
    ),
    
    // Title styles
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      letterSpacing: 0,
      color: AppColors.textPrimaryDark,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: AppColors.textPrimaryDark,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: AppColors.textPrimaryDark,
    ),
    
    // Body styles
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: AppColors.textSecondaryDark,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: AppColors.textSecondaryDark,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: AppColors.textTertiaryDark,
    ),
    
    // Label styles
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: AppColors.textPrimaryDark,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: AppColors.textSecondaryDark,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: AppColors.textTertiaryDark,
    ),
  );

  // ============================================
  // CUSTOM STYLES (for specific use cases)
  // ============================================
  
  /// Large stat number (dashboard cards)
  static TextStyle statNumber(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
  }
  
  /// Stat label (below stat numbers)
  static TextStyle statLabel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    );
  }
  
  /// Badge text
  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  /// Button text
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  /// Input hint text
  static TextStyle inputHint(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
    );
  }
}
