// lib/features/messages/domain/repositories/messages_repository.dart

import '../entities/message_entity.dart';
import '../entities/conversation_entity.dart';
import '../entities/message_template_entity.dart';

/// Result types for repository operations

class ConversationsResult {
  final List<ConversationEntity> conversations;
  final MessagesPagination pagination;
  final ConversationStats stats;

  const ConversationsResult({
    required this.conversations,
    required this.pagination,
    required this.stats,
  });
}

class MessagesResult {
  final List<MessageEntity> messages;
  final MessagesPagination pagination;

  const MessagesResult({
    required this.messages,
    required this.pagination,
  });
}

class SendMessageResult {
  final bool success;
  final MessageEntity? message;
  final String? error;

  const SendMessageResult({
    required this.success,
    this.message,
    this.error,
  });

  factory SendMessageResult.success(MessageEntity message) =>
      SendMessageResult(success: true, message: message);

  factory SendMessageResult.failure(String error) =>
      SendMessageResult(success: false, error: error);
}

class BroadcastResult {
  final bool success;
  final int recipientCount;
  final String? broadcastId;
  final String? error;

  const BroadcastResult({
    required this.success,
    this.recipientCount = 0,
    this.broadcastId,
    this.error,
  });

  factory BroadcastResult.success({
    required int recipientCount,
    required String broadcastId,
  }) =>
      BroadcastResult(
        success: true,
        recipientCount: recipientCount,
        broadcastId: broadcastId,
      );

  factory BroadcastResult.failure(String error) =>
      BroadcastResult(success: false, error: error);
}

class TemplateResult {
  final bool success;
  final MessageTemplateEntity? template;
  final String? error;

  const TemplateResult({
    required this.success,
    this.template,
    this.error,
  });

  factory TemplateResult.success(MessageTemplateEntity template) =>
      TemplateResult(success: true, template: template);

  factory TemplateResult.failure(String error) =>
      TemplateResult(success: false, error: error);
}

/// Abstract repository interface for messages
abstract class MessagesRepository {
  /// Fetch list of conversations (grouped by user)
  Future<ConversationsResult> fetchConversations({
    MessagesPagination pagination = const MessagesPagination(),
    String? searchQuery,
  });

  /// Fetch messages in a conversation with a specific user
  Future<MessagesResult> fetchMessages({
    required String userId,
    MessagesPagination pagination = const MessagesPagination(),
  });

  /// Fetch broadcast history
  Future<MessagesResult> fetchBroadcasts({
    MessagesPagination pagination = const MessagesPagination(),
    MessageFilters? filters,
  });

  /// Send a direct message to a specific user
  Future<SendMessageResult> sendMessage({
    required String recipientId,
    required String body,
    String? subject,
    bool sendPushNotification,
  });

  /// Send a broadcast message to multiple users
  Future<BroadcastResult> sendBroadcast({
    required BroadcastAudience audience,
    required String body,
    String? subject,
    bool sendPushNotification,
    List<String>? specificUserIds,
  });

  /// Mark messages as read
  Future<bool> markAsRead({required List<String> messageIds});

  /// Mark all messages in a conversation as read
  Future<bool> markConversationAsRead({required String userId});

  /// Fetch message templates
  Future<List<MessageTemplateEntity>> fetchTemplates({
    TemplateCategory? category,
    bool activeOnly = true,
  });

  /// Create a new message template
  Future<TemplateResult> createTemplate({
    required String name,
    required String body,
    String? subject,
    TemplateCategory category = TemplateCategory.general,
  });

  /// Update an existing template
  Future<TemplateResult> updateTemplate({
    required String templateId,
    String? name,
    String? body,
    String? subject,
    TemplateCategory? category,
    bool? isActive,
  });

  /// Delete a template
  Future<bool> deleteTemplate({required String templateId});

  /// Increment template usage count
  Future<void> incrementTemplateUsage({required String templateId});

  /// Search users for recipient selection
  Future<List<MessageUserInfo>> searchUsers({
    required String query,
    String? role,
    int limit = 20,
  });

  /// Get unread message count
  Future<int> getUnreadCount();

  /// Get conversation stats
  Future<ConversationStats> getStats();
}
