import 'package:flutter/material.dart';

/// A section card for displaying key-value information
class InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<InfoItem> items;
  final Widget? trailing;
  final bool isLoading;
  final String? emptyMessage;

  const InfoSection({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    this.trailing,
    this.isLoading = false,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const Divider(height: 24),

            // Content
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (items.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    emptyMessage ?? 'No information available',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...items.map((item) => _buildInfoRow(context, item)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, InfoItem item) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          SizedBox(
            width: 120,
            child: Text(
              item.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Value
          Expanded(
            child: item.widget ??
                Text(
                  item.value ?? '-',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

/// Represents a single info item
class InfoItem {
  final String label;
  final String? value;
  final Widget? widget;

  const InfoItem({
    required this.label,
    this.value,
    this.widget,
  });
}
