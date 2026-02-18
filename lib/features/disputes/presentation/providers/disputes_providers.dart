// lib/features/disputes/presentation/providers/disputes_providers.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/dispute_entity.dart';
import '../../domain/entities/evidence_entity.dart';
import '../../domain/repositories/disputes_repository.dart';
import '../../data/repositories/disputes_repository_impl.dart';
import '../../../../core/services/jwt_recovery_handler.dart';
import '../../../../core/services/core_providers.dart';

// ============================================================================
// REPOSITORY PROVIDER
// ============================================================================

final disputesRepositoryProvider = Provider<DisputesRepository>((ref) {
  final jwtHandler = ref.watch(jwtRecoveryHandlerProvider);
  final supabaseProvider = ref.watch(supabaseProviderInstance);

  return DisputesRepositoryImpl(
    jwtHandler: jwtHandler,
    supabaseProvider: supabaseProvider,
    sessionService: ref.watch(sessionServiceProvider),
  );
});

// ============================================================================
// DISPUTES LIST STATE
// ============================================================================

@immutable
class DisputesListState {
  final List<DisputeEntity> disputes;
  final DisputeStats stats;
  final DisputesPagination pagination;
  final DisputeFilters filters;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const DisputesListState({
    this.disputes = const [],
    this.stats = const DisputeStats(),
    this.pagination = const DisputesPagination(),
    this.filters = const DisputeFilters(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  DisputesListState copyWith({
    List<DisputeEntity>? disputes,
    DisputeStats? stats,
    DisputesPagination? pagination,
    DisputeFilters? filters,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return DisputesListState(
      disputes: disputes ?? this.disputes,
      stats: stats ?? this.stats,
      pagination: pagination ?? this.pagination,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DisputesListNotifier extends StateNotifier<DisputesListState> {
  final DisputesRepository _repository;

  DisputesListNotifier(this._repository) : super(const DisputesListState());

  Future<void> fetchDisputes({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      pagination: refresh ? const DisputesPagination() : state.pagination,
    );

    try {
      final result = await _repository.fetchDisputes(
        filters: state.filters,
        pagination: state.pagination.copyWith(page: 1),
      );

      state = state.copyWith(
        disputes: result.disputes,
        stats: result.stats,
        pagination: result.pagination,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.pagination.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.fetchDisputes(
        filters: state.filters,
        pagination: state.pagination.copyWith(page: state.pagination.page + 1),
      );

      state = state.copyWith(
        disputes: [...state.disputes, ...result.disputes],
        pagination: result.pagination,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  void updateFilters(DisputeFilters filters) {
    state = state.copyWith(filters: filters);
    fetchDisputes(refresh: true);
  }

  void clearFilters() {
    state = state.copyWith(filters: const DisputeFilters());
    fetchDisputes(refresh: true);
  }

  void filterByStatus(DisputeStatus? status) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        status: status,
        clearStatus: status == null,
      ),
    );
    fetchDisputes(refresh: true);
  }

  void filterByType(DisputeType? type) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        type: type,
        clearType: type == null,
      ),
    );
    fetchDisputes(refresh: true);
  }

  void filterByPriority(DisputePriority? priority) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        priority: priority,
        clearPriority: priority == null,
      ),
    );
    fetchDisputes(refresh: true);
  }

  void search(String query) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        searchQuery: query.isEmpty ? null : query,
        clearSearch: query.isEmpty,
      ),
    );
    fetchDisputes(refresh: true);
  }

  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        startDate: startDate,
        endDate: endDate,
        clearDates: startDate == null && endDate == null,
      ),
    );
    fetchDisputes(refresh: true);
  }

  void filterAssignedToMe(bool assignedToMe) {
    state = state.copyWith(
      filters: state.filters.copyWith(assignedToMe: assignedToMe ? true : null),
    );
    fetchDisputes(refresh: true);
  }
}

final disputesListNotifierProvider =
    StateNotifierProvider<DisputesListNotifier, DisputesListState>((ref) {
  final repository = ref.watch(disputesRepositoryProvider);
  return DisputesListNotifier(repository);
});

// ============================================================================
// DISPUTE DETAIL STATE
// ============================================================================

@immutable
class DisputeDetailState {
  final DisputeEntity? dispute;
  final List<EvidenceEntity> evidence;
  final List<DisputeTimelineEvent> timeline;
  final bool isLoading;
  final bool isUpdating;
  final String? error;

  const DisputeDetailState({
    this.dispute,
    this.evidence = const [],
    this.timeline = const [],
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
  });

