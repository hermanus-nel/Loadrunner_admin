import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'document_viewer_state.dart';

/// StateNotifier for managing document viewer state
class DocumentViewerController extends StateNotifier<DocumentViewerState> {
  DocumentViewerController({
    required List<ViewerDocument> documents,
    int initialIndex = 0,
  }) : super(DocumentViewerState(
          documents: documents,
          currentIndex: initialIndex.clamp(0, documents.length - 1),
        ));

  /// Navigate to a specific page
  void goToPage(int index) {
    if (index >= 0 && index < state.documents.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  /// Navigate to next document
  void nextPage() {
    if (state.canGoNext) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  /// Navigate to previous document
  void previousPage() {
    if (state.canGoPrevious) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  /// Set loading state for current document
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Set error state
  void setError(String? error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Set zoom state
  void setZoomed(bool zoomed) {
    state = state.copyWith(isZoomed: zoomed);
  }
}

/// Provider family for document viewer controller
/// Usage: ref.watch(documentViewerControllerProvider(params))
final documentViewerControllerProvider = StateNotifierProvider.family
    .autoDispose<DocumentViewerController, DocumentViewerState,
        DocumentViewerParams>(
  (ref, params) => DocumentViewerController(
    documents: params.documents,
    initialIndex: params.initialIndex,
  ),
);

/// Parameters for document viewer provider
class DocumentViewerParams {
  final List<ViewerDocument> documents;
  final int initialIndex;

  const DocumentViewerParams({
    required this.documents,
    this.initialIndex = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentViewerParams &&
          runtimeType == other.runtimeType &&
          documents == other.documents &&
          initialIndex == other.initialIndex;

  @override
  int get hashCode => documents.hashCode ^ initialIndex.hashCode;
}
