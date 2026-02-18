import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'document_viewer_state.dart';
import 'document_viewer_controller.dart';

/// Full-screen document viewer with zoom and swipe navigation
class DocumentViewerScreen extends ConsumerStatefulWidget {
  /// List of documents to display
  final List<ViewerDocument> documents;

  /// Initial index to display
  final int initialIndex;

  /// Optional title for the app bar
  final String? title;

  /// Whether to show download button
  final bool showDownloadButton;

  /// Callback when download is pressed
  final void Function(ViewerDocument document)? onDownload;

  const DocumentViewerScreen({
    super.key,
    required this.documents,
    this.initialIndex = 0,
    this.title,
    this.showDownloadButton = false,
    this.onDownload,
  });

  @override
  ConsumerState<DocumentViewerScreen> createState() =>
      _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends ConsumerState<DocumentViewerScreen> {
  late PageController _pageController;
  late DocumentViewerParams _params;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _params = DocumentViewerParams(
      documents: widget.documents,
      initialIndex: widget.initialIndex,
    );

    // Set immersive mode
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _onPageChanged(int index) {
    ref.read(documentViewerControllerProvider(_params).notifier).goToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentViewerControllerProvider(_params));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showControls
          ? AppBar(
              backgroundColor: Colors.black54,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                widget.title ??
                    state.currentDocument?.label ??
                    'Document Viewer',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                if (widget.showDownloadButton && state.currentDocument != null)
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: () {
                      widget.onDownload?.call(state.currentDocument!);
                    },
                  ),
              ],
            )
          : null,
      body: Stack(
        children: [
          // Photo gallery
          GestureDetector(
            onTap: _toggleControls,
            child: PhotoViewGallery.builder(
              scrollPhysics: state.isZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              pageController: _pageController,
              itemCount: state.documents.length,
              onPageChanged: _onPageChanged,
              builder: (context, index) {
                final document = state.documents[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(document.url),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  heroAttributes: PhotoViewHeroAttributes(tag: document.url),
                  errorBuilder: (context, error, stackTrace) {
                    return _buildErrorWidget(context, document);
                  },
                  onScaleEnd: (context, details, controllerValue) {
                    // Track zoom state
                    final isZoomed = controllerValue.scale != null &&
                        controllerValue.scale! > 1.0;
                    ref
                        .read(documentViewerControllerProvider(_params).notifier)
                        .setZoomed(isZoomed);
                  },
                );
              },
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
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
          ),

          // Page indicator
          if (_showControls && state.hasMultipleDocuments)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    state.pageIndicator,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

          // Document label
          if (_showControls && state.currentDocument?.label != null)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.currentDocument!.label!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

          // Navigation arrows for desktop/tablet
          if (_showControls && state.hasMultipleDocuments)
            _buildNavigationArrows(context, state),

          // Dot indicators
          if (_showControls && state.hasMultipleDocuments)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: _buildDotIndicators(state),
            ),

          // Hint for zoom
          if (_showControls && !state.isZoomed)
            const Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Double-tap or pinch to zoom',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, ViewerDocument document) {
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
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            document.label ?? 'Unknown document',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Force rebuild by clearing cache
              CachedNetworkImage.evictFromCache(document.url);
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
  }

  Widget _buildNavigationArrows(BuildContext context, DocumentViewerState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous arrow
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AnimatedOpacity(
            opacity: state.canGoPrevious ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 48,
              ),
              onPressed: state.canGoPrevious
                  ? () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  : null,
            ),
          ),
        ),

        // Next arrow
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AnimatedOpacity(
            opacity: state.canGoNext ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              icon: const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 48,
              ),
              onPressed: state.canGoNext
                  ? () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDotIndicators(DocumentViewerState state) {
    // Limit to 10 dots max for better UX
    final showDots = state.documents.length <= 10;
    if (!showDots) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        state.documents.length,
        (index) => GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == state.currentIndex
                  ? Colors.white
                  : Colors.white.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }
}

/// Extension to navigate to document viewer via GoRouter
extension DocumentViewerNavigation on BuildContext {
  /// Navigate to document viewer
  /// 
  /// Usage:
  /// ```dart
  /// context.pushDocumentViewer(
  ///   documents: [
  ///     ViewerDocument(url: 'https://...', label: 'License Front'),
  ///     ViewerDocument(url: 'https://...', label: 'License Back'),
  ///   ],
  ///   initialIndex: 0,
  /// );
  /// ```
  void pushDocumentViewer({
    required List<ViewerDocument> documents,
    int initialIndex = 0,
    String? title,
  }) {
    Navigator.of(this).push(
      MaterialPageRoute(
        builder: (context) => DocumentViewerScreen(
          documents: documents,
          initialIndex: initialIndex,
          title: title,
        ),
      ),
    );
  }
}
