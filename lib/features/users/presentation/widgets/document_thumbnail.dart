import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/entities/driver_document.dart';

/// Document thumbnail widget with status indicator
class DocumentThumbnail extends StatelessWidget {
  final DriverDocument document;
  final VoidCallback? onTap;
  final double size;

  const DocumentThumbnail({
    super.key,
    required this.document,
    this.onTap,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size + 40, // Extra space for label
        child: Column(
          children: [
            // Image container
            Stack(
              children: [
                // Image
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor().withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: document.docUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),

                // Status indicator
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Expiry warning
                if (document.isExpired || document.isExpiringSoon)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: document.isExpired
                            ? Colors.red
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        document.isExpired ? 'Expired' : 'Expiring',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Zoom icon overlay on hover/tap
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.black.withOpacity(0.0),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.zoom_in,
                        color: Colors.white.withOpacity(0.0),
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Label
            Expanded(
              child: Text(
                document.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (document.isExpired) return Colors.red;
    switch (document.verificationStatus.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon() {
    if (document.isExpired) return Icons.event_busy;
    switch (document.verificationStatus.toLowerCase()) {
      case 'approved':
        return Icons.check;
      case 'rejected':
        return Icons.close;
      case 'pending':
      default:
        return Icons.schedule;
    }
  }
}

/// Grid of document thumbnails
class DocumentsGrid extends StatelessWidget {
  final List<DriverDocument> documents;
  final Function(DriverDocument document, int index)? onDocumentTap;
  final bool isLoading;

  const DocumentsGrid({
    super.key,
    required this.documents,
    this.onDocumentTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (documents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.folder_open,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No documents uploaded',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        return DocumentThumbnail(
          document: documents[index],
          onTap: () => onDocumentTap?.call(documents[index], index),
        );
      },
    );
  }
}
