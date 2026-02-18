// lib/features/disputes/presentation/widgets/evidence_gallery.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/evidence_entity.dart';
import '../../domain/entities/dispute_entity.dart';

class EvidenceGallery extends StatelessWidget {
  final List<EvidenceEntity> evidence;
  final VoidCallback? onAddEvidence;

  const EvidenceGallery({
    super.key,
    required this.evidence,
    this.onAddEvidence,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: evidence.length,
      itemBuilder: (context, index) {
        final item = evidence[index];
        return EvidenceCard(
          evidence: item,
          onTap: () => _showEvidenceViewer(context, item, index),
        );
      },
    );
  }

  void _showEvidenceViewer(BuildContext context, EvidenceEntity item, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EvidenceViewerScreen(
          evidence: evidence,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// Card displaying a single evidence item
class EvidenceCard extends StatelessWidget {
  final EvidenceEntity evidence;
  final VoidCallback? onTap;

  const EvidenceCard({
    super.key,
    required this.evidence,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              _buildThumbnail(theme),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(evidence.evidenceType).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getTypeIcon(evidence.evidenceType),
                                size: 14,
                                color: _getTypeColor(evidence.evidenceType),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                evidence.evidenceType.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _getTypeColor(evidence.evidenceType),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat.MMMd().add_jm().format(evidence.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Description
                    if (evidence.description != null && evidence.description!.isNotEmpty)
                      Text(
                        evidence.description!,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    // Submitted by
                    if (evidence.submittedBy != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            backgroundImage: evidence.submittedBy!.profilePhotoUrl != null
                                ? NetworkImage(evidence.submittedBy!.profilePhotoUrl!)
                                : null,
                            child: evidence.submittedBy!.profilePhotoUrl == null
                                ? Text(
                                    evidence.submittedBy!.initials[0],
                                    style: const TextStyle(fontSize: 8),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'By ${evidence.submittedBy!.displayName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          if (evidence.submittedBy!.role != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${evidence.submittedBy!.role})',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    // GPS data if present
                    if (evidence.gpsCoordinates != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${evidence.gpsCoordinates!.lat.toStringAsFixed(4)}, ${evidence.gpsCoordinates!.lng.toStringAsFixed(4)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
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

  Widget _buildThumbnail(ThemeData theme) {
    if (evidence.hasFile && evidence.isImageFile) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          evidence.fileUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
        ),
      );
    }

    return _buildPlaceholder(theme);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _getTypeColor(evidence.evidenceType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getTypeIcon(evidence.evidenceType),
        color: _getTypeColor(evidence.evidenceType),
        size: 28,
      ),
    );
  }

  IconData _getTypeIcon(EvidenceType type) {
    switch (type) {
      case EvidenceType.photo:
        return Icons.photo;
      case EvidenceType.document:
        return Icons.description;
      case EvidenceType.deliveryProof:
        return Icons.check_circle;
      case EvidenceType.damagePhoto:
        return Icons.broken_image;
      case EvidenceType.receipt:
        return Icons.receipt;
      case EvidenceType.gpsData:
        return Icons.location_on;
      case EvidenceType.communication:
        return Icons.message;
      case EvidenceType.other:
        return Icons.attachment;
    }
  }

  Color _getTypeColor(EvidenceType type) {
    switch (type) {
      case EvidenceType.photo:
        return Colors.blue;
      case EvidenceType.document:
        return Colors.orange;
      case EvidenceType.deliveryProof:
        return Colors.green;
      case EvidenceType.damagePhoto:
        return Colors.red;
      case EvidenceType.receipt:
        return Colors.purple;
      case EvidenceType.gpsData:
        return Colors.teal;
      case EvidenceType.communication:
        return Colors.indigo;
      case EvidenceType.other:
        return Colors.grey;
    }
  }
}

/// Full-screen evidence viewer with swipe navigation
class EvidenceViewerScreen extends StatefulWidget {
  final List<EvidenceEntity> evidence;
  final int initialIndex;

  const EvidenceViewerScreen({
    super.key,
    required this.evidence,
    this.initialIndex = 0,
  });

  @override
  State<EvidenceViewerScreen> createState() => _EvidenceViewerScreenState();
}

class _EvidenceViewerScreenState extends State<EvidenceViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentEvidence = widget.evidence[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} of ${widget.evidence.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showEvidenceDetails(context, currentEvidence),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image viewer
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.evidence.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final item = widget.evidence[index];
                return _buildEvidenceView(item);
              },
            ),
          ),

          // Bottom info bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          currentEvidence.evidenceType.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat.yMMMd().add_jm().format(currentEvidence.createdAt),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (currentEvidence.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      currentEvidence.description!,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceView(EvidenceEntity item) {
    if (item.hasFile && item.isImageFile) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.network(
            item.fileUrl!,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (_, __, ___) => _buildPlaceholder(item),
          ),
        ),
      );
    }

    return Center(child: _buildPlaceholder(item));
  }

