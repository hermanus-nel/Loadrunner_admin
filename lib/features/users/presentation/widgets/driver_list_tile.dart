// lib/features/users/presentation/widgets/driver_list_tile.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/driver_entity.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import 'status_badge.dart';

/// List tile widget for displaying a driver in the list
class DriverListTile extends StatelessWidget {
  final DriverEntity driver;
  final VoidCallback? onTap;
  final bool showVehicleCount;
  final bool showRegistrationDate;

  const DriverListTile({
    super.key,
    required this.driver,
    this.onTap,
    this.showVehicleCount = true,
    this.showRegistrationDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingXs,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.borderRadiusMd,
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: AppDimensions.borderWidth,
        ),
      ),
      child: InkWell(
        onTap: onTap ?? () => context.push('/users/driver/${driver.id}'),
        borderRadius: AppDimensions.borderRadiusMd,
        child: Padding(
          padding: AppDimensions.cardPadding,
          child: Row(
            children: [
              // Avatar
              _buildAvatar(context),
              const SizedBox(width: AppDimensions.spacingMd),
              
              // Driver info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            driver.fullName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingSm),
                        StatusBadge(
                          status: driver.verificationStatus.statusName,
                          size: StatusBadgeSize.small,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingXs),

                    // Phone and email
                    _buildContactInfo(context, isDark),
                    
                    if (showVehicleCount || showRegistrationDate) ...[
                      const SizedBox(height: AppDimensions.spacingXs),
                      _buildMetaInfo(context, isDark),
                    ],
                  ],
                ),
              ),
              
              // Chevron
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (driver.hasProfilePhoto) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: CachedNetworkImageProvider(driver.profilePhotoUrl!),
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        onBackgroundImageError: (_, __) {},
        child: driver.hasProfilePhoto
            ? null
            : Text(
                driver.initials,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: _getAvatarColor(driver.fullName),
      child: Text(
        driver.initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      AppColors.primaryLight,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF607D8B), // Blue Grey
    ];
    
    final index = name.isEmpty ? 0 : name.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  Widget _buildContactInfo(BuildContext context, bool isDark) {
    final textColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Row(
      children: [
        if (driver.phoneNumber != null && driver.phoneNumber!.isNotEmpty) ...[
          Icon(
            Icons.phone_outlined,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            driver.phoneNumber!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                ),
          ),
        ],
        if (driver.phoneNumber != null && 
            driver.phoneNumber!.isNotEmpty &&
            driver.email != null && 
            driver.email!.isNotEmpty) ...[
          const SizedBox(width: AppDimensions.spacingMd),
        ],
        if (driver.email != null && driver.email!.isNotEmpty)
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 14,
                  color: textColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    driver.email!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMetaInfo(BuildContext context, bool isDark) {
    final textColor = isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;

    return Row(
      children: [
        if (showVehicleCount) ...[
          Icon(
            Icons.directions_car_outlined,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${driver.vehicleCount} ${driver.vehicleCount == 1 ? 'vehicle' : 'vehicles'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                ),
          ),
        ],
        if (showVehicleCount && showRegistrationDate)
          const SizedBox(width: AppDimensions.spacingMd),
        if (showRegistrationDate) ...[
          Icon(
            Icons.calendar_today_outlined,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Joined ${_formatDate(driver.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}

/// Compact version of driver list tile
class DriverListTileCompact extends StatelessWidget {
  final DriverEntity driver;
  final VoidCallback? onTap;

  const DriverListTileCompact({
    super.key,
    required this.driver,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap ?? () => context.push('/users/driver/${driver.id}'),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primaryLight.withOpacity(0.2),
        backgroundImage: driver.hasProfilePhoto
            ? CachedNetworkImageProvider(driver.profilePhotoUrl!)
            : null,
        child: driver.hasProfilePhoto
            ? null
            : Text(
                driver.initials,
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
      title: Text(driver.fullName),
      subtitle: Text(
        driver.phoneNumber ?? driver.email ?? '',
        style: TextStyle(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
      trailing: StatusBadge(
        status: driver.verificationStatus.statusName,
        size: StatusBadgeSize.small,
      ),
    );
  }
}