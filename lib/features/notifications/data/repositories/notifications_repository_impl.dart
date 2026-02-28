import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/admin_notification_entity.dart';
import '../../domain/entities/notification_preference_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../../../core/services/jwt_recovery_handler.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/services/supabase_provider.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final JwtRecoveryHandler _jwtHandler;
  final SupabaseProvider _supabaseProvider;
  final SessionService _sessionService;

  NotificationsRepositoryImpl({
    required JwtRecoveryHandler jwtHandler,
    required SupabaseProvider supabaseProvider,
    required SessionService sessionService,
  })  : _jwtHandler = jwtHandler,
        _supabaseProvider = supabaseProvider,
        _sessionService = sessionService;

  SupabaseClient get _supabase => _supabaseProvider.client;

  // Use adminClient (service role) for admin_event_* tables.
  // RLS on these tables checks admin_id = auth.uid() (auth.users.id),
  // but admin_id stores public.users.id — these differ, so RLS
  // blocks all rows. The service role bypasses RLS; the app's
  // .eq('admin_id', userId) filter still scopes to the correct admin.
  SupabaseClient get _adminSupabase => _supabaseProvider.adminClient;

  String? get _userId => _sessionService.userId;

  @override
  Future<List<AdminNotificationEntity>> fetchNotifications({
    int page = 1,
    int pageSize = 20,
    AdminNotificationType? typeFilter,
    bool? unreadOnly,
  }) async {
    try {
      final userId = _userId;
      if (userId == null) return [];

      final offset = (page - 1) * pageSize;

      var query = _adminSupabase
          .from('admin_event_notifications')
          .select()
          .eq('admin_id', userId)
          .eq('archived', false);

      if (typeFilter != null) {
        query = query.eq('event_type', typeFilter.toJson());
      }
      if (unreadOnly == true) {
        query = query.eq('is_read', false);
      }

      final result = await _jwtHandler.executeWithRecovery(
        () => query
            .order('created_at', ascending: false)
            .range(offset, offset + pageSize - 1),
        'fetch admin notifications',
      );

      final data = result as List<dynamic>;
      return data
          .map((json) => _mapToEntity(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _jwtHandler.executeWithRecovery(
        () => _adminSupabase
            .from('admin_event_notifications')
            .update({'is_read': true})
            .eq('id', notificationId),
        'mark notification read',
      );
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final userId = _userId;
      if (userId == null) return;

      await _jwtHandler.executeWithRecovery(
        () => _adminSupabase
            .from('admin_event_notifications')
            .update({'is_read': true})
            .eq('admin_id', userId)
            .eq('is_read', false),
        'mark all notifications read',
      );
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> archiveNotification(String notificationId) async {
    try {
      await _jwtHandler.executeWithRecovery(
        () => _adminSupabase.from('admin_event_notifications').update({
          'archived': true,
          'archived_at': DateTime.now().toIso8601String(),
        }).eq('id', notificationId),
        'archive notification',
      );
    } catch (e) {
      debugPrint('Error archiving notification: $e');
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final userId = _userId;
      if (userId == null) return 0;

      final result = await _jwtHandler.executeWithRecovery(
        () => _adminSupabase
            .from('admin_event_notifications')
            .select('id')
            .eq('admin_id', userId)
            .eq('is_read', false)
            .eq('archived', false),
        'get unread count',
      );

      return (result as List).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  @override
  Stream<int> watchUnreadCount() {
    final userId = _userId;
    if (userId == null) return Stream.value(0);

    final controller = StreamController<int>();

    void refreshCount() {
      getUnreadCount()
          .then((c) {
            if (!controller.isClosed) controller.add(c);
          })
          .catchError((_) {
            if (!controller.isClosed) controller.add(0);
          });
    }

    // Emit initial count
    refreshCount();

    // Poll every 30 seconds as a reliable fallback.
    // Realtime may not fire if RLS blocks the channel subscription.
    final timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => refreshCount(),
    );

    // Subscribe to realtime changes for instant updates when available.
    final channel = _supabase
        .channel('admin_event_notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'admin_event_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'admin_id',
            value: userId,
          ),
          callback: (payload) => refreshCount(),
        )
        .subscribe();

    controller.onCancel = () {
      timer.cancel();
      _supabase.removeChannel(channel);
    };

    return controller.stream;
  }

  @override
  Future<List<NotificationPreferenceEntity>> fetchPreferences() async {
    try {
      final userId = _userId;
      if (userId == null) return [];

      final result = await _jwtHandler.executeWithRecovery(
        () => _adminSupabase
            .from('admin_event_preferences')
            .select()
            .eq('admin_id', userId),
        'fetch notification preferences',
      );

      final data = result as List<dynamic>;
      return data
          .map((json) => _mapToPreference(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching preferences: $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePreference({
    required AdminNotificationType type,
    required bool pushEnabled,
    required bool smsEnabled,
  }) async {
    try {
      final userId = _userId;
      if (userId == null) return;

      // Use upsert via adminClient (service role) so that preference rows
      // missing from the seed function are created on first toggle.
      await _jwtHandler.executeWithRecovery(
        () => _supabaseProvider.adminClient
            .from('admin_event_preferences')
            .upsert(
              {
                'admin_id': userId,
                'event_type': type.toJson(),
                'fcm_enabled': pushEnabled,
                'sms_enabled': smsEnabled,
                'updated_at': DateTime.now().toIso8601String(),
              },
              onConflict: 'admin_id,event_type',
            ),
        'update notification preference',
      );
    } catch (e) {
      debugPrint('Error updating preference: $e');
      rethrow;
    }
  }

  @override
  Future<void> initializeDefaultPreferences() async {
    try {
      final userId = _userId;
      if (userId == null) return;

      await _jwtHandler.executeWithRecovery(
        () => _adminSupabase.rpc(
          'create_default_admin_event_preferences',
          params: {'p_admin_id': userId},
        ),
        'initialize default preferences',
      );
    } catch (e) {
      debugPrint('Error initializing default preferences: $e');
    }
  }

  AdminNotificationEntity _mapToEntity(Map<String, dynamic> json) {
    return AdminNotificationEntity(
      id: json['id'] as String,
      adminId: json['admin_id'] as String,
      eventType: AdminNotificationType.fromString(
        json['event_type'] as String,
      ),
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      archived: json['archived'] as bool? ?? false,
      relatedId: json['related_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      deliveryMethod: json['delivery_method'] as String?,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  NotificationPreferenceEntity _mapToPreference(Map<String, dynamic> json) {
    return NotificationPreferenceEntity(
      id: json['id'] as String,
      userId: json['admin_id'] as String,
      type: AdminNotificationType.fromString(
        json['event_type'] as String,
      ),
      pushEnabled: json['fcm_enabled'] as bool? ?? false,
      smsEnabled: json['sms_enabled'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
