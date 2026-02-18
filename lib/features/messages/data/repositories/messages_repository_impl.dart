// lib/features/messages/data/repositories/messages_repository_impl.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/message_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_template_entity.dart';
import '../../domain/repositories/messages_repository.dart';
import '../../../../core/services/jwt_recovery_handler.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/services/supabase_provider.dart';

class MessagesRepositoryImpl implements MessagesRepository {
  final JwtRecoveryHandler _jwtHandler;
  final SupabaseProvider _supabaseProvider;
  final SessionService _sessionService;

  MessagesRepositoryImpl({
    required JwtRecoveryHandler jwtHandler,
    required SupabaseProvider supabaseProvider,
    required SessionService sessionService,
  })  : _jwtHandler = jwtHandler,
        _supabaseProvider = supabaseProvider,
        _sessionService = sessionService;

  SupabaseClient get _supabase => _supabaseProvider.client;

  String? get _adminId => _sessionService.userId;

  @override
  Future<ConversationsResult> fetchConversations({
    MessagesPagination pagination = const MessagesPagination(),
    String? searchQuery,
  }) async {
    try {
      // Fetch conversations with last message grouped by recipient
      // Using a query to get unique conversations with latest message
      final offset = (pagination.page - 1) * pagination.pageSize;

      final result = await _jwtHandler.executeWithRecovery(
() async {
          // Get distinct users we've messaged
          var query = _supabase
              .from('admin_messages')
              .select('''
                recipient_id,
                recipient:recipient_id(
                  id, first_name, last_name, phone_number, email, role, profile_photo_url
                )
              ''')
              .not('recipient_id', 'is', null)
              .order('sent_at', ascending: false);

          final data = await query;
          return data as List<dynamic>;
        },
'fetch conversations',
      );

      // Group by recipient and get unique conversations
      final Map<String, dynamic> uniqueConversations = {};
      for (final row in result) {
        final recipientId = row['recipient_id'] as String?;
        if (recipientId != null && !uniqueConversations.containsKey(recipientId)) {
          uniqueConversations[recipientId] = row;
        }
      }

      // Apply search filter if provided
      var filteredConversations = uniqueConversations.values.toList();
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        filteredConversations = filteredConversations.where((conv) {
          final recipient = conv['recipient'] as Map<String, dynamic>?;
          if (recipient == null) return false;
          final firstName = (recipient['first_name'] as String?)?.toLowerCase() ?? '';
          final lastName = (recipient['last_name'] as String?)?.toLowerCase() ?? '';
          final phone = (recipient['phone_number'] as String?)?.toLowerCase() ?? '';
          return firstName.contains(query) ||
              lastName.contains(query) ||
              phone.contains(query);
        }).toList();
      }

      final totalCount = filteredConversations.length;

      // Apply pagination
      final paginatedConversations = filteredConversations
          .skip(offset)
          .take(pagination.pageSize)
          .toList();

      // Batch fetch last messages and unread counts for all conversations
      final recipientIds = paginatedConversations
          .map((conv) => conv['recipient_id'] as String)
          .where((id) => paginatedConversations
              .firstWhere((c) => c['recipient_id'] == id)['recipient'] != null)
          .toList();

      // Batch: get latest messages for all recipients in one query
      final allMessagesResult = await _jwtHandler.executeWithRecovery(
        () => _supabase
            .from('admin_messages')
            .select('id, recipient_id, sent_by, subject, body, message_type, sent_at, read_at, push_notification_sent, metadata, recipient_role')
            .inFilter('recipient_id', recipientIds)
            .order('sent_at', ascending: false),
        'fetch messages for conversations batch',
      );

      // Group messages by recipient and extract last message + unread count
      final Map<String, Map<String, dynamic>> lastMessages = {};
      final Map<String, int> unreadCounts = {};
      for (final msg in allMessagesResult as List) {
        final rid = msg['recipient_id'] as String;
        // Track first (latest) message per recipient
        if (!lastMessages.containsKey(rid)) {
          lastMessages[rid] = msg as Map<String, dynamic>;
        }
        // Count unread
        if (msg['read_at'] == null) {
          unreadCounts[rid] = (unreadCounts[rid] ?? 0) + 1;
        }
      }

      final List<ConversationEntity> conversations = [];
      for (final conv in paginatedConversations) {
        final recipientId = conv['recipient_id'] as String;
        final recipientData = conv['recipient'] as Map<String, dynamic>?;
        if (recipientData == null) continue;

        final participant = MessageUserInfo.fromJson(recipientData);
        MessageEntity? lastMessage;

        final lastMsgData = lastMessages[recipientId];
        if (lastMsgData != null) {
          lastMessage = _mapToMessageEntity(lastMsgData);
        }

        conversations.add(ConversationEntity(
          id: recipientId,
          participant: participant,
          lastMessage: lastMessage,
          unreadCount: unreadCounts[recipientId] ?? 0,
          lastMessageAt: lastMessage?.sentAt ?? DateTime.now(),
          totalMessages: 0,
        ));
      }

      // Sort by last message date
      conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

      // Get stats
      final stats = await getStats();

      return ConversationsResult(
        conversations: conversations,
        pagination: pagination.copyWith(
          totalCount: totalCount,
          hasMore: offset + paginatedConversations.length < totalCount,
        ),
        stats: stats,
      );
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      rethrow;
    }
  }

  @override
  Future<MessagesResult> fetchMessages({
    required String userId,
    MessagesPagination pagination = const MessagesPagination(),
  }) async {
    try {
      final offset = (pagination.page - 1) * pagination.pageSize;

      final result = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('admin_messages')
            .select('''
              *,
              recipient:recipient_id(
                id, first_name, last_name, phone_number, email, role, profile_photo_url
              )
            ''')
            .eq('recipient_id', userId)
            .eq('message_type', 'direct')
            .order('sent_at', ascending: false)
            .range(offset, offset + pagination.pageSize - 1),
'fetch messages for user $userId',
      );

      // Get total count
      final countResult = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('admin_messages')
            .select('id')
            .eq('recipient_id', userId)
            .eq('message_type', 'direct'),
'count messages for user $userId',
      );

      final data = result as List<dynamic>;
      final totalCount = (countResult as List).length;

      final messages = data.map((json) => _mapToMessageEntity(json as Map<String, dynamic>)).toList();

      return MessagesResult(
        messages: messages,
        pagination: pagination.copyWith(
          totalCount: totalCount,
          hasMore: offset + data.length < totalCount,
        ),
      );
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      rethrow;
    }
  }

  @override
  Future<MessagesResult> fetchBroadcasts({
    MessagesPagination pagination = const MessagesPagination(),
    MessageFilters? filters,
  }) async {
    try {
      final offset = (pagination.page - 1) * pagination.pageSize;

      var query = _supabase
          .from('admin_messages')
          .select('id, sent_by, recipient_id, message_type, recipient_role, subject, body, sent_at, read_at, push_notification_sent, metadata')
          .eq('message_type', 'broadcast');

      // Apply filters
      if (filters?.startDate != null) {
        query = query.gte('sent_at', filters!.startDate!.toIso8601String());
      }
      if (filters?.endDate != null) {
        query = query.lte('sent_at', filters!.endDate!.toIso8601String());
      }
      if (filters?.searchQuery != null && filters!.searchQuery!.isNotEmpty) {
        query = query.or('subject.ilike.%${filters.searchQuery}%,body.ilike.%${filters.searchQuery}%');
      }

      final result = await _jwtHandler.executeWithRecovery(
() => query
            .order('sent_at', ascending: false)
            .range(offset, offset + pagination.pageSize - 1),
'fetch broadcasts',
      );

      // Get total count
      var countQuery = _supabase
          .from('admin_messages')
          .select('id')
          .eq('message_type', 'broadcast');

      final countResult = await _jwtHandler.executeWithRecovery(
() => countQuery,
'count broadcasts',
      );

      final data = result as List<dynamic>;
      final totalCount = (countResult as List).length;

      final messages = data.map((json) => _mapToMessageEntity(json as Map<String, dynamic>)).toList();

      return MessagesResult(
        messages: messages,
        pagination: pagination.copyWith(
          totalCount: totalCount,
          hasMore: offset + data.length < totalCount,
        ),
      );
    } catch (e) {
      debugPrint('Error fetching broadcasts: $e');
      rethrow;
    }
  }

  @override
  Future<SendMessageResult> sendMessage({
    required String recipientId,
    required String body,
    String? subject,
    bool sendPushNotification = false,
  }) async {
    try {
      final adminId = _adminId;
      if (adminId == null) {
        return SendMessageResult.failure('Not authenticated');
      }

      final result = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('admin_messages')
            .insert({
              'sent_by': adminId,
              'recipient_id': recipientId,
              'message_type': 'direct',
              'subject': subject,
              'body': body,
              'push_notification_sent': sendPushNotification,
              'metadata': {},
            })
            .select('''
              *,
              recipient:recipient_id(
                id, first_name, last_name, phone_number, email, role, profile_photo_url
              )
            ''')
            .single(),
'send message to $recipientId',
      );

      // Log audit
      await _logAudit(
        action: 'message_sent',
        targetType: 'user',
        targetId: recipientId,
        newValues: {'subject': subject, 'body_preview': body.substring(0, body.length.clamp(0, 100))},
      );

      final message = _mapToMessageEntity(result);
      return SendMessageResult.success(message);
    } catch (e) {
      debugPrint('Error sending message: $e');
      return SendMessageResult.failure(e.toString());
    }
  }

  @override
  Future<BroadcastResult> sendBroadcast({
    required BroadcastAudience audience,
    required String body,
    String? subject,
    bool sendPushNotification = false,
    List<String>? specificUserIds,
  }) async {
    try {
      final adminId = _adminId;
      if (adminId == null) {
        return BroadcastResult.failure('Not authenticated');
      }

      // Determine target users based on audience
      List<String> targetUserIds;
      
      if (specificUserIds != null && specificUserIds.isNotEmpty) {
        targetUserIds = specificUserIds;
      } else {
        targetUserIds = await _getUserIdsForAudience(audience);
      }

      if (targetUserIds.isEmpty) {
        return BroadcastResult.failure('No users found for the selected audience');
      }

      // Create broadcast record (single message for audit)
      final broadcastResult = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('admin_messages')
            .insert({
              'sent_by': adminId,
              'recipient_id': null, // null for broadcasts
              'message_type': 'broadcast',
              'recipient_role': audience.toJson(),
              'subject': subject,
              'body': body,
              'push_notification_sent': sendPushNotification,
              'metadata': {
                'recipient_count': targetUserIds.length,
                'audience': audience.toJson(),
              },
            })
            .select()
            .single(),
'create broadcast record',
      );

      final broadcastId = broadcastResult['id'] as String;

      // Create individual messages for each recipient
      // (In a real app, this might be done via a background job)
      final messages = targetUserIds.map((userId) => {
        'sent_by': adminId,
        'recipient_id': userId,
        'message_type': 'broadcast',
        'subject': subject,
        'body': body,
        'push_notification_sent': sendPushNotification,
        'metadata': {'broadcast_id': broadcastId},
      }).toList();

      // Insert in batches of 100
      for (var i = 0; i < messages.length; i += 100) {
        final batch = messages.skip(i).take(100).toList();
        await _jwtHandler.executeWithRecovery(
  () => _supabase.from('admin_messages').insert(batch),
  'insert broadcast batch ${i ~/ 100 + 1}',
        );
      }

      // Log audit
      await _logAudit(
        action: 'broadcast_sent',
        targetType: 'broadcast',
        targetId: broadcastId,
        newValues: {
          'audience': audience.toJson(),
          'recipient_count': targetUserIds.length,
          'subject': subject,
        },
      );

      return BroadcastResult.success(
        recipientCount: targetUserIds.length,
        broadcastId: broadcastId,
      );
    } catch (e) {
      debugPrint('Error sending broadcast: $e');
      return BroadcastResult.failure(e.toString());
    }
  }

  Future<List<String>> _getUserIdsForAudience(BroadcastAudience audience) async {
    try {
      var query = _supabase.from('users').select('id');

      switch (audience) {
        case BroadcastAudience.all:
          // No filter needed
          break;
        case BroadcastAudience.drivers:
          query = query.eq('role', 'Driver');
          break;
        case BroadcastAudience.shippers:
          query = query.eq('role', 'Shipper');
          break;
        case BroadcastAudience.verifiedDrivers:
          query = query.eq('role', 'Driver').not('driver_verified_at', 'is', null);
          break;
        case BroadcastAudience.unverifiedDrivers:
          query = query.eq('role', 'Driver').isFilter('driver_verified_at', null);
          break;
      }

      final result = await _jwtHandler.executeWithRecovery(
() => query,
'get users for audience ${audience.name}',
      );

      return (result as List).map((r) => r['id'] as String).toList();
    } catch (e) {
      debugPrint('Error getting users for audience: $e');
      return [];
    }
  }

  @override
  Future<bool> markAsRead({required List<String> messageIds}) async {
    try {
      await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('admin_messages')
            .update({'read_at': DateTime.now().toIso8601String()})
            .inFilter('id', messageIds),
'mark messages as read',
      );
      return true;
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      return false;
    }
  }

  @override
  Future<bool> markConversationAsRead({required String userId}) async {
    try {
      await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('admin_messages')
            .update({'read_at': DateTime.now().toIso8601String()})
            .eq('recipient_id', userId)
            .isFilter('read_at', null),
'mark conversation as read for $userId',
      );
      return true;
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
      return false;
    }
  }

  @override
  Future<List<MessageTemplateEntity>> fetchTemplates({
    TemplateCategory? category,
    bool activeOnly = true,
  }) async {
    try {
      var query = _supabase.from('message_templates').select('id, name, subject, body, category, is_active, usage_count, created_at, updated_at, created_by');

      if (category != null) {
        query = query.eq('category', category.toJson());
      }
      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final result = await _jwtHandler.executeWithRecovery(
() => query.order('name'),
'fetch templates',
      );

      final data = result as List<dynamic>;
      return data.map((json) => _mapToTemplateEntity(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching templates: $e');
      // Return default templates if table doesn't exist
      return _getDefaultTemplates();
    }
  }

  @override
  Future<TemplateResult> createTemplate({
    required String name,
    required String body,
    String? subject,
    TemplateCategory category = TemplateCategory.general,
  }) async {
    try {
      final adminId = _adminId;

      final result = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('message_templates')
            .insert({
              'name': name,
              'subject': subject,
              'body': body,
              'category': category.toJson(),
              'is_active': true,
              'usage_count': 0,
              'created_by': adminId,
            })
            .select()
            .single(),
'create template',
      );

      final template = _mapToTemplateEntity(result);
      return TemplateResult.success(template);
    } catch (e) {
      debugPrint('Error creating template: $e');
      return TemplateResult.failure(e.toString());
    }
  }

  @override
  Future<TemplateResult> updateTemplate({
    required String templateId,
    String? name,
    String? body,
    String? subject,
    TemplateCategory? category,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (name != null) updates['name'] = name;
      if (body != null) updates['body'] = body;
      if (subject != null) updates['subject'] = subject;
      if (category != null) updates['category'] = category.toJson();
      if (isActive != null) updates['is_active'] = isActive;

      final result = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('message_templates')
            .update(updates)
            .eq('id', templateId)
            .select()
            .single(),
'update template $templateId',
      );

      final template = _mapToTemplateEntity(result);
      return TemplateResult.success(template);
    } catch (e) {
      debugPrint('Error updating template: $e');
      return TemplateResult.failure(e.toString());
    }
  }

  @override
  Future<bool> deleteTemplate({required String templateId}) async {
    try {
      await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('message_templates')
            .delete()
            .eq('id', templateId),
'delete template $templateId',
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting template: $e');
      return false;
    }
  }

  @override
  Future<void> incrementTemplateUsage({required String templateId}) async {
    try {
      await _jwtHandler.executeWithRecovery(
() => _supabase.rpc('increment_template_usage', params: {
          'template_id': templateId,
        }),
'increment template usage $templateId',
      );
    } catch (e) {
      // Non-critical, just log
      debugPrint('Error incrementing template usage: $e');
    }
  }

  @override
  Future<List<MessageUserInfo>> searchUsers({
    required String query,
    String? role,
    int limit = 20,
  }) async {
    try {
      var dbQuery = _supabase
          .from('users')
          .select('id, first_name, last_name, phone_number, email, role, profile_photo_url')
          .or('first_name.ilike.%$query%,last_name.ilike.%$query%,phone_number.ilike.%$query%,email.ilike.%$query%');

      if (role != null) {
        dbQuery = dbQuery.eq('role', role);
      }

      final result = await _jwtHandler.executeWithRecovery(
() => dbQuery.limit(limit),
'search users',
      );

      final data = result as List<dynamic>;
      return data.map((json) => MessageUserInfo.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final result = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('admin_messages')
            .select('id')
            .isFilter('read_at', null),
'get unread count',
      );
      return (result as List).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  @override
  Future<ConversationStats> getStats() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Run all stats queries in parallel for better performance
      final results = await Future.wait([
        // 0: Get unique recipients for conversation count
        _jwtHandler.executeWithRecovery(
          () => _supabase
              .from('admin_messages')
              .select('recipient_id')
              .not('recipient_id', 'is', null)
              .eq('message_type', 'direct'),
          'get conversation count',
        ),
        // 1: Get unread count
        _jwtHandler.executeWithRecovery(
          () => _supabase
              .from('admin_messages')
              .select('id')
              .isFilter('read_at', null),
          'get unread count',
        ),
        // 2: Get broadcasts count
        _jwtHandler.executeWithRecovery(
          () => _supabase
              .from('admin_messages')
              .select('id')
              .eq('message_type', 'broadcast')
              .isFilter('recipient_id', null),
          'get broadcasts count',
        ),
        // 3: Get direct messages count
        _jwtHandler.executeWithRecovery(
          () => _supabase
              .from('admin_messages')
              .select('id')
              .eq('message_type', 'direct'),
          'get direct messages count',
        ),
        // 4: Get today's active conversations
        _jwtHandler.executeWithRecovery(
          () => _supabase
              .from('admin_messages')
              .select('recipient_id')
              .gte('sent_at', startOfDay.toIso8601String())
              .not('recipient_id', 'is', null),
          'get today conversations',
        ),
      ]);

      final uniqueRecipients = (results[0] as List)
          .map((r) => r['recipient_id'])
          .toSet()
          .length;

      final todayUnique = (results[4] as List)
          .map((r) => r['recipient_id'])
          .toSet()
          .length;

      return ConversationStats(
        totalConversations: uniqueRecipients,
        totalUnread: (results[1] as List).length,
        totalBroadcastsSent: (results[2] as List).length,
        totalDirectMessagesSent: (results[3] as List).length,
        activeConversationsToday: todayUnique,
      );
    } catch (e) {
      debugPrint('Error getting stats: $e');
      return ConversationStats.empty();
    }
  }

  // Helper methods

  MessageEntity _mapToMessageEntity(Map<String, dynamic> json) {
    MessageUserInfo? recipient;
    if (json['recipient'] != null) {
      recipient = MessageUserInfo.fromJson(json['recipient'] as Map<String, dynamic>);
    }

    return MessageEntity(
      id: json['id'] as String,
      senderId: json['sent_by'] as String?,
      recipientId: json['recipient_id'] as String?,
      messageType: MessageType.fromString(json['message_type'] as String? ?? 'direct'),
      subject: json['subject'] as String?,
      body: json['body'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      pushNotificationSent: json['push_notification_sent'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      recipientRole: json['recipient_role'] as String?,
      recipient: recipient,
      recipientCount: (json['metadata'] as Map<String, dynamic>?)?['recipient_count'] as int?,
    );
  }

  MessageTemplateEntity _mapToTemplateEntity(Map<String, dynamic> json) {
    return MessageTemplateEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      subject: json['subject'] as String?,
      body: json['body'] as String,
      category: TemplateCategory.fromString(json['category'] as String? ?? 'general'),
      isActive: json['is_active'] as bool? ?? true,
      usageCount: json['usage_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
    );
  }

  List<MessageTemplateEntity> _getDefaultTemplates() {
    return DefaultTemplates.templates.asMap().entries.map((entry) {
      return MessageTemplateEntity(
        id: 'default_${entry.key}',
        name: entry.value['name'] as String,
        subject: entry.value['subject'] as String?,
        body: entry.value['body'] as String,
        category: TemplateCategory.fromString(entry.value['category'] as String),
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  Future<void> _logAudit({
    required String action,
    required String targetType,
    String? targetId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    try {
      final adminId = _adminId;
      await _supabase.from('admin_audit_logs').insert({
        'admin_id': adminId,
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'old_values': oldValues,
        'new_values': newValues,
      });
    } catch (e) {
      debugPrint('Error logging audit: $e');
    }
  }
}
