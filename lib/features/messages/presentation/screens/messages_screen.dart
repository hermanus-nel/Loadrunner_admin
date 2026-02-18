// lib/features/messages/presentation/screens/messages_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/components/loading_state.dart';
import '../providers/messages_providers.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/broadcast_tile.dart';
import '../widgets/template_tile.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_template_entity.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationsNotifierProvider.notifier).fetchConversations();
      ref.read(broadcastsNotifierProvider.notifier).fetchBroadcasts();
      ref.read(templatesNotifierProvider.notifier).fetchTemplates();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conversationsState = ref.watch(conversationsNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Messages'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Inbox'),
                  if (conversationsState.stats.totalUnread > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${conversationsState.stats.totalUnread}',
                        style: TextStyle(
                          color: theme.colorScheme.onError,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Broadcasts'),
            const Tab(text: 'Templates'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Message',
            onPressed: () => _showNewMessageOptions(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InboxTab(searchController: _searchController),
          const _BroadcastsTab(),
          const _TemplatesTab(),
        ],
      ),
    );
  }

  void _showNewMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('New Direct Message'),
              subtitle: const Text('Send a message to a specific user'),
              onTap: () {
                Navigator.pop(context);
                context.push('/messages/compose');
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign),
              title: const Text('New Broadcast'),
              subtitle: const Text('Send a message to multiple users'),
              onTap: () {
                Navigator.pop(context);
                context.push('/messages/broadcast');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('New Template'),
              subtitle: const Text('Create a reusable message template'),
              onTap: () {
                Navigator.pop(context);
                _showCreateTemplateDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTemplateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateTemplateDialog(),
    );
  }
}

// ============================================================================
// INBOX TAB
// ============================================================================

class _InboxTab extends ConsumerWidget {
  final TextEditingController searchController;

  const _InboxTab({required this.searchController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationsNotifierProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search conversations...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        ref.read(conversationsNotifierProvider.notifier).clearSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: (value) {
              ref.read(conversationsNotifierProvider.notifier).search(value);
            },
          ),
        ),

        // Stats bar
        _StatsBar(stats: state.stats),

