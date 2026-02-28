// lib/features/shippers/presentation/widgets/shipper_tile.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/shipper_entity.dart';

class ShipperTile extends StatelessWidget {
  final ShipperEntity shipper;
  final VoidCallback? onTap;

  const ShipperTile({
    super.key,
    required this.shipper,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(theme),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shipper.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(theme),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Contact info
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          shipper.phoneNumber,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        if (shipper.email != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.email,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shipper.email!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Stats row
                    if (shipper.stats != null) _buildStatsRow(theme),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: shipper.isCurrentlySuspended
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.primaryContainer,
          backgroundImage: shipper.profilePhotoUrl != null
              ? CachedNetworkImageProvider(shipper.profilePhotoUrl!)
              : null,
          child: shipper.profilePhotoUrl == null
              ? Text(
                  shipper.initials,
                  style: TextStyle(
                    color: shipper.isCurrentlySuspended
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        if (shipper.isRecentlyActive)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    final isActive = !shipper.isCurrentlySuspended;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : theme.colorScheme.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        shipper.statusString,
        style: TextStyle(
          color: isActive ? Colors.green : theme.colorScheme.error,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    final stats = shipper.stats!;
    return Row(
      children: [
        _StatChip(
          icon: Icons.local_shipping,
          value: '${stats.totalShipments}',
          label: 'Shipments',
          theme: theme,
        ),
        const SizedBox(width: 12),
        _StatChip(
          icon: Icons.attach_money,
          value: 'R${_formatAmount(stats.totalSpent)}',
          label: 'Spent',
          theme: theme,
        ),
        if (stats.ratingsCount > 0) ...[
          const SizedBox(width: 12),
          _StatChip(
            icon: Icons.star,
            value: stats.averageRating.toStringAsFixed(1),
            label: 'Rating',
            theme: theme,
            iconColor: Colors.amber,
          ),
        ],
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final ThemeData theme;
  final Color? iconColor;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.theme,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: iconColor ?? theme.colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Compact version for smaller spaces
class ShipperTileCompact extends StatelessWidget {
  final ShipperEntity shipper;
  final VoidCallback? onTap;

  const ShipperTileCompact({
    super.key,
    required this.shipper,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: shipper.isCurrentlySuspended
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.primaryContainer,
        backgroundImage: shipper.profilePhotoUrl != null
            ? CachedNetworkImageProvider(shipper.profilePhotoUrl!)
            : null,
        child: shipper.profilePhotoUrl == null
            ? Text(
                shipper.initials,
                style: TextStyle(
                  color: shipper.isCurrentlySuspended
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onPrimaryContainer,
                ),
              )
            : null,
      ),
      title: Text(
        shipper.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        shipper.phoneNumber,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      trailing: shipper.isCurrentlySuspended
          ? Icon(Icons.block, color: theme.colorScheme.error, size: 20)
          : const Icon(Icons.chevron_right),
    );
  }
}

/// Status badge widget
class ShipperStatusBadge extends StatelessWidget {
  final ShipperEntity shipper;
  final bool compact;

  const ShipperStatusBadge({
    super.key,
    required this.shipper,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = !shipper.isCurrentlySuspended;

    if (compact) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? Colors.green : theme.colorScheme.error,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.block,
            size: 16,
            color: isActive ? Colors.green : theme.colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            shipper.statusString,
            style: TextStyle(
              color: isActive ? Colors.green : theme.colorScheme.error,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Activity indicator
class ShipperActivityIndicator extends StatelessWidget {
  final ShipperEntity shipper;

  const ShipperActivityIndicator({super.key, required this.shipper});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String activityText;
    Color activityColor;

    if (shipper.lastLoginAt == null) {
      activityText = 'Never logged in';
      activityColor = theme.colorScheme.outline;
    } else {
      final daysSinceLogin = DateTime.now().difference(shipper.lastLoginAt!).inDays;
      if (daysSinceLogin == 0) {
        activityText = 'Active today';
        activityColor = Colors.green;
      } else if (daysSinceLogin <= 7) {
        activityText = 'Active ${daysSinceLogin}d ago';
        activityColor = Colors.green;
      } else if (daysSinceLogin <= 30) {
        activityText = 'Active ${daysSinceLogin}d ago';
        activityColor = Colors.orange;
      } else {
        activityText = 'Inactive ${daysSinceLogin}d';
        activityColor = theme.colorScheme.error;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: activityColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          activityText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: activityColor,
          ),
        ),
      ],
    );
  }
}
