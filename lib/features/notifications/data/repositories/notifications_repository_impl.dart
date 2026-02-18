import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/admin_notification_entity.dart';
import '../../domain/entities/notification_preference_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../../../core/services/jwt_recovery_handler.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/services/supabase_provider.dart';

/// Admin notification types stored in the DB.
const _adminNotificationTypes = [
  'dispute_filed',
  'dispute_escalated',
  'dispute_resolved',
  'driver_pending_approval',
  'driver_document_uploaded',
  'driver_suspended',
  'payment_failed',
  'payment_refund_requested',
  'admin_system_alert',
];

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

      var query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('archived', false)
          .inFilter('type', _adminNotificationTypes);

      if (typeFilter != null) {
        query = query.eq('type', typeFilter.toJson());
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
        () => _supabase
            .from('notifications')
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
        () => _supabase
            .from('notifications')
            .update({'is_read': true})
            .eq('user_id', userId)
            .eq('is_read', false)
            .inFilter('type', _adminNotificationTypes),
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
        () => _supabase.from('notifications').update({
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
        () => _supabase
            .from('notifications')
            .select('id')
            .eq('user_id', userId)
            .eq('is_read', false)
            .eq('archived', false)
            .inFilter('type', _adminNotificationTypes),
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

    // Emit initial count
    getUnreadCount().then(controller.add).catchError((_) => controller.add(0));

    // Subscribe to realtime changes on notifications table
    final channel = _supabase
        .channel('admin_notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            // Re-fetch count on any change
            getUnreadCount()
                .then(controller.add)
                .catchError((_) {});
          },
        )
        .subscribe();

    controller.onCancel = () {
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
        () => _supabase
            .from('notification_type_preferences')
            .select()
            .eq('user_id', userId)
            .inFilter('notification_type', _adminNotificationTypes),
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

      await _jwtHandler.executeWithRecovery(
        () => _supabase.rpc('set_notification_preference', params: {
          'p_user_id': userId,
          'p_notification_type': type.toJson(),
          'p_push_enabled': pushEnabled,
          'p_sms_enabled': smsEnabled,
        }),
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
        () => _supabase.rpc(
          'create_default_admin_notification_preferences',
          params: {'p_user_id': userId},
        ),
        'initialize default preferences',
      );
    } catch (e) {
      debugPrint('Error initializing default preferences: $e');
    }
  }

  AdminNotificationEntity _mapToEntity(Map<String, dynamic> json) {
    AdminNotificationType? type;
    final typeStr = json['type'] as String?;
    if (typeStr != null && _adminNotificationTypes.contains(typeStr)) {
      type = AdminNotificationType.fromString(typeStr);
    }

    return AdminNotificationEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      archived: json['archived'] as bool? ?? false,
      type: type,
      relatedId: json['related_id'] as String?,
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
      userId: json['user_id'] as String,
      type: AdminNotificationType.fromString(
        json['notification_type'] as String,
      ),
      pushEnabled: json['push_enabled'] as bool? ?? false,
      smsEnabled: json['sms_enabled'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