        // Conversations list
        Expanded(
          child: _buildConversationsList(context, ref, state),
        ),
      ],
    );
  }

  Widget _buildConversationsList(
    BuildContext context,
    WidgetRef ref,
    ConversationsState state,
  ) {
    if (state.isLoading && state.conversations.isEmpty) {
      return const ShimmerList(itemCount: 5, itemHeight: 72);
    }

    if (state.error != null && state.conversations.isEmpty) {
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
            Text(
              'Error loading conversations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(state.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(conversationsNotifierProvider.notifier).fetchConversations(refresh: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Start by sending a message to a user',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/messages/compose'),
              icon: const Icon(Icons.add),
              label: const Text('New Message'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(conversationsNotifierProvider.notifier).fetchConversations(refresh: true);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200) {
            ref.read(conversationsNotifierProvider.notifier).loadMore();
          }
          return false;
        },
        child: ListView.builder(
          itemCount: state.conversations.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.conversations.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final conversation = state.conversations[index];
            return ConversationTile(
              conversation: conversation,
              onTap: () {
                context.push('/messages/conversation/${conversation.id}');
              },
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// BROADCASTS TAB
// ============================================================================

class _BroadcastsTab extends ConsumerWidget {
  const _BroadcastsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(broadcastsNotifierProvider);

    if (state.isLoading && state.broadcasts.isEmpty) {
      return const ShimmerList(itemCount: 5, itemHeight: 80);
    }

    if (state.broadcasts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No broadcasts sent yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/messages/broadcast'),
              icon: const Icon(Icons.campaign),
              label: const Text('Send Broadcast'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(broadcastsNotifierProvider.notifier).fetchBroadcasts(refresh: true);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200) {
            ref.read(broadcastsNotifierProvider.notifier).loadMore();
          }
          return false;
        },
        child: ListView.builder(
          itemCount: state.broadcasts.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.broadcasts.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final broadcast = state.broadcasts[index];
            return BroadcastTile(
              message: broadcast,
              onTap: () {
                _showBroadcastDetails(context, broadcast);
              },
            );
          },
        ),
      ),
    );
  }

  void _showBroadcastDetails(BuildContext context, MessageEntity broadcast) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Broadcast Details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (broadcast.recipientRole != null)
                          Text(
                            'Audience: ${BroadcastAudience.fromString(broadcast.recipientRole!).displayName}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (broadcast.subject != null) ...[
                Text(
                  'Subject',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(broadcast.subject!),
                const SizedBox(height: 16),
              ],
              Text(
                'Message',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Text(broadcast.body),
              const SizedBox(height: 24),
              if (broadcast.recipientCount != null) ...[
                ListTile(
                  leading: const Icon(Icons.people),
                  title: Text('${broadcast.recipientCount} recipients'),
                  dense: true,
                ),
              ],
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text('Sent: ${_formatDateTime(broadcast.sentAt)}'),
                dense: true,
              ),
              if (broadcast.pushNotificationSent)
                const ListTile(
                  leading: Icon(Icons.notifications_active),
                  title: Text('Push notification sent'),
                  dense: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ============================================================================
// TEMPLATES TAB
// ============================================================================

class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(templatesNotifierProvider);

    return Column(
      children: [
        // Category filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: state.filterCategory == null,
                onSelected: (_) {
                  ref.read(templatesNotifierProvider.notifier).filterByCategory(null);
                },
              ),
              const SizedBox(width: 8),
              ...TemplateCategory.values.map((category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.displayName),
                      selected: state.filterCategory == category,
                      onSelected: (_) {
                        ref.read(templatesNotifierProvider.notifier).filterByCategory(
                              state.filterCategory == category ? null : category,
                            );
                      },
                    ),
                  )),
            ],
          ),
        ),

        // Templates list
        Expanded(
          child: _buildTemplatesList(context, ref, state),
        ),
      ],
    );
  }

  Widget _buildTemplatesList(
    BuildContext context,
    WidgetRef ref,
    TemplatesState state,
  ) {
    if (state.isLoading && state.templates.isEmpty) {
      return const ShimmerList(itemCount: 4, itemHeight: 80);
    }

    final templates = state.filteredTemplates;

    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No templates found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const _CreateTemplateDialog(),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Template'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(templatesNotifierProvider.notifier).fetchTemplates();
      },
      child: ListView.builder(
        itemCount: templates.length,
        padding: const EdgeInsets.only(bottom: 80),
        itemBuilder: (context, index) {
          final template = templates[index];
          return TemplateTile(
            template: template,
            onTap: () => _showTemplateOptions(context, ref, template),
            onEdit: () => _showEditTemplateDialog(context, ref, template),
            onDelete: () => _confirmDelete(context, ref, template),
          );
        },
      ),
    );
  }

  void _showTemplateOptions(
    BuildContext context,
    WidgetRef ref,
    MessageTemplateEntity template,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Use in New Message'),
              onTap: () {
                Navigator.pop(context);
                context.push('/messages/compose', extra: {'template': template});
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign),
              title: const Text('Use in Broadcast'),
              onTap: () {
                Navigator.pop(context);
                context.push('/messages/broadcast', extra: {'template': template});
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Template'),
              onTap: () {
                Navigator.pop(context);
                _showEditTemplateDialog(context, ref, template);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              title: Text(
                'Delete Template',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, ref, template);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTemplateDialog(
    BuildContext context,
    WidgetRef ref,
    MessageTemplateEntity template,
  ) {
    showDialog(
      context: context,
      builder: (context) => _CreateTemplateDialog(template: template),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MessageTemplateEntity template,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(templatesNotifierProvider.notifier).deleteTemplate(template.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Template deleted')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATS BAR
// ============================================================================

class _StatsBar extends StatelessWidget {
  final ConversationStats stats;

  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          _StatItem(
            icon: Icons.chat_bubble_outline,
            value: '${stats.totalConversations}',
            label: 'Conversations',
          ),
          const SizedBox(width: 24),
          _StatItem(
            icon: Icons.campaign_outlined,
            value: '${stats.totalBroadcastsSent}',
            label: 'Broadcasts',
          ),
          const SizedBox(width: 24),
          _StatItem(
            icon: Icons.today,
            value: '${stats.activeConversationsToday}',
            label: 'Today',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// CREATE/EDIT TEMPLATE DIALOG
// ============================================================================

class _CreateTemplateDialog extends ConsumerStatefulWidget {
  final MessageTemplateEntity? template;

  const _CreateTemplateDialog({this.template});

  @override
  ConsumerState<_CreateTemplateDialog> createState() => _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends ConsumerState<_CreateTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  TemplateCategory _selectedCategory = TemplateCategory.general;
  bool _isLoading = false;

  bool get isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameController.text = widget.template!.name;
      _subjectController.text = widget.template!.subject ?? '';
      _bodyController.text = widget.template!.body;
      _selectedCategory = widget.template!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Template' : 'Create Template'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Template Name',
                    hintText: 'e.g., Document Request',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TemplateCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: TemplateCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject (Optional)',
                    hintText: 'Message subject line',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Message Body',
                    hintText: 'Use {{placeholder}} for dynamic values',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a message';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Tip: Use {{user_name}}, {{document_type}}, etc. for placeholders',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(templatesNotifierProvider.notifier);
      
      if (isEditing) {
        await notifier.updateTemplate(
          templateId: widget.template!.id,
          name: _nameController.text,
          subject: _subjectController.text.isEmpty ? null : _subjectController.text,
          body: _bodyController.text,
          category: _selectedCategory,
        );
      } else {
        await notifier.createTemplate(
          name: _nameController.text,
          subject: _subjectController.text.isEmpty ? null : _subjectController.text,
          body: _bodyController.text,
          category: _selectedCategory,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Template updated' : 'Template created'),
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
        setState(() => _isLoading = false);
      }
    }
  }
}
