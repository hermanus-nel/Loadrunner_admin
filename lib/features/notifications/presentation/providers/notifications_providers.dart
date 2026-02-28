import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/admin_notification_entity.dart';
import '../../domain/entities/notification_preference_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../../../core/services/core_providers.dart';

// ============================================================
// REPOSITORY PROVIDER
// ============================================================

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(
    jwtHandler: ref.watch(jwtRecoveryHandlerProvider),
    supabaseProvider: ref.watch(supabaseProviderInstance),
    sessionService: ref.watch(sessionServiceProvider),
  );
});

// ============================================================
// UNREAD COUNT (real-time stream)
// ============================================================

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  // Re-create the stream when userId changes (login/logout).
  // Without this, the provider may be created before auth completes,
  // capture a null userId, and return Stream.value(0) forever.
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(0);

  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.watchUnreadCount();
});

// ============================================================
// NOTIFICATIONS LIST
// ============================================================

class NotificationsListState {
  final List<AdminNotificationEntity> notifications;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final AdminNotificationType? typeFilter;
  final bool unreadOnly;

  const NotificationsListState({
    this.notifications = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.typeFilter,
    this.unreadOnly = false,
  });

  NotificationsListState copyWith({
    List<AdminNotificationEntity>? notifications,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMore,
    AdminNotificationType? typeFilter,
    bool? unreadOnly,
    bool clearError = false,
    bool clearTypeFilter = false,
  }) {
    return NotificationsListState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      unreadOnly: unreadOnly ?? this.unreadOnly,
    );
  }
}

class NotificationsListNotifier extends StateNotifier<NotificationsListState> {
  final NotificationsRepository _repository;
  static const _pageSize = 20;

  NotificationsListNotifier(this._repository)
      : super(const NotificationsListState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final notifications = await _repository.fetchNotifications(
        page: 1,
        pageSize: _pageSize,
        typeFilter: state.typeFilter,
        unreadOnly: state.unreadOnly ? true : null,
      );
      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
        currentPage: 1,
        hasMore: notifications.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final notifications = await _repository.fetchNotifications(
        page: nextPage,
        pageSize: _pageSize,
        typeFilter: state.typeFilter,
        unreadOnly: state.unreadOnly ? true : null,
      );
      state = state.copyWith(
        notifications: [...state.notifications, ...notifications],
        isLoadingMore: false,
        currentPage: nextPage,
        hasMore: notifications.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    await loadNotifications();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      state = state.copyWith(
        notifications: state.notifications
            .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
            .toList(),
      );
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      state = state.copyWith(
        notifications:
            state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
      );
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> archiveNotification(String notificationId) async {
    try {
      await _repository.archiveNotification(notificationId);
      state = state.copyWith(
        notifications:
            state.notifications.where((n) => n.id != notificationId).toList(),
      );
    } catch (e) {
      debugPrint('Error archiving notification: $e');
    }
  }

  void setTypeFilter(AdminNotificationType? type) {
    if (type == state.typeFilter) return;
    state = state.copyWith(
      typeFilter: type,
      clearTypeFilter: type == null,
    );
    loadNotifications();
  }

  void setUnreadOnly(bool unreadOnly) {
    if (unreadOnly == state.unreadOnly) return;
    state = state.copyWith(unreadOnly: unreadOnly);
    loadNotifications();
  }
}

final notificationsListNotifierProvider = StateNotifierProvider<
    NotificationsListNotifier, NotificationsListState>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  return NotificationsListNotifier(repo);
});

// ============================================================
// NOTIFICATION PREFERENCES
// ============================================================

class NotificationPreferencesState {
  final List<NotificationPreferenceEntity> preferences;
  final bool isLoading;
  final String? error;

  const NotificationPreferencesState({
    this.preferences = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationPreferencesState copyWith({
    List<NotificationPreferenceEntity>? preferences,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationPreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Get preference for a specific type.
  NotificationPreferenceEntity? preferenceFor(AdminNotificationType type) {
    try {
      return preferences.firstWhere((p) => p.type == type);
    } catch (_) {
      return null;
    }
  }
}

class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferencesState> {
  final NotificationsRepository _repository;

  NotificationPreferencesNotifier(this._repository)
      : super(const NotificationPreferencesState()) {
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Ensure defaults exist first
      await _repository.initializeDefaultPreferences();
      final preferences = await _repository.fetchPreferences();
      state = state.copyWith(
        preferences: preferences,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updatePreference({
    required AdminNotificationType type,
    required bool pushEnabled,
    required bool smsEnabled,
  }) async {
    // Optimistic update
    final existing = state.preferences.any((p) => p.type == type);
    if (existing) {
      state = state.copyWith(
        preferences: state.preferences.map((p) {
          if (p.type == type) {
            return p.copyWith(pushEnabled: pushEnabled, smsEnabled: smsEnabled);
          }
          return p;
        }).toList(),
      );
    } else {
      // Preference not in list yet — add it optimistically
      state = state.copyWith(
        preferences: [
          ...state.preferences,
          NotificationPreferenceEntity(
            id: '', // Temporary; will be replaced on reload
            userId: '',
            type: type,
            pushEnabled: pushEnabled,
            smsEnabled: smsEnabled,
          ),
        ],
      );
    }

    try {
      await _repository.updatePreference(
        type: type,
        pushEnabled: pushEnabled,
        smsEnabled: smsEnabled,
      );
      // Reload to get the real DB row (with correct id) if we inserted a new one
      if (!existing) {
        await loadPreferences();
      }
    } catch (e) {
      // Revert on failure
      await loadPreferences();
      debugPrint('Error updating preference: $e');
    }
  }

  /// Toggle all types in a category for a single channel.
  /// Only the provided channel is changed; the other is preserved per-type.
  Future<void> toggleCategory({
    required List<AdminNotificationType> types,
    bool? pushEnabled,
    bool? smsEnabled,
  }) async {
    for (final type in types) {
      final pref = state.preferenceFor(type);
      await updatePreference(
        type: type,
        pushEnabled: pushEnabled ?? pref?.pushEnabled ?? false,
        smsEnabled: smsEnabled ?? pref?.smsEnabled ?? false,
      );
    }
  }
}

final notificationPreferencesNotifierProvider = StateNotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferencesState>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  return NotificationPreferencesNotifier(repo);
});
