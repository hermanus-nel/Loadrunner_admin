// lib/features/users/presentation/screens/driver_profile_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/components/document_viewer_screen.dart';
import '../../../../core/components/loading_state.dart';
import '../../../../core/components/document_viewer_state.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../messages/domain/entities/message_entity.dart';
import '../../domain/entities/driver_profile.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/driver_document.dart';
import '../../domain/entities/approval_history_item.dart';
import '../../domain/entities/document_queue_item.dart';
import '../providers/driver_profile_providers.dart';
import '../providers/document_queue_providers.dart';
import '../providers/vehicle_providers.dart';
import '../widgets/profile_header.dart';
import '../widgets/info_section.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/approval_timeline.dart';
import '../widgets/approve_confirm_dialog.dart';
import '../widgets/request_documents_dialog.dart';

/// Tracks which action button is currently processing.
enum _ActionType { none, approve, requestDocs, approveDocs, approveVehicles }

/// Screen displaying full driver profile with approval actions
class DriverProfileScreen extends ConsumerStatefulWidget {
  final String driverId;

  const DriverProfileScreen({
    super.key,
    required this.driverId,
  });

  @override
  ConsumerState<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  _ActionType _activeAction = _ActionType.none;
  bool get _isProcessing => _activeAction != _ActionType.none;

