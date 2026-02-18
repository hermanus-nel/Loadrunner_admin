import '../entities/admin_notification_entity.dart';
import '../entities/notification_preference_entity.dart';

/// Abstract repository for admin notifications and preferences.
abstract class NotificationsRepository {
  /// Fetch paginated notifications for the current admin.
  Future<List<AdminNotificationEntity>> fetchNotifications({
    int page = 1,
    int pageSize = 20,
    AdminNotificationType? typeFilter,
    bool? unreadOnly,
  });

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId);

  /// Mark all unread notifications as read.
  Future<void> markAllAsRead();

  /// Archive a notification.
  Future<void> archiveNotification(String notificationId);

  /// Get the current unread count.
  Future<int> getUnreadCount();

  /// Watch unread count in real-time via Supabase Realtime.
  Stream<int> watchUnreadCount();

  /// Fetch all admin notification preferences.
  Future<List<NotificationPreferenceEntity>> fetchPreferences();

  /// Update a single preference toggle.
  Future<void> updatePreference({
    required AdminNotificationType type,
    required bool pushEnabled,
    required bool smsEnabled,
  });

  /// Initialize default preferences for the current admin.
  Future<void> initializeDefaultPreferences();
}
