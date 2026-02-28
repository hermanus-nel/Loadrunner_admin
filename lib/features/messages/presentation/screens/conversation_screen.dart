// lib/features/messages/presentation/screens/conversation_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/messages_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/template_selector.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/message_template_entity.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String userId;

  const ConversationScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _sendPushNotification = false;
  MessageUserInfo? _recipient;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationMessagesNotifierProvider.notifier)
          .fetchMessages(widget.userId);
      _loadRecipientInfo();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(conversationMessagesNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _loadRecipientInfo() async {
    // Get recipient info from the first message or search
    final state = ref.read(conversationMessagesNotifierProvider);
    if (state.messages.isNotEmpty && state.messages.first.recipient != null) {
      setState(() {
        _recipient = state.messages.first.recipient;
      });
    } else {
      // Search for user
      final repository = ref.read(messagesRepositoryProvider);
      final users = await repository.searchUsers(query: widget.userId, limit: 1);
      if (users.isNotEmpty && mounted) {
        setState(() {
          _recipient = users.first;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(conversationMessagesNotifierProvider);

    // Get recipient from messages if not already set
    if (_recipient == null && state.messages.isNotEmpty) {
      for (final message in state.messages) {
        if (message.recipient != null) {
          _recipient = message.recipient;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _buildAppBarTitle(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _buildMessagesList(context, state),
          ),

          // Input area
          _buildInputArea(context, state),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle(BuildContext context) {
    if (_recipient == null) {
      return const Text('Conversation');
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          backgroundImage: _recipient!.profilePhotoUrl != null
              ? CachedNetworkImageProvider(_recipient!.profilePhotoUrl!)
              : null,
          child: _recipient!.profilePhotoUrl == null
              ? Text(
                  _recipient!.initials,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _recipient!.displayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_recipient!.role != null)
                Text(
                  _recipient!.role!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesList(
    BuildContext context,
    ConversationMessagesState state,
  ) {
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('Error loading messages'),
            const SizedBox(height: 8),
            Text(state.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(conversationMessagesNotifierProvider.notifier)
                    .fetchMessages(widget.userId, refresh: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Send the first message',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Latest messages at bottom
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.messages.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final message = state.messages[index];
        final isFromAdmin = message.senderId != null;
        
        // Show date separator
        final showDate = index == state.messages.length - 1 ||
            !_isSameDay(
              message.sentAt,
              state.messages[index + 1].sentAt,
            );

        return Column(
          children: [
            if (showDate)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  _formatDate(message.sentAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
            MessageBubble(
              message: message,
              isFromAdmin: isFromAdmin,
              onLongPress: () => _showMessageOptions(context, message),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputArea(BuildContext context, ConversationMessagesState state) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Push notification toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    _sendPushNotification
                        ? Icons.notifications_active
                        : Icons.notifications_off_outlined,
                    size: 18,
                    color: _sendPushNotification
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Push notification',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _sendPushNotification,
                    onChanged: (value) {
                      setState(() => _sendPushNotification = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Template button
                IconButton(
                  icon: const Icon(Icons.description_outlined),
                  tooltip: 'Use Template',
                  onPressed: () => _showTemplateSelector(context),
                ),
                // Message input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                IconButton.filled(
                  icon: state.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  onPressed: state.isSending ? null : _sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_recipient != null)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View User Profile'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/users/${widget.userId}');
                },
              ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Messages'),
              onTap: () {
                Navigator.pop(context);
                ref.read(conversationMessagesNotifierProvider.notifier)
                    .fetchMessages(widget.userId, refresh: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('Copy User ID'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: widget.userId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User ID copied')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, MessageEntity message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('Copy Message'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.body));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Message Details'),
              onTap: () {
                Navigator.pop(context);
                _showMessageDetails(context, message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageDetails(BuildContext context, MessageEntity message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'ID', value: message.id),
            _DetailRow(label: 'Type', value: message.messageType.displayName),
            _DetailRow(
              label: 'Sent',
              value: _formatDateTime(message.sentAt),
            ),
            if (message.readAt != null)
              _DetailRow(
                label: 'Read',
                value: _formatDateTime(message.readAt!),
              ),
            _DetailRow(
              label: 'Push Sent',
              value: message.pushNotificationSent ? 'Yes' : 'No',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTemplateSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => TemplateSelector(
          scrollController: scrollController,
          onSelect: (template) {
            Navigator.pop(context);
            _messageController.text = template.body;
            _focusNode.requestFocus();
          },
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final result = await ref
        .read(conversationMessagesNotifierProvider.notifier)
        .sendMessage(
          body: text,
          sendPushNotification: _sendPushNotification,
        );

    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to send message'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      // Restore text
      _messageController.text = text;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (_isSameDay(dt, now)) return 'Today';
    if (_isSameDay(dt, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