  DisputeDetailState copyWith({
    DisputeEntity? dispute,
    List<EvidenceEntity>? evidence,
    List<DisputeTimelineEvent>? timeline,
    bool? isLoading,
    bool? isUpdating,
    String? error,
    bool clearError = false,
    bool clearDispute = false,
  }) {
    return DisputeDetailState(
      dispute: clearDispute ? null : (dispute ?? this.dispute),
      evidence: evidence ?? this.evidence,
      timeline: timeline ?? this.timeline,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DisputeDetailNotifier extends StateNotifier<DisputeDetailState> {
  final DisputesRepository _repository;

  DisputeDetailNotifier(this._repository) : super(const DisputeDetailState());

  Future<void> fetchDisputeDetail(String disputeId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearDispute: true);

    try {
      final result = await _repository.fetchDisputeDetail(disputeId: disputeId);

      state = state.copyWith(
        dispute: result.dispute,
        evidence: result.evidence,
        timeline: result.timeline,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<ResolveDisputeResult> resolveDispute({
    required String disputeId,
    required ResolutionType resolution,
    required String notes,
    double? refundAmount,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final result = await _repository.resolveDispute(
        disputeId: disputeId,
        resolution: resolution,
        notes: notes,
        refundAmount: refundAmount,
      );

      if (result.success && result.dispute != null) {
        state = state.copyWith(
          dispute: result.dispute,
          isUpdating: false,
        );
        // Refresh timeline
        final timeline = await _repository.fetchTimeline(disputeId: disputeId);
        state = state.copyWith(timeline: timeline);
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result.error,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return ResolveDisputeResult.failure(e.toString());
    }
  }

  Future<EscalateDisputeResult> escalateDispute({
    required String disputeId,
    required String reason,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final result = await _repository.escalateDispute(
        disputeId: disputeId,
        reason: reason,
      );

      if (result.success && result.dispute != null) {
        state = state.copyWith(
          dispute: result.dispute,
          isUpdating: false,
        );
        // Refresh timeline
        final timeline = await _repository.fetchTimeline(disputeId: disputeId);
        state = state.copyWith(timeline: timeline);
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result.error,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return EscalateDisputeResult.failure(e.toString());
    }
  }

  Future<UpdateDisputeResult> updateStatus({
    required String disputeId,
    required DisputeStatus status,
    String? notes,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final result = await _repository.updateDisputeStatus(
        disputeId: disputeId,
        status: status,
        notes: notes,
      );

      if (result.success && result.dispute != null) {
        state = state.copyWith(
          dispute: result.dispute,
          isUpdating: false,
        );
        // Refresh timeline
        final timeline = await _repository.fetchTimeline(disputeId: disputeId);
        state = state.copyWith(timeline: timeline);
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result.error,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return UpdateDisputeResult.failure(e.toString());
    }
  }

  Future<UpdateDisputeResult> updatePriority({
    required String disputeId,
    required DisputePriority priority,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final result = await _repository.updateDisputePriority(
        disputeId: disputeId,
        priority: priority,
      );

      if (result.success && result.dispute != null) {
        state = state.copyWith(
          dispute: result.dispute,
          isUpdating: false,
        );
        // Refresh timeline
        final timeline = await _repository.fetchTimeline(disputeId: disputeId);
        state = state.copyWith(timeline: timeline);
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result.error,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return UpdateDisputeResult.failure(e.toString());
    }
  }

  Future<UpdateDisputeResult> assignToSelf({required String disputeId}) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final result = await _repository.assignToSelf(disputeId: disputeId);

      if (result.success) {
        // Refresh dispute detail
        await fetchDisputeDetail(disputeId);
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result.error,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return UpdateDisputeResult.failure(e.toString());
    }
  }

  Future<AddEvidenceResult> addEvidence({
    required String disputeId,
    required EvidenceType type,
    required String description,
    String? fileUrl,
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final result = await _repository.addEvidence(
        disputeId: disputeId,
        type: type,
        description: description,
        fileUrl: fileUrl,
        metadata: metadata,
      );

      if (result.success && result.evidence != null) {
        state = state.copyWith(
          evidence: [result.evidence!, ...state.evidence],
          isUpdating: false,
        );
        // Refresh timeline
        final timeline = await _repository.fetchTimeline(disputeId: disputeId);
        state = state.copyWith(timeline: timeline);
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result.error,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return AddEvidenceResult.failure(e.toString());
    }
  }

  Future<bool> requestEvidence({
    required String disputeId,
    required String userId,
    required String message,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final success = await _repository.requestEvidence(
        disputeId: disputeId,
        userId: userId,
        message: message,
      );

      if (success) {
        // Refresh dispute detail
        await fetchDisputeDetail(disputeId);
      }

      state = state.copyWith(isUpdating: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> addNote({
    required String disputeId,
    required String content,
    bool isInternal = true,
  }) async {
    try {
      final success = await _repository.addNote(
        disputeId: disputeId,
        content: content,
        isInternal: isInternal,
      );

      if (success) {
        // Refresh timeline
        final timeline = await _repository.fetchTimeline(disputeId: disputeId);
        state = state.copyWith(timeline: timeline);
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  void clear() {
    state = const DisputeDetailState();
  }
}

final disputeDetailNotifierProvider =
    StateNotifierProvider<DisputeDetailNotifier, DisputeDetailState>((ref) {
  final repository = ref.watch(disputesRepositoryProvider);
  return DisputeDetailNotifier(repository);
});

// ============================================================================
// STATS PROVIDER
// ============================================================================

final disputeStatsProvider = FutureProvider.family<DisputeStats, ({DateTime? startDate, DateTime? endDate})>(
  (ref, params) async {
    final repository = ref.watch(disputesRepositoryProvider);
    return repository.getStats(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  },
);

final defaultDisputeStatsProvider = FutureProvider<DisputeStats>((ref) async {
  final repository = ref.watch(disputesRepositoryProvider);
  final now = DateTime.now();
  return repository.getStats(
    startDate: now.subtract(const Duration(days: 30)),
    endDate: now,
  );
});

// ============================================================================
// DISPUTES BY USER PROVIDER
// ============================================================================

final disputesByUserProvider = FutureProvider.family<List<DisputeEntity>, String>(
  (ref, userId) async {
    final repository = ref.watch(disputesRepositoryProvider);
    return repository.getDisputesByUser(userId: userId);
  },
);

// ============================================================================
// DISPUTES BY SHIPMENT PROVIDER
// ============================================================================

final disputesByShipmentProvider = FutureProvider.family<List<DisputeEntity>, String>(
  (ref, shipmentId) async {
    final repository = ref.watch(disputesRepositoryProvider);
    return repository.getDisputesByShipment(shipmentId: shipmentId);
  },
);
