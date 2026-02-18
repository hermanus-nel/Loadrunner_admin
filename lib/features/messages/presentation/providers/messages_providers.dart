// lib/features/messages/presentation/providers/messages_providers.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/message_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_template_entity.dart';
import '../../domain/repositories/messages_repository.dart';
import '../../data/repositories/messages_repository_impl.dart';
import '../../../../core/services/jwt_recovery_handler.dart';
import '../../../../core/services/core_providers.dart';

// ============================================================================
// REPOSITORY PROVIDER
// ============================================================================

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  final jwtHandler = ref.watch(jwtRecoveryHandlerProvider);
  final supabaseProvider = ref.watch(supabaseProviderInstance);
  
  return MessagesRepositoryImpl(
    jwtHandler: jwtHandler,
    supabaseProvider: supabaseProvider,
    sessionService: ref.watch(sessionServiceProvider),
  );
});

// ============================================================================
// CONVERSATIONS STATE
// ============================================================================

@immutable
class ConversationsState {
  final List<ConversationEntity> conversations;
  final ConversationStats stats;
  final MessagesPagination pagination;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? searchQuery;

  const ConversationsState({
    this.conversations = const [],
    this.stats = const ConversationStats(),
    this.pagination = const MessagesPagination(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.searchQuery,
  });

  ConversationsState copyWith({
    List<ConversationEntity>? conversations,
    ConversationStats? stats,
    MessagesPagination? pagination,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? searchQuery,
    bool clearError = false,
    bool clearSearch = false,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      stats: stats ?? this.stats,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }
}

class ConversationsNotifier extends StateNotifier<ConversationsState> {
  final MessagesRepository _repository;

  ConversationsNotifier(this._repository) : super(const ConversationsState());

  Future<void> fetchConversations({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      pagination: refresh ? const MessagesPagination() : state.pagination,
    );

    try {
      final result = await _repository.fetchConversations(
        pagination: state.pagination.copyWith(page: 1),
        searchQuery: state.searchQuery,
      );

      state = state.copyWith(
        conversations: result.conversations,
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
      final result = await _repository.fetchConversations(
        pagination: state.pagination.copyWith(page: state.pagination.page + 1),
        searchQuery: state.searchQuery,
      );

      state = state.copyWith(
        conversations: [...state.conversations, ...result.conversations],
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

  void search(String query) {
    state = state.copyWith(
      searchQuery: query.isEmpty ? null : query,
      clearSearch: query.isEmpty,
    );
    fetchConversations(refresh: true);
  }

  void clearSearch() {
    state = state.copyWith(clearSearch: true);
    fetchConversations(refresh: true);
  }
}

final conversationsNotifierProvider =
    StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) {
  final repository = ref.watch(messagesRepositoryProvider);
  return ConversationsNotifier(repository);
});

// ============================================================================
// CONVERSATION MESSAGES STATE
// ============================================================================

@immutable
class ConversationMessagesState {
  final List<MessageEntity> messages;
  final MessagesPagination pagination;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSending;
  final String? error;
  final String? userId;

  const ConversationMessagesState({
    this.messages = const [],
    this.pagination = const MessagesPagination(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSending = false,
    this.error,
    this.userId,
  });

  ConversationMessagesState copyWith({
    List<MessageEntity>? messages,
    MessagesPagination? pagination,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSending,
    String? error,
    String? userId,
    bool clearError = false,
  }) {
    return ConversationMessagesState(
      messages: messages ?? this.messages,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
      userId: userId ?? this.userId,
    );
  }
}

class ConversationMessagesNotifier extends StateNotifier<ConversationMessagesState> {
  final MessagesRepository _repository;

  ConversationMessagesNotifier(this._repository) : super(const ConversationMessagesState());

  Future<void> fetchMessages(String userId, {bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      userId: userId,
      pagination: refresh ? const MessagesPagination() : state.pagination,
    );

    try {
      final result = await _repository.fetchMessages(
        userId: userId,
        pagination: state.pagination.copyWith(page: 1),
      );

      state = state.copyWith(
        messages: result.messages,
        pagination: result.pagination,
        isLoading: false,
      );

      // Mark as read
      await _repository.markConversationAsRead(userId: userId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.pagination.hasMore || state.userId == null) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.fetchMessages(
        userId: state.userId!,
        pagination: state.pagination.copyWith(page: state.pagination.page + 1),
      );

      state = state.copyWith(
        messages: [...state.messages, ...result.messages],
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

  Future<SendMessageResult> sendMessage({
    required String body,
    String? subject,
    bool sendPushNotification = false,
  }) async {
    if (state.userId == null) {
      return SendMessageResult.failure('No user selected');
    }

    state = state.copyWith(isSending: true, clearError: true);

    try {
      final result = await _repository.sendMessage(
        recipientId: state.userId!,
        body: body,
        subject: subject,
        sendPushNotification: sendPushNotification,
      );

      if (result.success && result.message != null) {
        // Add message to the beginning of the list
        state = state.copyWith(
          messages: [result.message!, ...state.messages],
          isSending: false,
        );
      } else {
        state = state.copyWith(
          isSending: false,
          error: result.error,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: e.toString(),
      );
      return SendMessageResult.failure(e.toString());
    }
  }
}

final conversationMessagesNotifierProvider =
    StateNotifierProvider<ConversationMessagesNotifier, ConversationMessagesState>((ref) {
  final repository = ref.watch(messagesRepositoryProvider);
  return ConversationMessagesNotifier(repository);
});

// ============================================================================
// BROADCASTS STATE
// ============================================================================

@immutable
class BroadcastsState {
  final List<MessageEntity> broadcasts;
  final MessagesPagination pagination;
  final MessageFilters filters;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSending;
  final String? error;

  const BroadcastsState({
    this.broadcasts = const [],
    this.pagination = const MessagesPagination(),
    this.filters = const MessageFilters(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSending = false,
    this.error,
  });

  BroadcastsState copyWith({
    List<MessageEntity>? broadcasts,
    MessagesPagination? pagination,
    MessageFilters? filters,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return BroadcastsState(
      broadcasts: broadcasts ?? this.broadcasts,
      pagination: pagination ?? this.pagination,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BroadcastsNotifier extends StateNotifier<BroadcastsState> {
  final MessagesRepository _repository;

  BroadcastsNotifier(this._repository) : super(const BroadcastsState());

  Future<void> fetchBroadcasts({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      pagination: refresh ? const MessagesPagination() : state.pagination,
    );

    try {
      final result = await _repository.fetchBroadcasts(
        pagination: state.pagination.copyWith(page: 1),
        filters: state.filters,
      );

      state = state.copyWith(
        broadcasts: result.messages,
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
      final result = await _repository.fetchBroadcasts(
        pagination: state.pagination.copyWith(page: state.pagination.page + 1),
        filters: state.filters,
      );

      state = state.copyWith(
        broadcasts: [...state.broadcasts, ...result.messages],
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

  Future<BroadcastResult> sendBroadcast({
    required BroadcastAudience audience,
    required String body,
    String? subject,
    bool sendPushNotification = false,
  }) async {
    state = state.copyWith(isSending: true, clearError: true);

    try {
      final result = await _repository.sendBroadcast(
        audience: audience,
        body: body,
        subject: subject,
        sendPushNotification: sendPushNotification,
      );

      state = state.copyWith(isSending: false);

      if (result.success) {
        // Refresh broadcasts list
        fetchBroadcasts(refresh: true);
      } else {
        state = state.copyWith(error: result.error);
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: e.toString(),
      );
      return BroadcastResult.failure(e.toString());
    }
  }

  void updateFilters(MessageFilters filters) {
    state = state.copyWith(filters: filters);
    fetchBroadcasts(refresh: true);
  }
}

final broadcastsNotifierProvider =
    StateNotifierProvider<BroadcastsNotifier, BroadcastsState>((ref) {
  final repository = ref.watch(messagesRepositoryProvider);
  return BroadcastsNotifier(repository);
});

// ============================================================================
// TEMPLATES STATE
// ============================================================================

@immutable
class TemplatesState {
  final List<MessageTemplateEntity> templates;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final TemplateCategory? filterCategory;

  const TemplatesState({
    this.templates = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.filterCategory,
  });

  TemplatesState copyWith({
    List<MessageTemplateEntity>? templates,
    bool? isLoading,
    bool? isSaving,
    String? error,
    TemplateCategory? filterCategory,
    bool clearError = false,
    bool clearFilter = false,
  }) {
    return TemplatesState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      filterCategory: clearFilter ? null : (filterCategory ?? this.filterCategory),
    );
  }

  List<MessageTemplateEntity> get filteredTemplates {
    if (filterCategory == null) return templates;
    return templates.where((t) => t.category == filterCategory).toList();
  }
}

class TemplatesNotifier extends StateNotifier<TemplatesState> {
  final MessagesRepository _repository;

  TemplatesNotifier(this._repository) : super(const TemplatesState());

  Future<void> fetchTemplates() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final templates = await _repository.fetchTemplates(
        category: state.filterCategory,
      );

      state = state.copyWith(
        templates: templates,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<TemplateResult> createTemplate({
    required String name,
    required String body,
    String? subject,
    TemplateCategory category = TemplateCategory.general,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final result = await _repository.createTemplate(
        name: name,
        body: body,
        subject: subject,
        category: category,
      );

      state = state.copyWith(isSaving: false);

      if (result.success) {
        fetchTemplates();
      } else {
        state = state.copyWith(error: result.error);
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return TemplateResult.failure(e.toString());
    }
  }

  Future<TemplateResult> updateTemplate({
    required String templateId,
    String? name,
    String? body,
    String? subject,
    TemplateCategory? category,
    bool? isActive,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final result = await _repository.updateTemplate(
        templateId: templateId,
        name: name,
        body: body,
        subject: subject,
        category: category,
        isActive: isActive,
      );

      state = state.copyWith(isSaving: false);

      if (result.success) {
        fetchTemplates();
      } else {
        state = state.copyWith(error: result.error);
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return TemplateResult.failure(e.toString());
    }
  }

  Future<bool> deleteTemplate(String templateId) async {
    try {
      final success = await _repository.deleteTemplate(templateId: templateId);
      if (success) {
        fetchTemplates();
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void filterByCategory(TemplateCategory? category) {
    state = state.copyWith(
      filterCategory: category,
      clearFilter: category == null,
    );
  }
}

final templatesNotifierProvider =
    StateNotifierProvider<TemplatesNotifier, TemplatesState>((ref) {
  final repository = ref.watch(messagesRepositoryProvider);
  return TemplatesNotifier(repository);
});

// ============================================================================
// USER SEARCH STATE
// ============================================================================

@immutable
class UserSearchState {
  final List<MessageUserInfo> results;
  final bool isSearching;
  final String? error;
  final String? query;

  const UserSearchState({
    this.results = const [],
    this.isSearching = false,
    this.error,
    this.query,
  });

  UserSearchState copyWith({
    List<MessageUserInfo>? results,
    bool? isSearching,
    String? error,
    String? query,
    bool clearError = false,
    bool clearResults = false,
  }) {
    return UserSearchState(
      results: clearResults ? [] : (results ?? this.results),
      isSearching: isSearching ?? this.isSearching,
      error: clearError ? null : (error ?? this.error),
      query: query ?? this.query,
    );
  }
}

class UserSearchNotifier extends StateNotifier<UserSearchState> {
  final MessagesRepository _repository;

  UserSearchNotifier(this._repository) : super(const UserSearchState());

  Future<void> search(String query, {String? role}) async {
    if (query.isEmpty) {
      state = state.copyWith(clearResults: true, query: null);
      return;
    }

    state = state.copyWith(isSearching: true, query: query, clearError: true);

    try {
      final results = await _repository.searchUsers(
        query: query,
        role: role,
      );

      state = state.copyWith(
        results: results,
        isSearching: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: e.toString(),
      );
    }
  }

  void clear() {
    state = const UserSearchState();
  }
}

final userSearchNotifierProvider =
    StateNotifierProvider<UserSearchNotifier, UserSearchState>((ref) {
  final repository = ref.watch(messagesRepositoryProvider);
  return UserSearchNotifier(repository);
});

// ============================================================================
// UNREAD COUNT PROVIDER
// ============================================================================

final unreadCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(messagesRepositoryProvider);
  return repository.getUnreadCount();
});

// ============================================================================
// STATS PROVIDER
// ============================================================================

final messageStatsProvider = FutureProvider<ConversationStats>((ref) async {
  final repository = ref.watch(messagesRepositoryProvider);
  return repository.getStats();
});
