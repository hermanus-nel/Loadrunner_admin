import 'admin_notification_entity.dart';

/// Represents a notification preference for a specific notification type.
class NotificationPreferenceEntity {
  final String id;
  final String userId;
  final AdminNotificationType type;
  final bool pushEnabled;
  final bool smsEnabled;
  final DateTime? updatedAt;

  const NotificationPreferenceEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.pushEnabled,
    required this.smsEnabled,
    this.updatedAt,
  });

  NotificationPreferenceEntity copyWith({
    bool? pushEnabled,
    bool? smsEnabled,
  }) {
    return NotificationPreferenceEntity(
      id: id,
      userId: userId,
      type: type,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns the delivery method based on toggle states.
  String get deliveryMethod {
    if (pushEnabled && smsEnabled) return 'both';
    if (pushEnabled) return 'push';
    if (smsEnabled) return 'sms';
    return 'none';
  }

  bool get isEnabled => pushEnabled || smsEnabled;
}
