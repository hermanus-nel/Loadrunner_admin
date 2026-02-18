import 'package:flutter/material.dart';

/// LoadRunner Admin Dashboard Color Palette
/// Based on LoadRunner Brand Style Guide
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY COLORS
  // ============================================

  /// LoadRunner Orange - Primary brand color
  /// Light Mode: #FF6B00
  /// Dark Mode: #FF8C3A
  static const Color primaryLight = Color(0xFFFF6B00);
  static const Color primaryDark = Color(0xFFFF8C3A);

  /// Dark Navy - Secondary brand color
  /// Light Mode: #1E3A5F
  /// Dark Mode: #2C5282
  static const Color secondaryLight = Color(0xFF1E3A5F);
  static const Color secondaryDark = Color(0xFF2C5282);

  // ============================================
  // SEMANTIC COLORS
  // ============================================
  
  /// Success Green - Approved, completed, positive
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);
  
  /// Warning Amber - Pending, attention needed
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);
  
  /// Error Red - Rejected, failed, urgent
  static const Color errorLight = Color(0xFFB00020);
  static const Color errorDark = Color(0xFFCF6679);
  
  /// Info Blue - Neutral information
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);

  // ============================================
  // NEUTRAL COLORS
  // ============================================
  
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  /// Background colors
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundDark = Color(0xFF121212);
  
  /// Surface colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  /// Card colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E);
  
  /// Text colors
  static const Color textPrimaryLight = Color(0xFF1F2937);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);
  static const Color textTertiaryDark = Color(0xFF6B7280);
  
  /// Border colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);
  
  /// Divider colors
  static const Color dividerLight = Color(0xFFE5E7EB);
  static const Color dividerDark = Color(0xFF374151);

  // ============================================
  // STATUS COLORS (for badges, indicators)
  // ============================================
  
  /// Pending status - Yellow/Amber
  static const Color statusPending = Color(0xFFFEF3C7);
  static const Color statusPendingText = Color(0xFF92400E);
  
  /// Approved status - Green
  static const Color statusApproved = Color(0xFFD1FAE5);
  static const Color statusApprovedText = Color(0xFF065F46);
  
  /// Rejected status - Red
  static const Color statusRejected = Color(0xFFFEE2E2);
  static const Color statusRejectedText = Color(0xFF991B1B);
  
  /// Documents Requested status - Blue
  static const Color statusDocumentsRequested = Color(0xFFDBEAFE);
  static const Color statusDocumentsRequestedText = Color(0xFF1E40AF);
  
  /// Suspended status - Gray
  static const Color statusSuspended = Color(0xFFF3F4F6);
  static const Color statusSuspendedText = Color(0xFF374151);

  // ============================================
  // CHART COLORS
  // ============================================
  
  static const List<Color> chartColors = [
    Color(0xFFFF6B00), // Primary (Orange)
    Color(0xFF10B981), // Success
    Color(0xFFF59E0B), // Warning
    Color(0xFF3B82F6), // Info
    Color(0xFFEF4444), // Error
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
  ];

  // ============================================
  // SHIPMENT STATUS CHART COLORS
  // ============================================

  static const Color shipmentBidding = Color(0xFF4CAF50);
  static const Color shipmentPickupLight = primaryLight; // 0xFFFF6B00
  static const Color shipmentPickupDark = primaryDark; // 0xFFFF8C3A
  static const Color shipmentOnRouteLight = Color(0xFF216A91);
  static const Color shipmentOnRouteDark = Color(0xFF338FC0);
  static const Color shipmentDelivered = Color(0xFF9E9E9E);
  static const Color shipmentCancelledLight = errorLight; // 0xFFB00020
  static const Color shipmentCancelledDark = errorDark; // 0xFFCF6679

  /// Returns ordered list of shipment status colors for charts
  static List<Color> shipmentStatusChartColors(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return [
      shipmentBidding,
      if (isDark) shipmentPickupDark else shipmentPickupLight,
      if (isDark) shipmentOnRouteDark else shipmentOnRouteLight,
      shipmentDelivered,
      if (isDark) shipmentCancelledDark else shipmentCancelledLight,
    ];
  }

  // ============================================
  // OPACITY HELPERS
  // ============================================
  
  /// Returns color with specified opacity (0.0 to 1.0)
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
  
  /// Primary color with 85% opacity (for glass effects)
  static Color get primaryGlass => primaryLight.withValues(alpha: 0.85);
  
  /// Primary color with 50% opacity (for hints, disabled)
  static Color get primaryHint => primaryLight.withValues(alpha: 0.5);
  
  /// Primary color with 20% opacity (for subtle backgrounds)
  static Color get primarySubtle => primaryLight.withValues(alpha: 0.2);
}
