// lib/features/messages/presentation/screens/broadcast_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/messages_providers.dart';
import '../widgets/template_selector.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/message_template_entity.dart';

class BroadcastScreen extends ConsumerStatefulWidget {
  final MessageTemplateEntity? initialTemplate;

  const BroadcastScreen({
    super.key,
    this.initialTemplate,
  });

  @override
  ConsumerState<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends ConsumerState<BroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  
  BroadcastAudience _selectedAudience = BroadcastAudience.all;
  bool _sendPushNotification = true;
  bool _isSending = false;
  bool _showPreview = false;
  int? _estimatedRecipients;

  @override
  void initState() {
    super.initState();
    
    // Apply initial template
    if (widget.initialTemplate != null) {
      _subjectController.text = widget.initialTemplate!.subject ?? '';
      _bodyController.text = widget.initialTemplate!.body;
    }
    
    _estimateRecipients();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _estimateRecipients() async {
    // This would ideally call an API to get count
    // For now, we'll show a placeholder
    setState(() => _estimatedRecipients = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('New Broadcast'),
        actions: [
          if (_showPreview)
            TextButton.icon(
              onPressed: () => setState(() => _showPreview = false),
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            )
          else
            TextButton.icon(
              onPressed: _bodyController.text.isNotEmpty
                  ? () => setState(() => _showPreview = true)
                  : null,
              icon: const Icon(Icons.preview),
              label: const Text('Preview'),
            ),
        ],
      ),
      body: _showPreview ? _buildPreview(context) : _buildForm(context),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Warning banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.campaign,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Broadcasts are sent to all users in the selected audience. Use carefully.',
                    style: TextStyle(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Audience selector
          Text(
            'Target Audience',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: BroadcastAudience.values.map((audience) {
                return RadioListTile<BroadcastAudience>(
                  title: Text(audience.displayName),
                  subtitle: Text(_getAudienceDescription(audience)),
                  value: audience,
                  groupValue: _selectedAudience,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedAudience = value);
                      _estimateRecipients();
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

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
                padding: EdgeInsets.only(bottom: 100),
                child: Icon(Icons.message),
              ),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.description_outlined),
                tooltip: 'Use Template',
                onPressed: () => _showTemplateSelector(context),
              ),
            ),
            maxLines: 10,
            minLines: 5,
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
                  subtitle: const Text('Notify all recipients immediately'),
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
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Preview header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.campaign,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Broadcast Preview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'This is how your message will appear to recipients.',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Audience info
        Card(
          child: ListTile(
            leading: const Icon(Icons.people),
            title: Text(_selectedAudience.displayName),
            subtitle: Text(_getAudienceDescription(_selectedAudience)),
            trailing: _estimatedRecipients != null
                ? Chip(
                    label: Text('~$_estimatedRecipients users'),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),

        // Message preview
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LoadRunner Admin',
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            'Just now',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_sendPushNotification)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_active,
                              size: 14,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Push',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const Divider(height: 24),
                if (_subjectController.text.isNotEmpty) ...[
                  Text(
                    _subjectController.text,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  _bodyController.text,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Confirmation checklist
        Text(
          'Before sending, please confirm:',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _ConfirmItem(
                icon: Icons.check_circle,
                text: 'Message content is accurate and appropriate',
              ),
              _ConfirmItem(
                icon: Icons.people,
                text: 'Target audience is correct: ${_selectedAudience.displayName}',
              ),
              _ConfirmItem(
                icon: _sendPushNotification ? Icons.notifications : Icons.notifications_off,
                text: _sendPushNotification
                    ? 'Push notification will be sent'
                    : 'No push notification',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target: ${_selectedAudience.displayName}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_estimatedRecipients != null)
                    Text(
                      'Approximately $_estimatedRecipients recipients',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: _isSending ? null : _confirmAndSend,
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
              label: Text(_showPreview ? 'Send Broadcast' : 'Preview & Send'),
            ),
          ],
        ),
      ),
    );
  }

  String _getAudienceDescription(BroadcastAudience audience) {
    switch (audience) {
      case BroadcastAudience.all:
        return 'All drivers and shippers on the platform';
      case BroadcastAudience.drivers:
        return 'All registered drivers';
      case BroadcastAudience.shippers:
        return 'All registered shippers';
      case BroadcastAudience.verifiedDrivers:
        return 'Only drivers with verified accounts';
      case BroadcastAudience.unverifiedDrivers:
        return 'Drivers awaiting verification';
    }
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

  void _confirmAndSend() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _showPreview = false);
      return;
    }

    if (!_showPreview) {
      setState(() => _showPreview = true);
      return;
    }

    // Show final confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Broadcast'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to send this broadcast?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16),
                      const SizedBox(width: 8),
                      Text(_selectedAudience.displayName),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _sendPushNotification
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(_sendPushNotification
                          ? 'Push notification ON'
                          : 'Push notification OFF'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _send();
            },
            child: const Text('Send Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    setState(() => _isSending = true);

    try {
      final notifier = ref.read(broadcastsNotifierProvider.notifier);
      final result = await notifier.sendBroadcast(
        audience: _selectedAudience,
        body: _bodyController.text.trim(),
        subject: _subjectController.text.trim().isEmpty
            ? null
            : _subjectController.text.trim(),
        sendPushNotification: _sendPushNotification,
      );

      if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Broadcast sent to ${result.recipientCount} recipients',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to send broadcast'),
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
// HELPER WIDGETS
// ============================================================================

class _ConfirmItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ConfirmItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(text),
      dense: true,
    );
  }
}