  @override
  void initState() {
    super.initState();
    // Load driver profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverProfileControllerProvider(widget.driverId).notifier).loadProfile();
    });
  }

  Future<void> _refreshProfile() async {
    await ref.read(driverProfileControllerProvider(widget.driverId).notifier).loadProfile();
  }

  void _navigateToMessageDriver(DriverProfile profile) {
    final recipient = MessageUserInfo(
      id: profile.id,
      fullName: profile.displayName,
      phone: profile.phoneNumber,
      email: profile.email,
      role: 'Driver',
      profilePhotoUrl: profile.profilePhotoUrl,
    );
    context.push('/messages/compose', extra: {'recipient': recipient});
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

  Future<void> _handleApprove(DriverProfile profile) async {
    final profileData = ref
        .read(driverProfileControllerProvider(widget.driverId))
        .valueOrNull;
    if (profileData == null) return;

    // Check for unapproved documents (any uploaded doc that isn't 'approved')
    final unapprovedDocs = profileData.documents
        .where((d) => d.verificationStatus != 'approved')
        .toList();

    // Check for unapproved vehicles
    final unapprovedVehicles = profileData.vehicles
        .where((v) => !v.isApproved)
        .toList();

    // If anything is outstanding, show blocker dialog
    if (unapprovedDocs.isNotEmpty || unapprovedVehicles.isNotEmpty) {
      _showApprovalBlockerDialog(unapprovedDocs, unapprovedVehicles);
      return;
    }

    final driverName = '${profile.firstName} ${profile.lastName}';

    final confirmed = await ApproveConfirmDialog.show(
      context: context,
      driverName: driverName,
    );

    if (!confirmed || !mounted) return;

    setState(() => _activeAction = _ActionType.approve);

    try {
      final success = await ref
          .read(driverProfileControllerProvider(widget.driverId).notifier)
          .approveDriver();

      if (success) {
        _showSnackBar('✅ $driverName has been approved successfully!');
        await _refreshProfile();
      } else {
        _showSnackBar('Failed to approve driver. Please try again.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _activeAction = _ActionType.none);
    }
  }

  Future<void> _handleRequestDocuments(DriverProfile profile) async {
    final driverName = '${profile.firstName} ${profile.lastName}';

    final result = await RequestDocumentsDialog.show(
      context: context,
      driverName: driverName,
    );

    if (result == null || !mounted) return;

    setState(() => _activeAction = _ActionType.requestDocs);

    try {
      final success = await ref
          .read(driverProfileControllerProvider(widget.driverId).notifier)
          .requestDocuments(
            documentTypes: result.requestedDocuments,
            message: result.message,
          );

      if (success) {
        _showSnackBar('📤 Document request sent to $driverName');
        await _refreshProfile();
      } else {
        _showSnackBar('Failed to send document request. Please try again.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _activeAction = _ActionType.none);
    }
  }

  Future<void> _handleApproveDocs(DriverProfile profile) async {
    final driverName = '${profile.firstName} ${profile.lastName}';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.done_all,
              size: 48,
              color: Colors.blue,
            ),
          ),
          title: const Text(
            'Approve Documents',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bulk-approve all pending driver documents for',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                driverName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will mark all pending personal documents (ID, license, PDP, etc.) as approved. It does not change the driver\'s verification status.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Approve'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      },
    ) ?? false;

    if (!confirmed || !mounted) return;

    setState(() => _activeAction = _ActionType.approveDocs);

    try {
      final docReviewRepo = ref.read(documentReviewRepositoryProvider);
      final adminId = await docReviewRepo.getCurrentAdminId();
      if (adminId == null) {
        _showSnackBar('Unable to identify admin user', isError: true);
        return;
      }

      final success = await docReviewRepo.approveAllDocuments(
        driverId: widget.driverId,
        adminId: adminId,
      );

      if (success) {
        _showSnackBar('Documents for $driverName approved');
        await _refreshProfile();
      } else {
        _showSnackBar(
          'Failed to approve documents. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _activeAction = _ActionType.none);
    }
  }

  Future<void> _handleApproveVehicles(DriverProfile profile) async {
    final driverName = '${profile.firstName} ${profile.lastName}';
    final profileData = ref
        .read(driverProfileControllerProvider(widget.driverId))
        .valueOrNull;
    final pendingVehicles = profileData?.vehicles
            .where((v) => v.isActionable)
            .toList() ??
        [];

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping,
              size: 48,
              color: Colors.purple,
            ),
          ),
          title: const Text(
            'Approve Vehicles',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Approve all pending vehicles and their documents for',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                driverName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ...pendingVehicles.map(
                (v) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 16,
                        color: Colors.purple[400],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${v.displayName} (${v.licensePlate})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.purple.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Each vehicle will be approved along with its registration, insurance, and roadworthy documents.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.purple[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.local_shipping, size: 18),
              label: const Text('Approve'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      },
    ) ?? false;

    if (!confirmed || !mounted) return;

    setState(() => _activeAction = _ActionType.approveVehicles);

    try {
      final vehiclesRepo = ref.read(vehiclesRepositoryProvider);
      final adminId =
          await ref.read(documentReviewRepositoryProvider).getCurrentAdminId();
      if (adminId == null) {
        _showSnackBar('Unable to identify admin user', isError: true);
        return;
      }

      var approvedCount = 0;
      for (final vehicle in pendingVehicles) {
        try {
          // Approve the vehicle itself
          await vehiclesRepo.approveVehicle(
            vehicleId: vehicle.id,
            adminId: adminId,
          );

          // Approve any pending vehicle documents
          for (final entry in vehicle.documentUrls.entries) {
            final status = vehicle.getDocStatus(entry.key);
            if (status == null ||
                status == 'pending' ||
                status == 'under_review') {
              try {
                await vehiclesRepo.approveVehicleDocument(
                  vehicleId: vehicle.id,
                  docType: entry.key,
                  adminId: adminId,
                );
              } catch (_) {
                // Continue with other docs
              }
            }
          }
          approvedCount++;
        } catch (_) {
          // Continue with other vehicles
        }
      }

      if (approvedCount > 0) {
        _showSnackBar(
          '$approvedCount vehicle${approvedCount > 1 ? 's' : ''} approved for $driverName',
        );
        await _refreshProfile();
      } else {
        _showSnackBar(
          'Failed to approve vehicles. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _activeAction = _ActionType.none);
    }
  }

  void _showApprovalBlockerDialog(
    List<DriverDocument> unapprovedDocs,
    List<VehicleEntity> unapprovedVehicles,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange,
            ),
          ),
          title: const Text(
            'Cannot Approve Driver',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The following items must be approved first:',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (unapprovedDocs.isNotEmpty) ...[
                Text('Documents', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                ...unapprovedDocs.map(
                  (doc) => _blockerRow(
                    icon: Icons.description_outlined,
                    label: doc.label,
                    status: doc.verificationStatus,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (unapprovedVehicles.isNotEmpty) ...[
                Text('Vehicles', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                ...unapprovedVehicles.map(
                  (v) => _blockerRow(
                    icon: Icons.local_shipping_outlined,
                    label: '${v.displayName} (${v.licensePlate})',
                    status: v.verificationStatus,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      },
    );
  }

  Widget _blockerRow({
    required IconData icon,
    required String label,
    required String status,
  }) {
    final color = switch (status) {
      'rejected' => Colors.red,
      'documents_requested' => Colors.orange,
      _ => Colors.orange, // pending, under_review
    };
    final statusLabel = switch (status) {
      'rejected' => 'Rejected',
      'documents_requested' => 'Re-upload Requested',
      'under_review' => 'Under Review',
      _ => 'Pending',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDocumentViewer(
    List<DriverDocument> documents,
    int initialIndex,
  ) async {
    final doc = documents[initialIndex];
    final profileState = ref.read(driverProfileControllerProvider(widget.driverId));
    final profile = profileState.valueOrNull?.profile;

    if (profile != null) {
      // Navigate to DocumentReviewScreen and refresh profile on return
      final result = await context.push<bool>(
        AppRoutes.documentReviewPath(doc.id),
        extra: DocumentQueueItem(
          document: doc,
          driverFirstName: profile.firstName ?? '',
          driverLastName: profile.lastName ?? '',
          driverProfilePhotoUrl: profile.profilePhotoUrl,
          driverPhone: profile.phoneNumber,
          driverVerificationStatus: profile.verificationStatus,
          driverCreatedAt: profile.createdAt,
        ),
      );

      // Refresh profile data when an action was taken
      if ((result ?? false) && mounted) {
        await _refreshProfile();
      }
    } else {
      // Fall back to the plain document viewer when profile is unavailable
      context.pushDocumentViewer(
        documents: documents
            .map((d) => ViewerDocument(
                  url: d.docUrl,
                  label: d.docType.replaceAll('_', ' ').toUpperCase(),
                ))
            .toList(),
        initialIndex: initialIndex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileState = ref.watch(driverProfileControllerProvider(widget.driverId));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Driver Profile'),
        actions: [
          if (profileState.valueOrNull != null)
            IconButton(
              icon: const Icon(Icons.message_outlined),
              onPressed: _isProcessing
                  ? null
                  : () => _navigateToMessageDriver(profileState.valueOrNull!.profile),
              tooltip: 'Message Driver',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isProcessing ? null : _refreshProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: profileState.when(
        data: (data) => _buildContent(context, data),
        loading: () => const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile header shimmer
              ShimmerPlaceholder(width: double.infinity, height: 120),
              SizedBox(height: 16),
              // Status card shimmer
              ShimmerCard(height: 80),
              SizedBox(height: 12),
              // Info sections shimmer
              ShimmerCard(height: 140),
              SizedBox(height: 12),
              ShimmerCard(height: 140),
              SizedBox(height: 12),
              ShimmerCard(height: 100),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Error loading profile', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(error.toString(), style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _refreshProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: profileState.whenOrNull(
        data: (data) => _buildActionBar(context, data.profile),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DriverProfileData data) {
    return RefreshIndicator(
      onRefresh: _refreshProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100), // Space for action bar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            ProfileHeader(
              profile: data.profile,
              onPhotoTap: data.profile.profilePhotoUrl != null
                  ? () => _openDocumentViewer(
                        [DriverDocument(
                          id: 'profile',
                          driverId: data.profile.id,
                          docType: 'profile_photo',
                          docUrl: data.profile.profilePhotoUrl!,
                          verificationStatus: 'approved',
                          createdAt: DateTime.now(),
                          modifiedAt: DateTime.now(),
                        )],
                        0,
                      )
                  : null,
            ),
            
            const SizedBox(height: 16),
            
            // Personal Information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InfoSection(
                title: 'Personal Information',
                icon: Icons.person_outline,
                items: [
                  InfoItem(label: 'Phone', value: data.profile.phoneNumber),
                  if (data.profile.email != null)
                    InfoItem(label: 'Email', value: data.profile.email!),
                  if (data.profile.dateOfBirth != null)
                    InfoItem(
                      label: 'Date of Birth',
                      value: _formatDate(data.profile.dateOfBirth!),
                    ),
                  if (data.profile.idNumber != null)
                    InfoItem(
                      label: 'ID Number',
                      value: data.profile.maskedIdNumber ?? data.profile.idNumber!,
                    ),
                  InfoItem(
                    label: 'Registered',
                    value: _formatDateTime(data.profile.createdAt),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // Split documents: bank docs vs non-bank docs
            ..._buildSectionsList(context, data),

            // Approval History Section
            if (data.approvalHistory.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildApprovalHistorySection(context, data.approvalHistory),
              ),
              const SizedBox(height: 16),
            ],
            
            // Verification Notes
            if (data.profile.verificationNotes != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildNotesSection(context, data.profile.verificationNotes!),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSectionsList(BuildContext context, DriverProfileData data) {
    final bankDocs = data.documents
        .where((d) => d.docType.toLowerCase().contains('bank'))
        .toList();
    final nonBankDocs = data.documents
        .where((d) => !d.docType.toLowerCase().contains('bank'))
        .toList();

    return [
      // Documents Section (non-bank docs)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildDocumentsSection(context, data.profile, nonBankDocs),
      ),
      const SizedBox(height: 16),

      // Bank Section (bank doc + bank account info)
      if (bankDocs.isNotEmpty || data.profile.bankAccount != null) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildBankSection(context, data.profile, bankDocs),
        ),
        const SizedBox(height: 16),
      ],

      // Vehicles Section
      if (data.vehicles.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildVehiclesSection(context, data.vehicles),
        ),
        const SizedBox(height: 16),
      ],
    ];
  }

  /// Expected personal document types for drivers.
  static const _expectedDriverDocTypes = <String, String>{
    'id_document': 'ID Document',
    'license_front': 'Driver\'s License',
    'pdp': 'Professional Driving Permit (PDP)',
    'proof_of_address': 'Proof of Address',
  };

  /// Deduplicate documents by docType, keeping the most recently modified.
  Map<String, DriverDocument> _latestByType(List<DriverDocument> docs) {
    final map = <String, DriverDocument>{};
    for (final doc in docs) {
      final key = doc.docType.toLowerCase();
      if (!map.containsKey(key) ||
          doc.modifiedAt.isAfter(map[key]!.modifiedAt)) {
        map[key] = doc;
      }
    }
    return map;
  }

  Widget _buildDocumentsSection(
    BuildContext context,
    DriverProfile profile,
    List<DriverDocument> documents,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Deduplicate: keep only the latest document per docType
    final latestDocs = _latestByType(documents);

    // Build expected doc map: label → DriverDocument?
    final expectedDocs = <String, DriverDocument?>{
      for (final entry in _expectedDriverDocTypes.entries)
        entry.value: latestDocs[entry.key],
    };

    // Any uploaded docs whose type isn't in the expected list (extras)
    final extraDocs = latestDocs.entries
        .where((e) => !_expectedDriverDocTypes.containsKey(e.key))
        .map((e) => e.value)
        .toList();

    final uploadedCount =
        expectedDocs.values.where((d) => d != null).length + extraDocs.length;
    final totalExpected = _expectedDriverDocTypes.length + extraDocs.length;

    final missingLabels = expectedDocs.entries
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
                  '$uploadedCount/$totalExpected uploaded',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Missing documents warning
            if (missingLabels.isNotEmpty) ...[
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
                    const Icon(
                      Icons.warning_amber,
                      size: 18,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Missing Documents (${missingLabels.length})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            missingLabels.join(', '),
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

            // Expected documents (uploaded or missing tile)
            ...expectedDocs.entries.map((entry) {
              if (entry.value != null) {
                return _buildDocumentTile(context, entry.value!);
              }
              return _buildMissingDocumentTile(context, entry.key);
            }),

            // Extra documents not in the expected list
            ...extraDocs.map((doc) => _buildDocumentTile(context, doc)),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclesSection(BuildContext context, List<VehicleEntity> vehicles) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Vehicles', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  '${vehicles.length} registered',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...vehicles.map((vehicle) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: VehicleCard(
                vehicle: vehicle,
                onTap: () => context.push('/users/vehicle/${vehicle.id}'),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBankSection(
    BuildContext context,
    DriverProfile profile,
    List<DriverDocument> bankDocs,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bankAccount = profile.bankAccount;

    // Status pill for the header (from bank account if available)
    Color statusColor = Colors.orange;
    var statusIcon = Icons.schedule;
    var statusLabel = 'Pending';

    if (bankAccount != null) {
      switch (bankAccount.verificationStatusLabel) {
        case 'Verified':
          statusColor = Colors.green;
          statusIcon = Icons.verified;
          statusLabel = bankAccount.verificationStatusLabel;
          break;
        case 'Rejected':
          statusColor = colorScheme.error;
          statusIcon = Icons.cancel;
          statusLabel = bankAccount.verificationStatusLabel;
          break;
        default:
          statusColor = Colors.orange;
          statusIcon = Icons.schedule;
          statusLabel = bankAccount.verificationStatusLabel;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Bank Account', style: theme.textTheme.titleMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Bank document tile(s) — deduplicated, latest per docType
            if (bankDocs.isNotEmpty) ...[
              ..._latestByType(bankDocs)
                  .values
                  .map((doc) => _buildDocumentTile(context, doc)),
              if (bankAccount != null) const Divider(height: 24),
            ],

            // Bank account info
            if (bankAccount != null) ...[
              _buildBankInfoRow(theme, 'Bank Name', bankAccount.bankName),
              const SizedBox(height: 8),
              _buildBankInfoRow(theme, 'Account Name', bankAccount.accountName),
              const SizedBox(height: 8),
              _buildBankInfoRow(
                theme,
                'Account Number',
                bankAccount.maskedAccountNumber,
              ),
              const SizedBox(height: 8),
              _buildBankInfoRow(theme, 'Currency', bankAccount.currency),
              if (bankAccount.isRejected &&
                  bankAccount.rejectionReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
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
                          bankAccount.rejectionReason!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBankInfoRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentTile(BuildContext context, DriverDocument doc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine badge label and color based on verification status
    String badgeLabel;
    Color badgeColor;
    switch (doc.verificationStatus) {
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
      default:
        badgeLabel = 'Pending Review';
        badgeColor = Colors.orange;
        break;
    }

    // Cache-bust URL so thumbnails refresh after re-upload
    final separator = doc.docUrl.contains('?') ? '&' : '?';
    final cacheBustUrl =
        '${doc.docUrl}${separator}v=${doc.verificationStatus}';

    return InkWell(
      onTap: () => _openDocumentViewer([doc], 0),
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
                  placeholder: (context, _) => ColoredBox(
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, _, __) => ColoredBox(
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
                    doc.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (doc.isReviewable)
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
              border: Border.all(
                color: colorScheme.error.withValues(alpha: 0.3),
              ),
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

  Widget _buildApprovalHistorySection(
    BuildContext context,
    List<ApprovalHistoryItem> history,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Approval History', style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(height: 24),
            ApprovalTimeline(history: history),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, String notes) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Verification Notes', style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                notes,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, DriverProfile profile) {
    final theme = Theme.of(context);
    final status = profile.verificationStatus;
    final profileData = ref.read(driverProfileControllerProvider(widget.driverId)).valueOrNull;
    final hasPendingDriverDocs = profileData != null &&
        profileData.documents.any((d) => d.isReviewable);
    final hasActionableVehicles = profileData != null &&
        profileData.vehicles.any((v) => v.isActionable);

    // Only show action bar for actionable statuses
    if (status == 'approved' || status == 'suspended') {
      return const SizedBox.shrink();
    }

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bulk approve buttons row
            if (hasPendingDriverDocs || hasActionableVehicles) ...[
              Row(
                children: [
                  if (hasPendingDriverDocs)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _handleApproveDocs(profile),
                        icon: _activeAction == _ActionType.approveDocs
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue,
                                ),
                              )
                            : const Icon(Icons.done_all, size: 18),
                        label: const Text('Approve Documents'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  if (hasPendingDriverDocs && hasActionableVehicles)
                    const SizedBox(width: 8),
                  if (hasActionableVehicles)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _handleApproveVehicles(profile),
                        icon: _activeAction == _ActionType.approveVehicles
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.purple,
                                ),
                              )
                            : const Icon(Icons.local_shipping, size: 18),
                        label: const Text('Approve Vehicles'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple,
                          side: const BorderSide(color: Colors.purple),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                // Request Documents button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _handleRequestDocuments(profile),
                    icon: const Icon(Icons.file_upload_outlined, size: 18),
                    label: const Text('Documents'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Approve button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => _handleApprove(profile),
                    icon: _activeAction == _ActionType.approve
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
