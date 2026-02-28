import 'package:flutter/material.dart';

import '../../domain/entities/admin_notification_entity.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

class NotificationTile extends StatelessWidget {
  final AdminNotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismissed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final type = notification.eventType;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimensions.spacingMd),
        color: isDark ? AppColors.errorDark : AppColors.errorLight,
        child: const Icon(Icons.archive, color: Colors.white),
      ),
      child: Material(
        color: notification.isRead
            ? Colors.transparent
            : (isDark
                ? AppColors.primaryDark.withValues(alpha: 0.08)
                : AppColors.primaryLight.withValues(alpha: 0.05)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
              vertical: AppDimensions.spacingSm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingXs),
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Icon(
                    type.icon,
                    size: AppDimensions.iconSm,
                    color: type.color,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSm),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type label + time
                      Row(
                        children: [
                          Text(
                            type.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: type.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            notification.timeAgo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingXxs),

                      // Message
                      Text(
                        notification.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.spacingXxs),

                      // Delivery method indicator
                      _buildDeliveryIndicator(context),
                    ],
                  ),
                ),

                // Unread dot
                if (!notification.isRead)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimensions.spacingXs,
                      top: AppDimensions.spacingXs,
                    ),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final method = notification.deliveryMethod;
    final iconColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (method == 'push' || method == 'both')
          Icon(Icons.notifications_active, size: 12, color: iconColor),
        if (method == 'both') const SizedBox(width: 2),
        if (method == 'sms' || method == 'both')
          Icon(Icons.sms, size: 12, color: iconColor),
      ],
    );
  }
}
