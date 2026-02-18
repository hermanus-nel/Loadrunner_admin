import 'package:flutter/material.dart';

/// LoadRunner Admin Dashboard Dimensions
/// Consistent spacing, sizing, and layout constants
class AppDimensions {
  AppDimensions._();

  // ============================================
  // SPACING (based on 4px grid)
  // ============================================
  
  /// 4px
  static const double spacingXxs = 4.0;
  
  /// 8px
  static const double spacingXs = 8.0;
  
  /// 12px
  static const double spacingSm = 12.0;
  
  /// 16px - Default spacing
  static const double spacingMd = 16.0;
  
  /// 20px
  static const double spacingLg = 20.0;
  
  /// 24px
  static const double spacingXl = 24.0;
  
  /// 32px
  static const double spacingXxl = 32.0;
  
  /// 40px
  static const double spacingXxxl = 40.0;
  
  /// 48px
  static const double spacingHuge = 48.0;

  // ============================================
  // PADDING PRESETS
  // ============================================
  
  /// Page padding - 16px horizontal, 16px vertical
  static const EdgeInsets pagePadding = EdgeInsets.all(spacingMd);
  
  /// Page padding horizontal only
  static const EdgeInsets pageHorizontalPadding = EdgeInsets.symmetric(
    horizontal: spacingMd,
  );
  
  /// Card padding - 16px all sides
  static const EdgeInsets cardPadding = EdgeInsets.all(spacingMd);
  
  /// Card padding compact - 12px all sides
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(spacingSm);
  
  /// List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: spacingMd,
    vertical: spacingSm,
  );
  
  /// Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: spacingLg,
    vertical: spacingSm,
  );
  
  /// Input field content padding
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: spacingMd,
    vertical: spacingSm,
  );

  // ============================================
  // BORDER RADIUS
  // ============================================
  
  /// 4px - Small elements (chips, badges)
  static const double radiusXs = 4.0;
  
  /// 8px - Buttons, inputs
  static const double radiusSm = 8.0;
  
  /// 12px - Cards, dialogs
  static const double radiusMd = 12.0;
  
  /// 16px - Large cards, bottom sheets
  static const double radiusLg = 16.0;
  
  /// 24px - Full rounded elements
  static const double radiusXl = 24.0;
  
  /// Full circle
  static const double radiusFull = 999.0;
  
  /// Common border radius presets
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));

  // ============================================
  // ICON SIZES
  // ============================================
  
  /// 16px - Small inline icons
  static const double iconXs = 16.0;
  
  /// 20px - Default icon size
  static const double iconSm = 20.0;
  
  /// 24px - Navigation, list items
  static const double iconMd = 24.0;
  
  /// 32px - Feature icons
  static const double iconLg = 32.0;
  
  /// 48px - Large feature icons
  static const double iconXl = 48.0;
  
  /// 64px - Hero icons
  static const double iconXxl = 64.0;

  // ============================================
  // AVATAR SIZES
  // ============================================
  
  /// 24px - Tiny avatar (inline)
  static const double avatarXs = 24.0;
  
  /// 32px - Small avatar
  static const double avatarSm = 32.0;
  
  /// 40px - Default avatar (list items)
  static const double avatarMd = 40.0;
  
  /// 56px - Large avatar (profile header)
  static const double avatarLg = 56.0;
  
  /// 80px - Extra large avatar
  static const double avatarXl = 80.0;
  
  /// 120px - Profile page avatar
  static const double avatarXxl = 120.0;

  // ============================================
  // COMPONENT HEIGHTS
  // ============================================
  
  /// 36px - Small button
  static const double buttonHeightSm = 36.0;
  
  /// 44px - Default button
  static const double buttonHeightMd = 44.0;
  
  /// 52px - Large button
  static const double buttonHeightLg = 52.0;
  
  /// 48px - Input field height
  static const double inputHeight = 48.0;
  
  /// 56px - App bar height
  static const double appBarHeight = 56.0;
  
  /// 80px - Bottom navigation bar height
  static const double bottomNavHeight = 80.0;
  
  /// 48px - List item minimum height
  static const double listItemMinHeight = 48.0;
  
  /// 72px - List item with subtitle
  static const double listItemWithSubtitleHeight = 72.0;

  // ============================================
  // CARD DIMENSIONS
  // ============================================
  
  /// Stat card minimum width
  static const double statCardMinWidth = 150.0;
  
  /// Stat card height
  static const double statCardHeight = 100.0;
  
  /// Quick action button size
  static const double quickActionSize = 80.0;

  // ============================================
  // BORDER WIDTH
  // ============================================
  
  /// 1px - Default border
  static const double borderWidth = 1.0;
  
  /// 1.5px - Focused/active border
  static const double borderWidthMd = 1.5;
  
  /// 2px - Strong emphasis
  static const double borderWidthLg = 2.0;

  // ============================================
  // ELEVATION
  // ============================================
  
  /// No elevation
  static const double elevationNone = 0.0;
  
  /// 2px - Subtle shadow
  static const double elevationSm = 2.0;
  
  /// 4px - Card shadow
  static const double elevationMd = 4.0;
  
  /// 8px - Modal shadow
  static const double elevationLg = 8.0;
  
  /// 16px - Dialog shadow
  static const double elevationXl = 16.0;

  // ============================================
  // RESPONSIVE BREAKPOINTS
  // ============================================
  
  /// Mobile (compact) max width
  static const double mobileMaxWidth = 599.0;
  
  /// Tablet (medium) max width
  static const double tabletMaxWidth = 839.0;
  
  /// Desktop (expanded) min width
  static const double desktopMinWidth = 840.0;

  // ============================================
  // ANIMATION DURATIONS
  // ============================================
  
  /// 150ms - Quick transitions
  static const Duration durationFast = Duration(milliseconds: 150);
  
  /// 250ms - Default transitions
  static const Duration durationMedium = Duration(milliseconds: 250);
  
  /// 350ms - Slow transitions
  static const Duration durationSlow = Duration(milliseconds: 350);
  
  /// 500ms - Very slow transitions
  static const Duration durationVerySlow = Duration(milliseconds: 500);
}
