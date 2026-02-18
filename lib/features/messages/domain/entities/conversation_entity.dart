// lib/features/messages/domain/entities/conversation_entity.dart

import 'package:flutter/foundation.dart';
import 'message_entity.dart';

/// Represents a conversation thread between admin and a user
@immutable
class ConversationEntity {
  final String id; // User ID of the other participant
  final MessageUserInfo participant;
  final MessageEntity? lastMessage;
  final int unreadCount;
  final DateTime lastMessageAt;
  final int totalMessages;

  const ConversationEntity({
    required this.id,
    required this.participant,
    this.lastMessage,
    this.unreadCount = 0,
    required this.lastMessageAt,
    this.totalMessages = 0,
  });

  /// Check if conversation has unread messages
  bool get hasUnread => unreadCount > 0;

  /// Get preview text from last message
  String get previewText => lastMessage?.previewText ?? 'No messages';

  /// Get last message subject if available
  String? get lastSubject => lastMessage?.subject;

  /// Copy with method for immutability
  ConversationEntity copyWith({
    String? id,
    MessageUserInfo? participant,
    MessageEntity? lastMessage,
    int? unreadCount,
    DateTime? lastMessageAt,
    int? totalMessages,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      participant: participant ?? this.participant,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      totalMessages: totalMessages ?? this.totalMessages,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Statistics for conversations
@immutable
class ConversationStats {
  final int totalConversations;
  final int totalUnread;
  final int totalBroadcastsSent;
  final int totalDirectMessagesSent;
  final int activeConversationsToday;

  const ConversationStats({
    this.totalConversations = 0,
    this.totalUnread = 0,
    this.totalBroadcastsSent = 0,
    this.totalDirectMessagesSent = 0,
    this.activeConversationsToday = 0,
  });

  factory ConversationStats.empty() => const ConversationStats();
}
