import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';

import '../providers/vehicle_providers.dart';
import '../widgets/document_reupload_dialog.dart';
import '../widgets/status_badge.dart';

/// Full-screen vehicle document review screen with zoom and
/// Reject / Re-upload / Approve actions for a single document.
class VehicleDocReviewScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final String docType;
  final String docUrl;
  final String? currentStatus;

  const VehicleDocReviewScreen({
    super.key,
    required this.vehicleId,
    required this.docType,
    required this.docUrl,
    this.currentStatus,
  });

  @override
  ConsumerState<VehicleDocReviewScreen> createState() =>
      _VehicleDocReviewScreenState();
}

class _VehicleDocReviewScreenState
    extends ConsumerState<VehicleDocReviewScreen> {
  bool _showOverlay = true;

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
    setState(() => _showOverlay = !_showOverlay);
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
              'Approve this ${widget.docType} document?',
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
        .read(vehicleDetailControllerProvider(widget.vehicleId).notifier)
        .approveVehicleDocument(widget.docType);

    if (success && mounted) {
      _showSnackBar('${widget.docType} document approved');
      Navigator.of(context).pop(true);
    } else if (mounted) {
      _showSnackBar('Failed to approve document', isError: true);
    }
  }

  Future<void> _handleReupload() async {
    final result = await DocumentReuploadDialog.show(
      context: context,
      docTypeLabel: '${widget.docType} Document',
    );

    if (result == null || !mounted) return;

    final reason = result.customReason ?? result.reason.displayText;

    final success = await ref
        .read(vehicleDetailControllerProvider(widget.vehicleId).notifier)
        .requestVehicleDocumentReupload(
          widget.docType,
          reason,
          notes: result.adminNotes,
        );

    if (success && mounted) {
      _showSnackBar('Re-upload requested for ${widget.docType}');
      Navigator.of(context).pop(true);
    } else if (mounted) {
      _showSnackBar('Failed to request re-upload', isError: true);
    }
  }

  // ==================================================================
  // BUILD
  // ==================================================================

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      vehicleDetailControllerProvider(widget.vehicleId),
    );
    final isProcessing = state.isProcessing;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Photo viewer
          GestureDetector(
            onTap: _toggleOverlay,
            child: PhotoView(
              imageProvider: CachedNetworkImageProvider(
                widget.docUrl,
                cacheKey: widget.docUrl,
              ),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 4,
              backgroundDecoration:
                  const BoxDecoration(color: Colors.black),
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
                          CachedNetworkImage.evictFromCache(
                            widget.docUrl,
                            cacheKey: widget.docUrl,
                          );
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

          // Top bar overlay
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
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
                                '${widget.docType} Document',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (widget.currentStatus != null)
                                StatusBadge(
                                  status: widget.currentStatus!,
                                  size: StatusBadgeSize.small,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom action bar overlay
          if (_showOverlay)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildActionBar(isProcessing),
            ),
        ],
      ),
    );
  }

  Widget _buildActionBar(bool isProcessing) {
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
              if (!isProcessing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Pinch to zoom \u2022 Tap image to toggle controls',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),

              // Loading indicator
              if (isProcessing)
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
                  // Re-upload button (always shown)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing ? null : _handleReupload,
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Re-upload'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[300],
                        side: BorderSide(
                          color: Colors.orange[300]!.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  // Approve button (hidden when already approved)
                  if (widget.currentStatus != 'approved') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isProcessing ? null : _handleApprove,
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
