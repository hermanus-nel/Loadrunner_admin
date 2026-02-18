import 'package:equatable/equatable.dart';

/// Represents a document to be displayed in the viewer
class ViewerDocument extends Equatable {
  final String url;
  final String? label;
  final String? type; // 'image', 'pdf', etc.

  const ViewerDocument({
    required this.url,
    this.label,
    this.type,
  });

  @override
  List<Object?> get props => [url, label, type];
}

/// State for the document viewer
class DocumentViewerState extends Equatable {
  final List<ViewerDocument> documents;
  final int currentIndex;
  final bool isLoading;
  final String? error;
  final bool isZoomed;

  const DocumentViewerState({
    this.documents = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.error,
    this.isZoomed = false,
  });

  DocumentViewerState copyWith({
    List<ViewerDocument>? documents,
    int? currentIndex,
    bool? isLoading,
    String? error,
    bool? isZoomed,
  }) {
    return DocumentViewerState(
      documents: documents ?? this.documents,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isZoomed: isZoomed ?? this.isZoomed,
    );
  }

  ViewerDocument? get currentDocument =>
      documents.isNotEmpty && currentIndex < documents.length
          ? documents[currentIndex]
          : null;

  bool get hasMultipleDocuments => documents.length > 1;

  bool get canGoNext => currentIndex < documents.length - 1;

  bool get canGoPrevious => currentIndex > 0;

  String get pageIndicator => '${currentIndex + 1} / ${documents.length}';

  @override
  List<Object?> get props => [documents, currentIndex, isLoading, error, isZoomed];
}