  Widget _buildPlaceholder(EvidenceEntity item) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          item.isDocumentFile ? Icons.description : Icons.attachment,
          size: 64,
          color: Colors.white.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        Text(
          item.evidenceType.displayName,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
        if (item.fileUrl != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              // TODO: Open document in external viewer
            },
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            label: const Text(
              'Open File',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  void _showEvidenceDetails(BuildContext context, EvidenceEntity item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evidence Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Type', value: item.evidenceType.displayName),
            _DetailRow(
              label: 'Submitted',
              value: DateFormat.yMMMd().add_jm().format(item.createdAt),
            ),
            if (item.submittedBy != null)
              _DetailRow(
                label: 'By',
                value: '${item.submittedBy!.displayName} (${item.submittedBy!.role ?? "User"})',
              ),
            if (item.description != null)
              _DetailRow(label: 'Description', value: item.description!),
            if (item.gpsCoordinates != null)
              _DetailRow(
                label: 'GPS',
                value:
                    '${item.gpsCoordinates!.lat.toStringAsFixed(6)}, ${item.gpsCoordinates!.lng.toStringAsFixed(6)}',
              ),
            if (item.capturedAt != null)
              _DetailRow(
                label: 'Captured',
                value: DateFormat.yMMMd().add_jm().format(item.capturedAt!),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

/// Grid view of evidence thumbnails
class EvidenceGridView extends StatelessWidget {
  final List<EvidenceEntity> evidence;
  final int maxVisible;
  final VoidCallback? onViewAll;

  const EvidenceGridView({
    super.key,
    required this.evidence,
    this.maxVisible = 4,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleEvidence = evidence.take(maxVisible).toList();
    final remaining = evidence.length - maxVisible;

    return SizedBox(
      height: 80,
      child: Row(
        children: [
          ...visibleEvidence.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == visibleEvidence.length - 1;

            return Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 8),
              child: _buildThumbnail(context, item, index),
            );
          }),
          if (remaining > 0) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '+$remaining',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'more',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, EvidenceEntity item, int index) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EvidenceViewerScreen(
              evidence: evidence,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        clipBehavior: Clip.antiAlias,
        child: item.hasFile && item.isImageFile
            ? Image.network(
                item.fileUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.broken_image,
                  color: theme.colorScheme.outline,
                ),
              )
            : Icon(
                _getTypeIcon(item.evidenceType),
                color: theme.colorScheme.outline,
              ),
      ),
    );
  }

  IconData _getTypeIcon(EvidenceType type) {
    switch (type) {
      case EvidenceType.photo:
        return Icons.photo;
      case EvidenceType.document:
        return Icons.description;
      case EvidenceType.deliveryProof:
        return Icons.check_circle;
      case EvidenceType.damagePhoto:
        return Icons.broken_image;
      case EvidenceType.receipt:
        return Icons.receipt;
      case EvidenceType.gpsData:
        return Icons.location_on;
      case EvidenceType.communication:
        return Icons.message;
      case EvidenceType.other:
        return Icons.attachment;
    }
  }
}
