// lib/features/users/presentation/screens/driver_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/components/document_viewer_screen.dart';
import '../../../../core/components/document_viewer_state.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/core_providers.dart';
import '../../domain/entities/driver_bank_account.dart';
import '../../domain/entities/driver_profile.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/driver_document.dart';
import '../../domain/entities/approval_history_item.dart';
import '../../domain/entities/document_queue_item.dart';
import '../providers/driver_profile_providers.dart';
import '../providers/document_review_providers.dart';
import '../widgets/profile_header.dart';
import '../widgets/info_section.dart';
import '../widgets/document_thumbnail.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/approval_timeline.dart';
import '../widgets/approve_confirm_dialog.dart';
import '../widgets/reject_dialog.dart';
import '../widgets/request_documents_dialog.dart';
import '../widgets/status_badge.dart';

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
  bool _isProcessing = false;

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
    final driverName = '${profile.firstName} ${profile.lastName}';
    
    final confirmed = await ApproveConfirmDialog.show(
      context: context,
      driverName: driverName,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);

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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleReject(DriverProfile profile) async {
    final driverName = '${profile.firstName} ${profile.lastName}';
    
    final result = await RejectDialog.show(
      context: context,
      driverName: driverName,
    );

    if (result == null || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final success = await ref
          .read(driverProfileControllerProvider(widget.driverId).notifier)
          .rejectDriver(reason: result.reason, notes: result.notes);

      if (success) {
        _showSnackBar('❌ $driverName has been rejected.');
        await _refreshProfile();
      } else {
        _showSnackBar('Failed to reject driver. Please try again.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleRequestDocuments(DriverProfile profile) async {
    final driverName = '${profile.firstName} ${profile.lastName}';
    
    final result = await RequestDocumentsDialog.show(
      context: context,
      driverName: driverName,
    );

    if (result == null || !mounted) return;

    setState(() => _isProcessing = true);

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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleApproveAllDocs(DriverProfile profile) async {
    final driverName = '${profile.firstName} ${profile.lastName}';

    final confirmed = await ApproveConfirmDialog.show(
      context: context,
      driverName: '$driverName (all documents)',
    );

    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final success = await ref
          .read(documentReviewNotifierProvider.notifier)
          .approveAllDocuments(driverId: widget.driverId);

      if (success) {
        _showSnackBar('All documents for $driverName approved');
        await _refreshProfile();
      } else {
        _showSnackBar(
          'Failed to approve all documents. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _openDocumentViewer(List<DriverDocument> documents, int initialIndex) {
    final doc = documents[initialIndex];
    final profileState = ref.read(driverProfileControllerProvider(widget.driverId));
    final profile = profileState.valueOrNull?.profile;

    if (doc.isReviewable && profile != null) {
      // Navigate to DocumentReviewScreen for reviewable documents
      context.goToDocumentReview(
        documentId: doc.id,
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
    } else {
      // Fall back to the plain document viewer for non-reviewable documents
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isProcessing ? null : _refreshProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: profileState.when(
        data: (data) => _buildContent(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
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
    final theme = Theme.of(context);
    
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
            
            // Documents Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDocumentsSection(context, data.profile, data.documents),
            ),
            
            const SizedBox(height: 16),
            
            // Vehicles Section
            if (data.vehicles.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildVehiclesSection(context, data.vehicles),
              ),
              const SizedBox(height: 16),
            ],

            // Bank Account Section
            if (data.profile.bankAccount != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildBankAccountSection(context, data.profile.bankAccount!),
              ),
              const SizedBox(height: 16),
            ],

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

  Widget _buildDocumentsSection(
    BuildContext context,
    DriverProfile profile,
    List<DriverDocument> documents,
  ) {
    final theme = Theme.of(context);
    
    // Combine profile-level documents with separate documents list
    final allDocuments = <DriverDocument>[
      ...profile.documents,
      ...documents,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Documents', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  '${allDocuments.length} files',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (allDocuments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_off_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No documents uploaded',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: allDocuments.length,
                itemBuilder: (context, index) {
                  final doc = allDocuments[index];
                  return DocumentThumbnail(
                    document: doc,
                    onTap: () => _openDocumentViewer(allDocuments, index),
                  );
                },
              ),
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

  Widget _buildBankAccountSection(BuildContext context, DriverBankAccount bankAccount) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color statusColor;
    IconData statusIcon;
    switch (bankAccount.verificationStatusLabel) {
      case 'Verified':
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        break;
      case 'Rejected':
        statusColor = colorScheme.error;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
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
                        bankAccount.verificationStatusLabel,
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
            _buildBankInfoRow(theme, 'Bank Name', bankAccount.bankName),
            const SizedBox(height: 8),
            _buildBankInfoRow(theme, 'Account Name', bankAccount.accountName),
            const SizedBox(height: 8),
            _buildBankInfoRow(theme, 'Account Number', bankAccount.maskedAccountNumber),
            const SizedBox(height: 8),
            _buildBankInfoRow(theme, 'Currency', bankAccount.currency),
            if (bankAccount.isRejected && bankAccount.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bankAccount.rejectionReason!,
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
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
    final hasPendingDocs = profileData != null &&
        profileData.documents.any((d) => d.isReviewable);

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
            // Approve All Docs button (shown when driver has pending documents)
            if (hasPendingDocs) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _handleApproveAllDocs(profile),
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Approve All Documents'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
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
                    label: const Text('Request Docs'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Reject button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => _handleReject(profile),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
            
                // Approve button
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isProcessing ? null : () => _handleApprove(profile),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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
