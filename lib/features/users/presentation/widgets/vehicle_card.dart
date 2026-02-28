// lib/features/users/presentation/widgets/vehicle_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/vehicle_entity.dart';
import 'status_badge.dart';

/// Widget displaying a vehicle card with basic info and expandable details
class VehicleCard extends StatefulWidget {
  final VehicleEntity vehicle;
  final VoidCallback? onTap;
  final bool showExpandedByDefault;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.showExpandedByDefault = false,
  });

  @override
  State<VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.showExpandedByDefault;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vehicle = widget.vehicle;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main content row
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Vehicle image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 60,
                      child: _buildVehicleImage(context),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Vehicle info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Make and model
                        Text(
                          vehicle.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Plate number
                        Row(
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 14,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                vehicle.licensePlate,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Type and capacity
                        Row(
                          children: [
                            Flexible(
                              child: _buildInfoChip(
                                context,
                                Icons.local_shipping_outlined,
                                vehicle.type,
                              ),
                            ),
                            if (vehicle.capacityTons != null) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: _buildInfoChip(
                                  context,
                                  Icons.scale_outlined,
                                  '${vehicle.capacityTons!.toStringAsFixed(1)} tons',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status and arrow
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(
                        status: vehicle.verificationStatus,
                        size: StatusBadgeSize.small,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Document count indicator
                          if (vehicle.documentsCount > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.folder_outlined,
                                    size: 12,
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${vehicle.documentsCount}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          // Expand/navigate arrow
                          GestureDetector(
                            onTap: () => setState(() => _isExpanded = !_isExpanded),
                            child: Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Expanded content
            if (_isExpanded) ...[
              Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: _buildExpandedContent(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleImage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vehicle = widget.vehicle;

    if (vehicle.photoUrl == null || vehicle.photoUrl!.isEmpty) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.local_shipping_outlined,
          color: colorScheme.onSurface.withValues(alpha: 0.3),
          size: 32,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: vehicle.photoUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: colorScheme.surfaceContainerHighest,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.local_shipping_outlined,
          color: colorScheme.onSurface.withValues(alpha: 0.3),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vehicle = widget.vehicle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Additional vehicle info
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            if (vehicle.year != null)
              _buildDetailItem(context, 'Year', vehicle.year.toString()),
            if (vehicle.color != null)
              _buildDetailItem(context, 'Color', vehicle.color!),
            _buildDetailItem(context, 'Make', vehicle.make),
            _buildDetailItem(context, 'Model', vehicle.model),
          ],
        ),

        const SizedBox(height: 12),

        // Documents status
        Row(
          children: [
            Icon(
              Icons.folder_outlined,
              size: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              'Documents: ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            _buildDocumentIndicator(
              context,
              'Reg',
              vehicle.registrationDocumentUrl != null,
            ),
            const SizedBox(width: 8),
            _buildDocumentIndicator(
              context,
              'Ins',
              vehicle.insuranceDocumentUrl != null,
            ),
            const SizedBox(width: 8),
            _buildDocumentIndicator(
              context,
              'RWC',
              vehicle.roadworthyCertificateUrl != null,
            ),
          ],
        ),

        // Rejection reason (if rejected)
        if (vehicle.isRejected && vehicle.rejectionReason != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vehicle.rejectionReason!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],

        // View details button
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onTap,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('View Full Details'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentIndicator(BuildContext context, String label, bool hasDocument) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: hasDocument
            ? Colors.green.withValues(alpha: 0.1)
            : colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: hasDocument
              ? Colors.green.withValues(alpha: 0.3)
              : colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasDocument ? Icons.check : Icons.close,
            size: 10,
            color: hasDocument ? Colors.green : colorScheme.error,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: hasDocument ? Colors.green : colorScheme.error,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact vehicle card for list views
class CompactVehicleCard extends StatelessWidget {
  final VehicleEntity vehicle;
  final VoidCallback? onTap;

  const CompactVehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            // Vehicle image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 45,
                child: _buildVehicleImage(context),
              ),
            ),
            const SizedBox(width: 12),

            // Vehicle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vehicle.licensePlate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Status
            StatusBadge(
              status: vehicle.verificationStatus,
              size: StatusBadgeSize.small,
            ),

            const SizedBox(width: 4),

            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleImage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (vehicle.photoUrl == null || vehicle.photoUrl!.isEmpty) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.local_shipping_outlined,
          color: colorScheme.onSurface.withValues(alpha: 0.3),
          size: 24,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: vehicle.photoUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: colorScheme.surfaceContainerHighest,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.local_shipping_outlined,
          color: colorScheme.onSurface.withValues(alpha: 0.3),
          size: 24,
        ),
      ),
    );
  }
}
