// lib/features/users/presentation/screens/vehicle_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/components/document_viewer_screen.dart';
import '../../../../core/components/loading_state.dart';
import '../../../../core/components/document_viewer_state.dart';
import '../../../messages/domain/entities/message_entity.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/repositories/vehicles_repository.dart';
import '../providers/vehicle_providers.dart';
import '../widgets/status_badge.dart';
import '../widgets/info_section.dart';
import '../widgets/vehicle_approval_timeline.dart';

/// Screen displaying full vehicle details with approval actions
class VehicleDetailScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const VehicleDetailScreen({
    super.key,
    required this.vehicleId,
  });

  @override
  ConsumerState<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> {
  int _currentPhotoIndex = 0;
  late PageController _photoPageController;

  @override
  void initState() {
    super.initState();
    _photoPageController = PageController();
    // Load vehicle data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vehicleDetailControllerProvider(widget.vehicleId).notifier).loadVehicle();
    });
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    super.dispose();
  }

  Future<void> _refreshVehicle() async {
    await ref.read(vehicleDetailControllerProvider(widget.vehicleId).notifier).loadVehicle();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _handleApprove(VehicleEntity vehicle) async {
    final confirmed = await _showApproveDialog(vehicle);
    if (!confirmed || !mounted) return;

    final success = await ref
        .read(vehicleDetailControllerProvider(widget.vehicleId).notifier)
        .approveVehicle();

    if (success) {
      _showSnackBar('✅ ${vehicle.displayName} has been approved!');
    } else {
      _showSnackBar('Failed to approve vehicle. Please try again.', isError: true);
    }
  }

  Future<void> _handleReject(VehicleEntity vehicle) async {
    final result = await _showRejectDialog(vehicle);
    if (result == null || !mounted) return;

    final success = await ref
        .read(vehicleDetailControllerProvider(widget.vehicleId).notifier)
        .rejectVehicle(reason: result['reason']!, notes: result['notes']);

    if (success) {
      _showSnackBar('❌ ${vehicle.displayName} has been rejected.');
    } else {
      _showSnackBar('Failed to reject vehicle. Please try again.', isError: true);
    }
  }

  Future<void> _handleRequestDocuments(VehicleEntity vehicle) async {
    final result = await _showRequestDocumentsDialog(vehicle);
    if (result == null || !mounted) return;

    final success = await ref
        .read(vehicleDetailControllerProvider(widget.vehicleId).notifier)
        .requestDocuments(
          documentTypes: result['documents'] as List<String>,
          message: result['message'] as String,
        );

    if (success) {
      _showSnackBar('📤 Document request sent to driver');
    } else {
      _showSnackBar('Failed to send request. Please try again.', isError: true);
    }
  }

  Future<void> _handleMarkUnderReview(VehicleEntity vehicle) async {
    final result = await _showUnderReviewDialog(vehicle);
    if (result == null || !mounted) return;

    final success = await ref
        .read(vehicleDetailControllerProvider(widget.vehicleId).notifier)
        .markUnderReview(notes: result['notes']);

    if (success) {
      _showSnackBar('🔵 ${vehicle.displayName} marked as under review');
    } else {
      _showSnackBar('Failed to update vehicle. Please try again.', isError: true);
    }
  }

  Future<void> _handleSuspend(VehicleEntity vehicle) async {
    final result = await _showSuspendDialog(vehicle);
    if (result == null || !mounted) return;

    final success = await ref
        .read(vehicleDetailControllerProvider(widget.vehicleId).notifier)
        .suspendVehicle(reason: result['reason']!, notes: result['notes']);

    if (success) {
      _showSnackBar('⚠️ ${vehicle.displayName} has been suspended.');
    } else {
      _showSnackBar('Failed to suspend vehicle. Please try again.', isError: true);
    }
  }

  Future<void> _handleReinstate(VehicleEntity vehicle) async {
    final result = await _showReinstateDialog(vehicle);
    if (result == null || !mounted) return;

    final success = await ref
        .read(vehicleDetailControllerProvider(widget.vehicleId).notifier)
        .reinstateVehicle(notes: result['notes']);

    if (success) {
      _showSnackBar('🟢 ${vehicle.displayName} has been reinstated!');
    } else {
      _showSnackBar('Failed to reinstate vehicle. Please try again.', isError: true);
    }
  }

  void _navigateToMessageDriver(VehicleEntity vehicle) {
    final recipient = MessageUserInfo(
      id: vehicle.driverId,
      fullName: vehicle.driverName,
      phone: vehicle.driverPhone,
      role: 'Driver',
    );
    context.push('/messages/compose', extra: {'recipient': recipient});
  }

  void _openDocumentViewer(List<String> urls, int initialIndex) {
    context.pushDocumentViewer(
      documents: urls
          .map((url) => ViewerDocument(url: url))
          .toList(),
      initialIndex: initialIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleDetailControllerProvider(widget.vehicleId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Vehicle Details'),
        actions: [
          if (state.vehicle != null)
            IconButton(
              icon: const Icon(Icons.message_outlined),
              onPressed: state.isProcessing
                  ? null
                  : () => _navigateToMessageDriver(state.vehicle!),
              tooltip: 'Message Driver',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.isProcessing ? null : _refreshVehicle,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(context, state),
      bottomNavigationBar: state.vehicle != null
          ? _buildActionBar(context, state.vehicle!)
          : null,
    );
  }

  Widget _buildBody(BuildContext context, VehicleDetailState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (state.isLoading && state.vehicle == null) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Photo gallery shimmer
            ShimmerPlaceholder(width: double.infinity, height: 200),
            SizedBox(height: 16),
            // Vehicle info shimmer
            ShimmerCard(height: 120),
            SizedBox(height: 12),
            // Details shimmer
            ShimmerCard(height: 140),
            SizedBox(height: 12),
            ShimmerCard(height: 100),
          ],
        ),
      );
    }

    if (state.error != null && state.vehicle == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('Error loading vehicle', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(state.error!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _refreshVehicle,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final vehicle = state.vehicle!;

    return RefreshIndicator(
      onRefresh: _refreshVehicle,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Gallery
            _buildPhotoGallery(context, vehicle),

            const SizedBox(height: 16),

            // Vehicle Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildVehicleHeader(context, vehicle),
            ),

            const SizedBox(height: 16),

            // Vehicle Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildVehicleInfoSection(context, vehicle),
            ),

            const SizedBox(height: 16),

            // Driver Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDriverInfoSection(context, vehicle),
            ),
            const SizedBox(height: 16),

            // Documents Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDocumentsSection(context, vehicle),
            ),

            const SizedBox(height: 16),

            // Rejection/Suspension Reason
            if ((vehicle.isRejected || vehicle.isSuspended) && vehicle.rejectionReason != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildRejectionSection(context, vehicle),
              ),
              const SizedBox(height: 16),
            ],

            // Admin Notes (if any)
            if (vehicle.adminNotes != null && vehicle.adminNotes!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildNotesSection(context, vehicle),
              ),
              const SizedBox(height: 16),
            ],

            // Approval History
            if (state.history.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: VehicleApprovalTimeline(
                  history: state.history,
                  maxItems: 5,
                  onViewAll: () => _showFullHistoryDialog(context, state.history),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGallery(BuildContext context, VehicleEntity vehicle) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final photos = vehicle.allPhotoUrls;

    if (photos.isEmpty) {
      return Container(
        height: 250,
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 64,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'No photos available',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Photo PageView
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _photoPageController,
            itemCount: photos.length,
            onPageChanged: (index) {
              setState(() => _currentPhotoIndex = index);
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openDocumentViewer(photos, index),
                child: CachedNetworkImage(
                  imageUrl: photos[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: colorScheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Page indicator
        if (photos.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentPhotoIndex + 1} / ${photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Tap hint
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.zoom_in, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Tap to zoom',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleHeader(BuildContext context, VehicleEntity vehicle) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicle.licensePlate,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: vehicle.verificationStatus),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  context,
                  Icons.local_shipping_outlined,
                  vehicle.type,
                ),
                if (vehicle.capacityTons != null)
                  _buildInfoChip(
                    context,
                    Icons.scale_outlined,
                    '${vehicle.capacityTons!.toStringAsFixed(1)} tons',
                  ),
                if (vehicle.color != null)
                  _buildInfoChip(
                    context,
                    Icons.palette_outlined,
                    vehicle.color!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoSection(BuildContext context, VehicleEntity vehicle) {
    return InfoSection(
      title: 'Vehicle Information',
      icon: Icons.directions_car_outlined,
      items: [
        InfoItem(label: 'Make', value: vehicle.make),
        InfoItem(label: 'Model', value: vehicle.model),
        if (vehicle.year != null)
          InfoItem(label: 'Year', value: vehicle.year.toString()),
        InfoItem(label: 'Plate', value: vehicle.licensePlate),
        if (vehicle.color != null)
          InfoItem(label: 'Color', value: vehicle.color!),
        InfoItem(label: 'Type', value: vehicle.type),
        if (vehicle.capacityTons != null)
          InfoItem(label: 'Capacity', value: '${vehicle.capacityTons!.toStringAsFixed(1)} tons'),
        if (vehicle.createdAt != null)
          InfoItem(
            label: 'Registered',
            value: _formatDateTime(vehicle.createdAt!),
          ),
        if (vehicle.verifiedAt != null)
          InfoItem(
            label: 'Verified At',
            value: _formatDateTime(vehicle.verifiedAt!),
          ),
      ],
    );
  }

  Widget _buildDriverInfoSection(BuildContext context, VehicleEntity vehicle) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Driver Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.message_outlined, size: 16),
                  label: const Text('Message'),
                  onPressed: () => _navigateToMessageDriver(vehicle),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Profile'),
                  onPressed: () => context.push('/users/driver/${vehicle.driverId}'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 24),
            if (vehicle.driverName != null)
              _buildDriverInfoRow(theme, 'Name', vehicle.driverName!),
            if (vehicle.driverPhone != null)
              _buildDriverInfoRow(theme, 'Phone', vehicle.driverPhone!),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(BuildContext context, VehicleEntity vehicle) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final documents = vehicle.documentUrls;

    // All expected documents with their upload status
    final expectedDocs = <String, String?>{
      'Registration': vehicle.registrationDocumentUrl,
      'Insurance': vehicle.insuranceDocumentUrl,
      'Roadworthy': vehicle.roadworthyCertificateUrl,
    };
    final missingDocs = expectedDocs.entries
        .where((e) => e.value == null)
        .map((e) => e.key)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Documents', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  '${documents.length}/3 uploaded',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Missing documents warning
            if (missingDocs.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber, size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Missing Documents (${missingDocs.length})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            missingDocs.join(', '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Show all expected documents
            ...expectedDocs.entries.map((doc) {
              if (doc.value != null) {
                return _buildDocumentTile(
                  context,
                  doc.key,
                  doc.value!,
                  vehicle.getDocStatus(doc.key),
                );
              } else {
                return _buildMissingDocumentTile(context, doc.key);
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTile(
    BuildContext context,
    String label,
    String url,
    String? docStatus,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine badge label and color based on per-doc status
    String badgeLabel;
    Color badgeColor;
    switch (docStatus) {
      case 'approved':
        badgeLabel = 'Approved';
        badgeColor = Colors.green;
        break;
      case 'rejected':
        badgeLabel = 'Rejected';
        badgeColor = Colors.red;
        break;
      case 'documents_requested':
        badgeLabel = 'Re-upload Requested';
        badgeColor = Colors.orange;
        break;
      case 'pending':
        badgeLabel = 'Pending Review';
        badgeColor = Colors.orange;
        break;
      default:
        badgeLabel = 'Pending Review';
        badgeColor = Colors.orange;
        break;
    }

    // Append doc status as query param to bust HTTP / CDN caches when the
    // driver re-uploads to the same storage path (URL unchanged, status flips).
    final separator = url.contains('?') ? '&' : '?';
    final cacheBustUrl = '$url${separator}v=${docStatus ?? 'unknown'}';

    return InkWell(
      onTap: () {
        context.push(
          '/users/vehicle/${widget.vehicleId}/document-review',
          extra: {
            'docType': label,
            'docUrl': cacheBustUrl,
            'currentStatus': docStatus,
          },
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: CachedNetworkImage(
                  imageUrl: cacheBustUrl,
                  cacheKey: cacheBustUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, _, __) => Container(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.description_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Tap to review',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                badgeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
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

  Widget _buildMissingDocumentTile(BuildContext context, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.error.withValues(alpha: 0.4),
                style: BorderStyle.solid,
              ),
              color: colorScheme.error.withValues(alpha: 0.05),
            ),
            child: Icon(
              Icons.file_present_outlined,
              color: colorScheme.error.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Not uploaded',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Missing',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionSection(BuildContext context, VehicleEntity vehicle) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSuspended = vehicle.isSuspended;
    final sectionTitle = isSuspended ? 'Suspension Reason' : 'Rejection Reason';
    final sectionIcon = isSuspended ? Icons.block : Icons.cancel_outlined;

    return Card(
      color: colorScheme.error.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(sectionIcon, color: colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  sectionTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                vehicle.rejectionReason!,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, VehicleEntity vehicle) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Admin Notes', style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                vehicle.adminNotes!,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, VehicleEntity vehicle) {
    final theme = Theme.of(context);
    final state = ref.watch(vehicleDetailControllerProvider(widget.vehicleId));
    final isProcessing = state.isProcessing;

    final buttons = _buildActionButtons(vehicle, isProcessing, theme);
    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: buttons
              .expand((w) => [Expanded(child: w), const SizedBox(width: 8)])
              .toList()
            ..removeLast(), // Remove trailing SizedBox
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(
    VehicleEntity vehicle,
    bool isProcessing,
    ThemeData theme,
  ) {
    switch (vehicle.verificationStatus) {
      case 'pending':
        return [
          OutlinedButton.icon(
            onPressed: isProcessing ? null : () => _handleMarkUnderReview(vehicle),
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('Review'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: isProcessing ? null : () => _handleReject(vehicle),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          _buildApproveButton(vehicle, isProcessing),
        ];

      case 'under_review':
        return [
          OutlinedButton.icon(
            onPressed: isProcessing ? null : () => _handleRequestDocuments(vehicle),
            icon: const Icon(Icons.file_upload_outlined, size: 18),
            label: const Text('Request Docs'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: isProcessing ? null : () => _handleReject(vehicle),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          _buildApproveButton(vehicle, isProcessing),
        ];

      case 'documents_requested':
        return [
          OutlinedButton.icon(
            onPressed: isProcessing ? null : () => _handleRequestDocuments(vehicle),
            icon: const Icon(Icons.file_upload_outlined, size: 18),
            label: const Text('Request Docs'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: isProcessing ? null : () => _handleReject(vehicle),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          _buildApproveButton(vehicle, isProcessing),
        ];

      case 'rejected':
        return [
          OutlinedButton.icon(
            onPressed: isProcessing ? null : () => _handleRequestDocuments(vehicle),
            icon: const Icon(Icons.file_upload_outlined, size: 18),
            label: const Text('Request Docs'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          _buildApproveButton(vehicle, isProcessing),
        ];

      case 'approved':
        return [
          OutlinedButton.icon(
            onPressed: isProcessing ? null : () => _handleSuspend(vehicle),
            icon: const Icon(Icons.block, size: 18),
            label: const Text('Suspend'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.brown,
              side: const BorderSide(color: Colors.brown),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ];

      case 'suspended':
        return [
          OutlinedButton.icon(
            onPressed: isProcessing ? null : () => _handleReinstate(vehicle),
            icon: isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.green,
                    ),
                  )
                : const Icon(Icons.restore, size: 18),
            label: const Text('Reinstate'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ];

      default:
        return [];
    }
  }

  Widget _buildApproveButton(VehicleEntity vehicle, bool isProcessing) {
    return OutlinedButton.icon(
      onPressed: isProcessing ? null : () => _handleApprove(vehicle),
      icon: isProcessing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.green,
              ),
            )
          : const Icon(Icons.check, size: 18),
      label: const Text('Approve'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.green,
        side: const BorderSide(color: Colors.green),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  // ==========================================================================
  // DIALOGS
  // ==========================================================================

  Future<bool> _showApproveDialog(VehicleEntity vehicle) async {
    final theme = Theme.of(context);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
        ),
        title: const Text('Approve Vehicle', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to approve', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              vehicle.displayName,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The driver will be notified and can use this vehicle for deliveries.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approve'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );

    return result ?? false;
  }

  Future<Map<String, String?>?> _showRejectDialog(VehicleEntity vehicle) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    String? selectedReason;
    final customReasonController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final rejectionReasons = [
      'Invalid or expired documents',
      'Poor document quality',
      'Vehicle does not meet requirements',
      'Insurance not valid',
      'Registration expired',
      'Photos unclear or missing',
      'Other (specify below)',
    ];

    final result = await showDialog<Map<String, String?>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cancel_outlined, size: 48, color: colorScheme.error),
          ),
          title: const Text('Reject Vehicle', textAlign: TextAlign.center),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      vehicle.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Rejection Reason *', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    decoration: InputDecoration(
                      hintText: 'Select a reason',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    isExpanded: true,
                    items: rejectionReasons.map((reason) {
                      return DropdownMenuItem(value: reason, child: Text(reason));
                    }).toList(),
                    onChanged: (value) => setState(() => selectedReason = value),
                    validator: (value) => value == null ? 'Please select a reason' : null,
                  ),
                  if (selectedReason == 'Other (specify below)') ...[
                    const SizedBox(height: 16),
                    Text('Specify Reason *', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: customReasonController,
                      decoration: InputDecoration(
                        hintText: 'Enter the rejection reason',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      maxLines: 2,
                      maxLength: 200,
                      validator: (value) {
                        if (selectedReason == 'Other (specify below)') {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please specify the reason';
                          }
                          if (value.trim().length < 10) {
                            return 'Reason must be at least 10 characters';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text('Notes (Optional)', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: notesController,
                    decoration: InputDecoration(
                      hintText: 'Internal notes',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 2,
                    maxLength: 500,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final reason = selectedReason == 'Other (specify below)'
                      ? customReasonController.text.trim()
                      : selectedReason!;
                  Navigator.of(context).pop({
                    'reason': reason,
                    'notes': notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  });
                }
              },
              icon: const Icon(Icons.cancel, size: 18),
              label: const Text('Reject'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      ),
    );

    customReasonController.dispose();
    notesController.dispose();
    return result;
  }

  Future<Map<String, dynamic>?> _showRequestDocumentsDialog(VehicleEntity vehicle) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedDocuments = <String>{};
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final documentTypes = [
      'Vehicle Photo',
      'Registration Document',
      'Insurance Certificate',
      'Roadworthy Certificate',
      'Front Photo',
      'Back Photo',
      'Side Photos',
      'Cargo Area Photo',
    ];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.file_upload_outlined, size: 48, color: Colors.orange),
          ),
          title: const Text('Request Documents', textAlign: TextAlign.center),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        vehicle.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Select Documents to Request *', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    ...documentTypes.map((doc) {
                      final isSelected = selectedDocuments.contains(doc);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(doc),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedDocuments.add(doc);
                            } else {
                              selectedDocuments.remove(doc);
                            }
                          });
                        },
                      );
                    }),
                    if (selectedDocuments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: Text(
                          'Please select at least one document',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text('Message to Driver *', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Explain why these documents are needed...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      maxLines: 3,
                      maxLength: 500,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide a message';
                        }
                        if (value.trim().length < 20) {
                          return 'Message must be at least 20 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: selectedDocuments.isEmpty
                  ? null
                  : () {
                      if (formKey.currentState?.validate() ?? false) {
                        Navigator.of(context).pop({
                          'documents': selectedDocuments.toList(),
                          'message': messageController.text.trim(),
                        });
                      }
                    },
              icon: const Icon(Icons.send, size: 18),
              label: Text('Request (${selectedDocuments.length})'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      ),
    );

    messageController.dispose();
    return result;
  }

  Future<Map<String, String?>?> _showUnderReviewDialog(VehicleEntity vehicle) async {
    final theme = Theme.of(context);
    final notesController = TextEditingController();

    final result = await showDialog<Map<String, String?>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.visibility, size: 48, color: Colors.blue),
        ),
        title: const Text('Mark as Under Review', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mark this vehicle for detailed review?', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              vehicle.displayName,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The driver will be notified their vehicle is being reviewed.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Notes (Optional)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: notesController,
              decoration: InputDecoration(
                hintText: 'Internal notes',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 2,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop({
                'notes': notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              });
            },
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('Mark Under Review'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );

    notesController.dispose();
    return result;
  }

  Future<Map<String, String?>?> _showSuspendDialog(VehicleEntity vehicle) async {
    final theme = Theme.of(context);
    final reasonController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String?>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.brown.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.block, size: 48, color: Colors.brown),
        ),
        title: const Text('Suspend Vehicle', textAlign: TextAlign.center),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    vehicle.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.brown.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.brown.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, size: 20, color: Colors.brown),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The driver will no longer be able to use this vehicle for deliveries.',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.brown[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Suspension Reason *', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: 'Enter the reason for suspension',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 2,
                  maxLength: 300,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a reason';
                    }
                    if (value.trim().length < 10) {
                      return 'Reason must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('Notes (Optional)', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: notesController,
                  decoration: InputDecoration(
                    hintText: 'Internal notes',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 2,
                  maxLength: 500,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop({
                  'reason': reasonController.text.trim(),
                  'notes': notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                });
              }
            },
            icon: const Icon(Icons.block, size: 18),
            label: const Text('Suspend'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );

    reasonController.dispose();
    notesController.dispose();
    return result;
  }

  Future<Map<String, String?>?> _showReinstateDialog(VehicleEntity vehicle) async {
    final theme = Theme.of(context);
    final notesController = TextEditingController();

    final result = await showDialog<Map<String, String?>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.restore, size: 48, color: Colors.green),
        ),
        title: const Text('Reinstate Vehicle', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reinstate this suspended vehicle?', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              vehicle.displayName,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The vehicle will be restored to approved status and the driver can use it for deliveries again.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Notes (Optional)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: notesController,
              decoration: InputDecoration(
                hintText: 'Internal notes',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 2,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop({
                'notes': notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              });
            },
            icon: const Icon(Icons.restore, size: 18),
            label: const Text('Reinstate'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );

    notesController.dispose();
    return result;
  }

  void _showFullHistoryDialog(BuildContext context, List<VehicleApprovalHistoryItem> history) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.history, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Full Approval History'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: VehicleApprovalTimeline(
              history: history,
              maxItems: history.length, // Show all
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
