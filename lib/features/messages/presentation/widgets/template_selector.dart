// lib/features/messages/presentation/widgets/template_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/messages_providers.dart';
import '../../domain/entities/message_template_entity.dart';

class TemplateSelector extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Function(MessageTemplateEntity) onSelect;

  const TemplateSelector({
    super.key,
    required this.scrollController,
    required this.onSelect,
  });

  @override
  ConsumerState<TemplateSelector> createState() => _TemplateSelectorState();
}

class _TemplateSelectorState extends ConsumerState<TemplateSelector> {
  TemplateCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Fetch templates if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(templatesNotifierProvider.notifier).fetchTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesState = ref.watch(templatesNotifierProvider);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose a Template',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (_) {
                        setState(() => _selectedCategory = null);
                      },
                    ),
                    const SizedBox(width: 8),
                    ...TemplateCategory.values.map((category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category.displayName),
                            selected: _selectedCategory == category,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory =
                                    _selectedCategory == category ? null : category;
                              });
                            },
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(),

        // Templates list
        Expanded(
          child: _buildTemplatesList(context, templatesState),
        ),
      ],
    );
  }

  Widget _buildTemplatesList(BuildContext context, TemplatesState state) {
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(templatesNotifierProvider.notifier).fetchTemplates();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Filter by selected category
    final templates = _selectedCategory == null
        ? state.templates
        : state.templates.where((t) => t.category == _selectedCategory).toList();

    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No templates found',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory != null
                  ? 'Try a different category'
                  : 'Create a template to get started',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      itemCount: templates.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final template = templates[index];
        return _TemplateItem(
          template: template,
          onTap: () => widget.onSelect(template),
        );
      },
    );
  }
}

class _TemplateItem extends StatelessWidget {
  final MessageTemplateEntity template;
  final VoidCallback onTap;

  const _TemplateItem({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(template.category),
                    size: 20,
                    color: _getCategoryColor(template.category, theme),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      template.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(template.category, theme)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      template.category.displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getCategoryColor(template.category, theme),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Subject if present
              if (template.subject != null && template.subject!.isNotEmpty) ...[
                Text(
                  template.subject!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Preview text
              Text(
                template.previewText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Placeholders hint
              if (template.hasPlaceholders) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Contains placeholders: ${template.placeholders.join(", ")}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.general:
        return Icons.message;
      case TemplateCategory.documentRequest:
        return Icons.description;
      case TemplateCategory.verification:
        return Icons.verified_user;
      case TemplateCategory.payment:
        return Icons.payment;
      case TemplateCategory.warning:
        return Icons.warning;
      case TemplateCategory.support:
        return Icons.support_agent;
    }
  }

  Color _getCategoryColor(TemplateCategory category, ThemeData theme) {
    switch (category) {
      case TemplateCategory.general:
        return theme.colorScheme.primary;
      case TemplateCategory.documentRequest:
        return Colors.blue;
      case TemplateCategory.verification:
        return Colors.green;
      case TemplateCategory.payment:
        return Colors.orange;
      case TemplateCategory.warning:
        return Colors.red;
      case TemplateCategory.support:
        return Colors.purple;
    }
  }
}

/// Inline template preview for quick view
class TemplatePreviewCard extends StatelessWidget {
  final MessageTemplateEntity template;
  final VoidCallback? onUse;
  final VoidCallback? onEdit;

  const TemplatePreviewCard({
    super.key,
    required this.template,
    this.onUse,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.name,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    template.category.displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Subject
            if (template.subject != null) ...[
              Text(
                'Subject: ${template.subject}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Body
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                template.body,
                style: theme.textTheme.bodySmall,
              ),
            ),

            // Placeholders
            if (template.hasPlaceholders) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: template.placeholders.map((p) {
                  return Chip(
                    label: Text('{{$p}}'),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  );
                }).toList(),
              ),
            ],

            // Actions
            if (onUse != null || onEdit != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  if (onUse != null)
                    FilledButton.icon(
                      onPressed: onUse,
                      icon: const Icon(Icons.check),
                      label: const Text('Use Template'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
