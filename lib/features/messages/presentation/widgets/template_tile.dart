// lib/features/messages/presentation/widgets/template_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/message_template_entity.dart';

class TemplateTile extends StatelessWidget {
  final MessageTemplateEntity template;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TemplateTile({
    super.key,
    required this.template,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor(template.category, theme);

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
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(template.category),
                      size: 20,
                      color: categoryColor,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            template.category.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: categoryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (value == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 12),
                                Text('Edit'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: theme.colorScheme.error),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Subject if present
              if (template.subject != null && template.subject!.isNotEmpty) ...[
                Text(
                  'Subject: ${template.subject}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
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
              const SizedBox(height: 12),

              // Footer row
              Row(
                children: [
                  // Placeholders indicator
                  if (template.hasPlaceholders)
                    _InfoChip(
                      icon: Icons.data_object,
                      label: '${template.placeholders.length} placeholders',
                      color: theme.colorScheme.secondary,
                    ),

                  // Usage count
                  if (template.usageCount > 0) ...[
                    if (template.hasPlaceholders) const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.trending_up,
                      label: 'Used ${template.usageCount}x',
                      color: theme.colorScheme.tertiary,
                    ),
                  ],

                  const Spacer(),

                  // Status indicator
                  if (!template.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Inactive',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                ],
              ),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact template tile for smaller spaces
class TemplateTileCompact extends StatelessWidget {
  final MessageTemplateEntity template;
  final VoidCallback? onTap;

  const TemplateTileCompact({
    super.key,
    required this.template,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getCategoryColor(template.category, theme).withOpacity(0.1),
        child: Icon(
          _getCategoryIcon(template.category),
          color: _getCategoryColor(template.category, theme),
        ),
      ),
      title: Text(
        template.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        template.category.displayName,
        style: theme.textTheme.bodySmall,
      ),
      trailing: template.hasPlaceholders
          ? Chip(
              label: Text('${template.placeholders.length}'),
              avatar: const Icon(Icons.data_object, size: 16),
              visualDensity: VisualDensity.compact,
            )
          : null,
      onTap: onTap,
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

/// Empty state widget for templates
class TemplatesEmptyState extends StatelessWidget {
  final VoidCallback? onCreateTemplate;

  const TemplatesEmptyState({
    super.key,
    this.onCreateTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                size: 64,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No templates yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create message templates to save time when sending common messages',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (onCreateTemplate != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCreateTemplate,
                icon: const Icon(Icons.add),
                label: const Text('Create Template'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
