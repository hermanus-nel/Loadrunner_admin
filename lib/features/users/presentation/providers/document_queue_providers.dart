import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/core_providers.dart';
import '../../data/repositories/document_review_repository.dart';
import '../../domain/entities/document_queue_item.dart';

// ============================================================
// REPOSITORY PROVIDER
// ============================================================

/// Provider for DocumentReviewRepository
final documentReviewRepositoryProvider =
    Provider<DocumentReviewRepository>((ref) {
  final supabaseProvider = ref.read(supabaseProviderInstance);
  final jwtHandler = ref.read(jwtRecoveryHandlerProvider);
  final sessionService = ref.read(sessionServiceProvider);

  return DocumentReviewRepository(
    supabaseProvider: supabaseProvider,
    jwtRecoveryHandler: jwtHandler,
    sessionService: sessionService,
  );
});

// ============================================================
// DOCUMENT QUEUE STATE
// ============================================================

/// State for the document review queue
class DocumentQueueState {
  final List<DocumentQueueItem> documents;
  final int totalCount;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? docTypeFilter;
  final int currentPage;
  final bool hasMore;

  const DocumentQueueState({
    this.documents = const [],
    this.totalCount = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.docTypeFilter,
    this.currentPage = 0,
    this.hasMore = true,
  });

  factory DocumentQueueState.initial() {
    return const DocumentQueueState(isLoading: true);
  }

  DocumentQueueState copyWith({
    List<DocumentQueueItem>? documents,
    int? totalCount,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? docTypeFilter,
    int? currentPage,
    bool? hasMore,
  }) {
    return DocumentQueueState(
      documents: documents ?? this.documents,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      docTypeFilter: docTypeFilter ?? this.docTypeFilter,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  bool get hasError => error != null;
  bool get isEmpty => documents.isEmpty && !isLoading;
}

// ============================================================
// DOCUMENT QUEUE NOTIFIER
// ============================================================

/// StateNotifier for the document review queue
class DocumentQueueNotifier extends StateNotifier<DocumentQueueState> {
  final DocumentReviewRepository _repository;
  static const int _pageSize = 20;

  DocumentQueueNotifier(this._repository)
      : super(DocumentQueueState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      _loadQueue(refresh: true),
      _loadCount(),
    ]);
  }

  /// Load the document queue
  Future<void> _loadQueue({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    final offset = refresh ? 0 : state.currentPage * _pageSize;

    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 0,
      );
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final documents = await _repository.fetchDocumentQueue(
        limit: _pageSize,
        offset: offset,
        docTypeFilter: state.docTypeFilter,
      );

      final newDocuments =
          refresh ? documents : [...state.documents, ...documents];

      state = state.copyWith(
        documents: newDocuments,
        isLoading: false,
        isLoadingMore: false,
        hasMore: documents.length >= _pageSize,
        currentPage: refresh ? 1 : state.currentPage + 1,
      );

      debugPrint(
        'DocumentQueueNotifier: Loaded ${newDocuments.length} documents',
      );
    } catch (e) {
      debugPrint('DocumentQueueNotifier: Error loading queue: $e');
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Failed to load document queue',
      );
    }
  }

  /// Load the total count
  Future<void> _loadCount() async {
    try {
      final count = await _repository.fetchDocumentQueueCount();
      state = state.copyWith(totalCount: count);
    } catch (e) {
      debugPrint('DocumentQueueNotifier: Error loading count: $e');
    }
  }

  /// Refresh the queue
  Future<void> refresh() async {
    await Future.wait([
      _loadQueue(refresh: true),
      _loadCount(),
    ]);
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    await _loadQueue();
  }

  /// Filter by document type
  void filterByDocType(String? docType) {
    state = state.copyWith(
      docTypeFilter: docType,
      documents: [],
      hasMore: true,
      currentPage: 0,
    );
    _loadQueue(refresh: true);
  }

  /// Remove a document from the local list (optimistic UI after action)
  void removeDocument(String documentId) {
    final updated = state.documents
        .where((item) => item.document.id != documentId)
        .toList();
    state = state.copyWith(
      documents: updated,
      totalCount: state.totalCount > 0 ? state.totalCount - 1 : 0,
    );
  }

  /// Clear error
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(error: null);
    }
  }
}

// ============================================================
// PROVIDERS
// ============================================================

/// Provider for DocumentQueueNotifier
final documentQueueNotifierProvider =
    StateNotifierProvider<DocumentQueueNotifier, DocumentQueueState>((ref) {
  final repository = ref.read(documentReviewRepositoryProvider);
  return DocumentQueueNotifier(repository);
});

/// Provider for the document queue count (for badge)
final documentQueueCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.read(documentReviewRepositoryProvider);
  return repository.fetchDocumentQueueCount();
});
