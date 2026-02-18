import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_dimensions.dart';

/// LoadRunner Admin Dashboard Theme Configuration
/// Based on Material Design 3 and LoadRunner Brand Guidelines
class AppTheme {
  AppTheme._();

  // ============================================
  // LIGHT THEME
  // ============================================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.white,
        primaryContainer: Color(0xFFFFE0C8),
        onPrimaryContainer: Color(0xFF2A1700),
        secondary: AppColors.secondaryLight,
        onSecondary: AppColors.white,
        secondaryContainer: Color(0xFFD0DEF0),
        onSecondaryContainer: Color(0xFF0A1929),
        tertiary: AppColors.info,
        onTertiary: AppColors.white,
        error: AppColors.errorLight,
        onError: AppColors.white,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        surfaceContainerHighest: AppColors.backgroundLight,
        outline: AppColors.borderLight,
        outlineVariant: AppColors.dividerLight,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.backgroundLight,
      
      // Text Theme
      textTheme: AppTextStyles.lightTextTheme,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.surfaceLight,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimaryLight,
          size: AppDimensions.iconMd,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textTertiaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: AppDimensions.elevationMd,
        shadowColor: AppColors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusMd,
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.white,
          elevation: AppDimensions.elevationSm,
          shadowColor: AppColors.primaryLight.withValues(alpha: 0.3),
          padding: AppDimensions.buttonPadding,
          minimumSize: const Size(88, AppDimensions.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusSm,
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          padding: AppDimensions.buttonPadding,
          minimumSize: const Size(88, AppDimensions.buttonHeightMd),
          side: const BorderSide(
            color: AppColors.primaryLight,
            width: AppDimensions.borderWidthMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusSm,
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          padding: AppDimensions.buttonPadding,
          minimumSize: const Size(88, AppDimensions.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusSm,
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.white,
        elevation: AppDimensions.elevationLg,
        shape: CircleBorder(),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundLight,
        contentPadding: AppDimensions.inputPadding,
        border: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusSm,
          borderSide: const BorderSide(
            color: AppColors.borderLight,
            width: AppDimensions.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusSm,
          borderSide: const BorderSide(
            color: AppColors.borderLight,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusSm,
          borderSide: const BorderSide(
            color: AppColors.primaryLight,
            width: AppDimensions.borderWidthMd,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusSm,
          borderSide: const BorderSide(
            color: AppColors.errorLight,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusSm,
          borderSide: const BorderSide(
            color: AppColors.errorLight,
            width: AppDimensions.borderWidthMd,
          ),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondaryLight,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiaryLight,
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundLight,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(
          color: AppColors.borderLight,
          width: AppDimensions.borderWidth,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSm,
          vertical: AppDimensions.spacingXxs,
        ),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: AppDimensions.borderWidth,
        space: AppDimensions.spacingMd,
      ),
      
      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingXs,
        ),
        minVerticalPadding: AppDimensions.spacingSm,
        iconColor: AppColors.textSecondaryLight,
        textColor: AppColors.textPrimaryLight,
      ),
      
      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primaryLight,
        unselectedLabelColor: AppColors.textSecondaryLight,
        indicatorColor: AppColors.primaryLight,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        elevation: AppDimensions.elevationXl,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLg,
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        elevation: AppDimensions.elevationLg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLg),
          ),
        ),
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: const TextStyle(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusSm,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================
  // DARK THEME
  // ============================================
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark,
        onPrimary: AppColors.black,
        primaryContainer: Color(0xFF6B2D00),
        onPrimaryContainer: Color(0xFFFFE0C8),
        secondary: AppColors.secondaryDark,
        onSecondary: AppColors.white,
        secondaryContainer: Color(0xFF1A3A5C),
        onSecondaryContainer: Color(0xFFD0DEF0),
        tertiary: AppColors.infoDark,
        onTertiary: AppColors.white,
        error: AppColors.errorDark,
        onError: AppColors.black,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        surfaceContainerHighest: AppColors.backgroundDark,
        outline: AppColors.borderDark,
        outlineVariant: AppColors.dividerDark,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.backgroundDark,
      
      // Text Theme
      textTheme: AppTextStyles.darkTextTheme,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.surfaceDark,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimaryDark,
          size: AppDimensions.iconMd,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.textTertiaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusMd,
          side: BorderSide(
            color: AppColors.borderDark.withValues(alpha: 0.5),
            width: AppDimensions.borderWidth,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.black,
          elevation: AppDimensions.elevationSm,
          shadowColor: AppColors.primaryDark.withValues(alpha: 0.3),
          padding: AppDimensions.buttonPadding,
          minimumSize: const Size(88, AppDimensions.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusSm,
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          padding: AppDimensions.buttonPadding,
          minimumSize: const Size(88, AppDimensions.buttonHeightMd),
          side: const BorderSide(
            color: AppColors.primaryDark,
            width: AppDimensions.borderWidthMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusSm,
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          padding: AppDimensions.buttonPadding,
          minimumSize: const Size(88, AppDimensions.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusSm,
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.black,
        elevation: AppDimensions.elevationLg,
        shape: CircleBorder(),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: AppDimensions.inputPadding,
        border: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusSm,
          borderSide: const BorderSide(
            color: AppColors.borderDark,
            width: AppDimensions.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusSm,
          borderSide: const BorderSide(
            color: AppColors.borderDark,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusSm,
          borderSide: const BorderSide(
            color: AppColors.primaryDark,
            width: AppDimensions.borderWidthMd,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusSm,
          borderSide: const BorderSide(
            color: AppColors.errorDark,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusSm,
          borderSide: const BorderSide(
            color: AppColors.errorDark,
            width: AppDimensions.borderWidthMd,
          ),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondaryDark,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiaryDark,
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDark,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDark,
        ),
        side: const BorderSide(
          color: AppColors.borderDark,
          width: AppDimensions.borderWidth,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSm,
          vertical: AppDimensions.spacingXxs,
        ),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: AppDimensions.borderWidth,
        space: AppDimensions.spacingMd,
      ),
      
      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingXs,
        ),
        minVerticalPadding: AppDimensions.spacingSm,
        iconColor: AppColors.textSecondaryDark,
        textColor: AppColors.textPrimaryDark,
      ),
      
      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: AppColors.textSecondaryDark,
        indicatorColor: AppColors.primaryDark,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: AppDimensions.elevationXl,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLg,
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: AppDimensions.elevationLg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLg),
          ),
        ),
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimaryLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusSm,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
