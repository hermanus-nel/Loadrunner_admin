// lib/features/messages/domain/entities/message_entity.dart

import 'package:flutter/foundation.dart';

/// Message type enum matching database message_type column
enum MessageType {
  direct,
  broadcast,
  system;

  static MessageType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'direct':
        return MessageType.direct;
      case 'broadcast':
        return MessageType.broadcast;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.direct;
    }
  }

  String get displayName {
    switch (this) {
      case MessageType.direct:
        return 'Direct Message';
      case MessageType.broadcast:
        return 'Broadcast';
      case MessageType.system:
        return 'System';
    }
  }

  String toJson() => name;
}

/// Target audience for broadcasts
enum BroadcastAudience {
  all,
  drivers,
  shippers,
  verifiedDrivers,
  unverifiedDrivers;

  static BroadcastAudience fromString(String value) {
    switch (value.toLowerCase()) {
      case 'all':
        return BroadcastAudience.all;
      case 'drivers':
      case 'driver':
        return BroadcastAudience.drivers;
      case 'shippers':
      case 'shipper':
        return BroadcastAudience.shippers;
      case 'verified_drivers':
      case 'verifieddrivers':
        return BroadcastAudience.verifiedDrivers;
      case 'unverified_drivers':
      case 'unverifieddrivers':
        return BroadcastAudience.unverifiedDrivers;
      default:
        return BroadcastAudience.all;
    }
  }

  String get displayName {
    switch (this) {
      case BroadcastAudience.all:
        return 'All Users';
      case BroadcastAudience.drivers:
        return 'All Drivers';
      case BroadcastAudience.shippers:
        return 'All Shippers';
      case BroadcastAudience.verifiedDrivers:
        return 'Verified Drivers';
      case BroadcastAudience.unverifiedDrivers:
        return 'Unverified Drivers';
    }
  }

  String toJson() {
    switch (this) {
      case BroadcastAudience.all:
        return 'all';
      case BroadcastAudience.drivers:
        return 'Driver';
      case BroadcastAudience.shippers:
        return 'Shipper';
      case BroadcastAudience.verifiedDrivers:
        return 'verified_drivers';
      case BroadcastAudience.unverifiedDrivers:
        return 'unverified_drivers';
    }
  }
}

/// User info for message participants
@immutable
class MessageUserInfo {
  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? role;
  final String? profilePhotoUrl;

  const MessageUserInfo({
    required this.id,
    this.fullName,
    this.phone,
    this.email,
    this.role,
    this.profilePhotoUrl,
  });

  String get displayName => fullName ?? phone ?? 'Unknown User';
  
  String get initials {
    if (fullName != null && fullName!.isNotEmpty) {
      final parts = fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return fullName![0].toUpperCase();
    }
    return '?';
  }

  factory MessageUserInfo.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name'] as String?;
    final lastName = json['last_name'] as String?;
    String? fullName;
    if (firstName != null || lastName != null) {
      fullName = [firstName, lastName].where((s) => s != null).join(' ').trim();
      if (fullName.isEmpty) fullName = null;
    }

    return MessageUserInfo(
      id: json['id'] as String,
      fullName: fullName,
      phone: json['phone_number'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );
  }
}

/// Main Message Entity
@immutable
class MessageEntity {
  final String id;
  final String? senderId;
  final String? recipientId;
  final MessageType messageType;
  final String? subject;
  final String body;
  final DateTime sentAt;
  final DateTime? readAt;
  final bool pushNotificationSent;
  final Map<String, dynamic>? metadata;
  
  // Target role for broadcasts
  final String? recipientRole;
  
  // Related entities (populated when fetching)
  final MessageUserInfo? sender;
  final MessageUserInfo? recipient;
  
  // Broadcast stats (for broadcast messages)
  final int? recipientCount;

  const MessageEntity({
    required this.id,
    this.senderId,
    this.recipientId,
    required this.messageType,
    this.subject,
    required this.body,
    required this.sentAt,
    this.readAt,
    this.pushNotificationSent = false,
    this.metadata,
    this.recipientRole,
    this.sender,
    this.recipient,
    this.recipientCount,
  });

  /// Check if message is read
  bool get isRead => readAt != null;

  /// Check if this is a broadcast message
  bool get isBroadcast => messageType == MessageType.broadcast;

  /// Check if this is from admin (sent by current admin)
  bool get isFromAdmin => senderId != null;

  /// Get preview text (truncated body)
  String get previewText {
    const maxLength = 100;
    if (body.length <= maxLength) return body;
    return '${body.substring(0, maxLength)}...';
  }

  /// Copy with method for immutability
  MessageEntity copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    MessageType? messageType,
    String? subject,
    String? body,
    DateTime? sentAt,
    DateTime? readAt,
    bool? pushNotificationSent,
    Map<String, dynamic>? metadata,
    String? recipientRole,
    MessageUserInfo? sender,
    MessageUserInfo? recipient,
    int? recipientCount,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      messageType: messageType ?? this.messageType,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      pushNotificationSent: pushNotificationSent ?? this.pushNotificationSent,
      metadata: metadata ?? this.metadata,
      recipientRole: recipientRole ?? this.recipientRole,
      sender: sender ?? this.sender,
      recipient: recipient ?? this.recipient,
      recipientCount: recipientCount ?? this.recipientCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Filter options for fetching messages
@immutable
class MessageFilters {
  final MessageType? messageType;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? unreadOnly;
  final String? searchQuery;

  const MessageFilters({
    this.messageType,
    this.startDate,
    this.endDate,
    this.unreadOnly,
    this.searchQuery,
  });

  MessageFilters copyWith({
    MessageType? messageType,
    DateTime? startDate,
    DateTime? endDate,
    bool? unreadOnly,
    String? searchQuery,
    bool clearType = false,
    bool clearDates = false,
    bool clearSearch = false,
  }) {
    return MessageFilters(
      messageType: clearType ? null : (messageType ?? this.messageType),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      unreadOnly: unreadOnly ?? this.unreadOnly,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }

  bool get hasActiveFilters =>
      messageType != null ||
      startDate != null ||
      endDate != null ||
      unreadOnly == true ||
      (searchQuery != null && searchQuery!.isNotEmpty);
}

/// Pagination info for messages list
@immutable
class MessagesPagination {
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  const MessagesPagination({
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.hasMore = false,
  });

  MessagesPagination copyWith({
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
  }) {
    return MessagesPagination(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
