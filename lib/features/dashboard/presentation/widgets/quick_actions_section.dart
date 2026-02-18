// lib/features/dashboard/presentation/widgets/quick_actions_section.dart

import 'package:flutter/material.dart';

/// Data class for quick action configuration
class QuickActionData {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final int? badgeCount;

  const QuickActionData({
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
    this.badgeCount,
  });
}

/// Quick actions section for dashboard
class QuickActionsSection extends StatelessWidget {
  final int pendingDrivers;
  final int pendingDisputes;
  final VoidCallback? onReviewDrivers;
  final VoidCallback? onViewShipments;
  final VoidCallback? onHandleDisputes;
  final VoidCallback? onSendMessage;

  const QuickActionsSection({
    super.key,
    this.pendingDrivers = 0,
    this.pendingDisputes = 0,
    this.onReviewDrivers,
    this.onViewShipments,
    this.onHandleDisputes,
    this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      QuickActionData(
        title: 'Review Drivers',
        icon: Icons.person_add_outlined,
        color: Colors.orange,
        onTap: onReviewDrivers,
        badgeCount: pendingDrivers > 0 ? pendingDrivers : null,
      ),
      QuickActionData(
        title: 'View Analytics',
        icon: Icons.analytics_outlined,
        color: Colors.blue,
        onTap: onViewShipments,
      ),
      QuickActionData(
        title: 'Handle Disputes',
        icon: Icons.warning_amber_outlined,
        color: Colors.red,
        onTap: onHandleDisputes,
        badgeCount: pendingDisputes > 0 ? pendingDisputes : null,
      ),
      QuickActionData(
        title: 'Send Message',
        icon: Icons.message_outlined,
        color: Colors.green,
        onTap: onSendMessage,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions.map((action) => QuickActionCard(data: action)).toList(),
    );
  }
}

/// Individual quick action card
class QuickActionCard extends StatelessWidget {
  final QuickActionData data;

  const QuickActionCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: data.color.withOpacity(isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: data.color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon with optional badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: data.color.withOpacity(isDark ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      data.icon,
                      size: 20,
                      color: data.color,
                    ),
                  ),
                  if (data.badgeCount != null)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          data.badgeCount! > 99
                              ? '99+'
                              : data.badgeCount.toString(),
                          style: TextStyle(
                            color: colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  data.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact action button for use in app bar or other tight spaces
class CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final int? badgeCount;

  const CompactActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 20, color: color),
                  if (badgeCount != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          badgeCount! > 9 ? '9+' : badgeCount.toString(),
                          style: TextStyle(
                            color: colorScheme.onError,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
