// lib/features/messages/presentation/screens/compose_message_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/messages_providers.dart';
import '../widgets/user_selector.dart';
import '../widgets/template_selector.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/message_template_entity.dart';

class ComposeMessageScreen extends ConsumerStatefulWidget {
  final MessageTemplateEntity? initialTemplate;
  final MessageUserInfo? initialRecipient;

  const ComposeMessageScreen({
    super.key,
    this.initialTemplate,
    this.initialRecipient,
  });

  @override
  ConsumerState<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends ConsumerState<ComposeMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  
  MessageUserInfo? _selectedRecipient;
  bool _sendPushNotification = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    
    // Apply initial template
    if (widget.initialTemplate != null) {
      _subjectController.text = widget.initialTemplate!.subject ?? '';
      _bodyController.text = widget.initialTemplate!.body;
    }
    
    // Apply initial recipient
    _selectedRecipient = widget.initialRecipient;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('New Message'),
        actions: [
          TextButton.icon(
            onPressed: _isSending || _selectedRecipient == null ? null : _send,
            icon: _isSending
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.send),
            label: const Text('Send'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Recipient selector
            _RecipientCard(
              recipient: _selectedRecipient,
              onSelect: () => _showUserSelector(context),
              onClear: () => setState(() => _selectedRecipient = null),
            ),
            const SizedBox(height: 16),

            // Subject field
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject (Optional)',
                prefixIcon: Icon(Icons.subject),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Message body
            TextFormField(
              controller: _bodyController,
              decoration: InputDecoration(
                labelText: 'Message',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(Icons.message),
                ),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.description_outlined),
                  tooltip: 'Use Template',
                  onPressed: () => _showTemplateSelector(context),
                ),
              ),
              maxLines: 8,
              minLines: 4,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a message';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Options
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Send Push Notification'),
                    subtitle: const Text('Notify user immediately'),
                    secondary: Icon(
                      _sendPushNotification
                          ? Icons.notifications_active
                          : Icons.notifications_off_outlined,
                    ),
                    value: _sendPushNotification,
                    onChanged: (value) {
                      setState(() => _sendPushNotification = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Send button (mobile-friendly)
            FilledButton.icon(
              onPressed: _isSending || _selectedRecipient == null ? null : _send,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: const Text('Send Message'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),

            // Preview section
            if (_selectedRecipient != null && _bodyController.text.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                'Preview',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'To: ${_selectedRecipient!.displayName}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (_subjectController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _subjectController.text,
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        _bodyController.text,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showUserSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => UserSelector(
          scrollController: scrollController,
          onSelect: (user) {
            Navigator.pop(context);
            setState(() => _selectedRecipient = user);
          },
        ),
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
            setState(() {
              _subjectController.text = template.subject ?? '';
              _bodyController.text = template.body;
            });
          },
        ),
      ),
    );
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRecipient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a recipient')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final repository = ref.read(messagesRepositoryProvider);
      final result = await repository.sendMessage(
        recipientId: _selectedRecipient!.id,
        body: _bodyController.text.trim(),
        subject: _subjectController.text.trim().isEmpty
            ? null
            : _subjectController.text.trim(),
        sendPushNotification: _sendPushNotification,
      );

      if (result.success && mounted) {
        // Refresh conversations list
        ref.read(conversationsNotifierProvider.notifier).fetchConversations(refresh: true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent successfully')),
        );
        
        // Navigate to conversation
        context.pushReplacement('/messages/conversation/${_selectedRecipient!.id}');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to send message'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}

// ============================================================================
// RECIPIENT CARD
// ============================================================================

class _RecipientCard extends StatelessWidget {
  final MessageUserInfo? recipient;
  final VoidCallback onSelect;
  final VoidCallback onClear;

  const _RecipientCard({
    required this.recipient,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (recipient == null) {
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.person_add),
          ),
          title: const Text('Select Recipient'),
          subtitle: const Text('Tap to choose a user'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onSelect,
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: recipient!.profilePhotoUrl != null
              ? NetworkImage(recipient!.profilePhotoUrl!)
              : null,
          child: recipient!.profilePhotoUrl == null
              ? Text(
                  recipient!.initials,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        title: Text(recipient!.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipient!.phone != null) Text(recipient!.phone!),
            if (recipient!.role != null)
              Text(
                recipient!.role!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Change recipient',
              onPressed: onSelect,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear',
              onPressed: onClear,
            ),
          ],
        ),
        isThreeLine: recipient!.phone != null && recipient!.role != null,
      ),
    );
  }
}
