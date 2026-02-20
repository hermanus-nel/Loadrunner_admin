import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';

import '../../domain/entities/document_queue_item.dart';
import '../../domain/entities/driver_document.dart';
import '../providers/document_queue_providers.dart';
import '../providers/document_review_providers.dart';
import '../widgets/document_reject_dialog.dart';
import '../widgets/document_reupload_dialog.dart';
import '../widgets/status_badge.dart';

/// Full-screen document review screen with zoom, driver context panel,
/// and action buttons (Approve, Reject, Request Re-upload, Flag).
class DocumentReviewScreen extends ConsumerStatefulWidget {
  final String documentId;

  /// Optional pre-loaded data passed via route extra.
  /// If null, the screen can still be used but won't show driver context.
  final DocumentQueueItem? queueItem;

  /// Alternatively, pass a DriverDocument + driver context separately
  /// (used when navigating from driver profile screen).
  final DriverDocument? document;
  final String? driverName;
  final String? driverPhone;
  final String? driverVerificationStatus;
  final DateTime? driverCreatedAt;

  const DocumentReviewScreen({
    super.key,
    required this.documentId,
    this.queueItem,
    this.document,
    this.driverName,
    this.driverPhone,
    this.driverVerificationStatus,
    this.driverCreatedAt,
  });

  @override
  ConsumerState<DocumentReviewScreen> createState() =>
      _DocumentReviewScreenState();
}

class _DocumentReviewScreenState extends ConsumerState<DocumentReviewScreen> {
  bool _showOverlay = true;
  bool _showDriverPanel = false;

  DriverDocument? get _document =>
      widget.queueItem?.document ?? widget.document;

  String get _driverName =>
      widget.queueItem?.driverFullName ?? widget.driverName ?? 'Unknown Driver';

  String? get _driverPhone =>
      widget.queueItem?.driverPhone ?? widget.driverPhone;

  String get _driverVerificationStatus =>
      widget.queueItem?.driverVerificationStatus ??
      widget.driverVerificationStatus ??
      'pending';

  DateTime? get _driverCreatedAt =>
      widget.queueItem?.driverCreatedAt ?? widget.driverCreatedAt;

  String get _driverId =>
      widget.queueItem?.document.driverId ?? widget.document?.driverId ?? '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
      if (!_showOverlay) _showDriverPanel = false;
    });
  }

  void _toggleDriverPanel() {
    setState(() => _showDriverPanel = !_showDriverPanel);
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

  // ==================================================================
  // ACTIONS
  // ==================================================================

  Future<void> _handleApprove() async {
    final doc = _document;
    if (doc == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Colors.green,
          ),
        ),
        title: const Text('Approve Document', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Approve this ${doc.label}?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The driver will be notified that this document has been approved.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green[700],
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

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(documentReviewNotifierProvider.notifier)
        .approveDocument(
          documentId: doc.id,
          driverId: _driverId,
          docType: doc.docType,
        );

    if (success && mounted) {
      _showSnackBar('Document approved successfully');
      ref
          .read(documentQueueNotifierProvider.notifier)
          .removeDocument(doc.id);
      Navigator.of(context).pop(true);
    } else if (mounted) {
      final state = ref.read(documentReviewNotifierProvider);
      _showSnackBar(
        state.actionError ?? 'Failed to approve document',
        isError: true,
      );
    }
  }

  Future<void> _handleReject() async {
    final doc = _document;
    if (doc == null) return;

    final result = await DocumentRejectDialog.show(
      context: context,
      docTypeLabel: doc.label,
    );

    if (result == null || !mounted) return;

    final success = await ref
        .read(documentReviewNotifierProvider.notifier)
        .rejectDocument(
          documentId: doc.id,
          driverId: _driverId,
          docType: doc.docType,
          reason: result.reason,
          customReason: result.customReason,
          adminNotes: result.adminNotes,
        );

    if (success && mounted) {
      _showSnackBar('Document rejected');
      ref
          .read(documentQueueNotifierProvider.notifier)
          .removeDocument(doc.id);
      Navigator.of(context).pop(true);
    } else if (mounted) {
      final state = ref.read(documentReviewNotifierProvider);
      _showSnackBar(
        state.actionError ?? 'Failed to reject document',
        isError: true,
      );
    }
  }

  Future<void> _handleReupload() async {
    final doc = _document;
    if (doc == null) return;

    final result = await DocumentReuploadDialog.show(
      context: context,
      docTypeLabel: doc.label,
    );

    if (result == null || !mounted) return;

    final success = await ref
        .read(documentReviewNotifierProvider.notifier)
        .requestReupload(
          documentId: doc.id,
          driverId: _driverId,
          docType: doc.docType,
          reason: result.reason,
          customReason: result.customReason,
          adminNotes: result.adminNotes,
        );

    if (success && mounted) {
      _showSnackBar('Re-upload requested');
      ref
          .read(documentQueueNotifierProvider.notifier)
          .removeDocument(doc.id);
      Navigator.of(context).pop(true);
    } else if (mounted) {
      final state = ref.read(documentReviewNotifierProvider);
      _showSnackBar(
        state.actionError ?? 'Failed to request re-upload',
        isError: true,
      );
    }
  }

  // ==================================================================
  // BUILD
  // ==================================================================

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(documentReviewNotifierProvider);
    final doc = _document;
    final theme = Theme.of(context);

    if (doc == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black54,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Document Review',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(
          child: Text(
            'Document data not available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Photo viewer
          GestureDetector(
            onTap: _toggleOverlay,
            child: PhotoView(
              imageProvider: CachedNetworkImageProvider(doc.docUrl),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 4,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              loadingBuilder: (context, event) {
                return Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                      value: event == null
                          ? null
                          : event.cumulativeBytesLoaded /
                              (event.expectedTotalBytes ?? 1),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white54,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          CachedNetworkImage.evictFromCache(doc.docUrl);
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // App bar overlay
          if (_showOverlay)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                doc.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _driverName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _showDriverPanel
                                ? Icons.info
                                : Icons.info_outline,
                            color: Colors.white,
                          ),
                          onPressed: _toggleDriverPanel,
                          tooltip: 'Driver info',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Driver context panel
          if (_showOverlay && _showDriverPanel)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              left: 16,
              right: 16,
              child: _buildDriverPanel(context, theme),
            ),

          // Action bar overlay
          if (_showOverlay)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildActionBar(context, doc, reviewState, theme),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverPanel(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                _driverName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_driverPhone != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  _driverPhone!,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.verified_user,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              StatusBadge(
                status: _driverVerificationStatus,
                size: StatusBadgeSize.small,
              ),
            ],
          ),
          if (_driverCreatedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Registered: ${_formatDate(_driverCreatedAt!)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    DriverDocument doc,
    DocumentReviewState reviewState,
    ThemeData theme,
  ) {
    final isLoading = reviewState.isActionLoading;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hint
              if (!isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Pinch to zoom \u2022 Tap image to toggle controls',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),

              // Loading indicator
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Action buttons
              Row(
                children: [
                  // Reject button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _handleReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[300],
                        side: BorderSide(
                          color: Colors.red[300]!.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Reupload button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _handleReupload,
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Re-upload'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[300],
                        side: BorderSide(
                          color: Colors.orange[300]!.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Approve button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _handleApprove,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green[300],
                        side: BorderSide(
                          color: Colors.green[300]!.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
