import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_notification_entity.dart';
import '../../domain/entities/notification_category.dart';
import '../providers/notifications_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationPreferencesNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        centerTitle: true,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildError(context, ref, state.error!)
              : ListView(
                  padding: AppDimensions.pagePadding,
                  children: [
                    // Header
                    Text(
                      'Choose how you receive notifications for each event type.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),

                    // Build sections for each category
                    for (final category
                        in NotificationCategory.values) ...[
                      _buildCategorySection(
                        context,
                        ref,
                        category,
                        state,
                        isDark,
                      ),
                      const SizedBox(height: AppDimensions.spacingLg),
                    ],
                  ],
                ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    WidgetRef ref,
    NotificationCategory category,
    NotificationPreferencesState state,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    // Determine master toggle state
    final categoryPrefs = category.types
        .map((t) => state.preferenceFor(t))
        .toList();
    final allPushEnabled =
        categoryPrefs.every((p) => p?.pushEnabled ?? false);
    final allSmsEnabled =
        categoryPrefs.every((p) => p?.smsEnabled ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with master toggles
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.spacingXs,
            right: AppDimensions.spacingMd,
            bottom: AppDimensions.spacingXs,
          ),
          child: Row(
            children: [
              Text(
                category.displayName,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const Spacer(),
              // Master push toggle
              _MiniToggle(
                icon: Icons.notifications_active,
                isEnabled: allPushEnabled,
                onTap: () {
                  ref
                      .read(notificationPreferencesNotifierProvider.notifier)
                      .toggleCategory(
                        types: category.types,
                        pushEnabled: !allPushEnabled,
                      );
                },
              ),
              const SizedBox(width: AppDimensions.spacingXs),
              // Master SMS toggle
              _MiniToggle(
                icon: Icons.sms,
                isEnabled: allSmsEnabled,
                onTap: () {
                  ref
                      .read(notificationPreferencesNotifierProvider.notifier)
                      .toggleCategory(
                        types: category.types,
                        smsEnabled: !allSmsEnabled,
                      );
                },
              ),
            ],
          ),
        ),

        // Card with individual type rows
        Card(
          child: Column(
            children: [
              for (int i = 0; i < category.types.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                _buildTypeRow(
                  context,
                  ref,
                  category.types[i],
                  state,
                  isDark,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeRow(
    BuildContext context,
    WidgetRef ref,
    AdminNotificationType type,
    NotificationPreferencesState state,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final pref = state.preferenceFor(type);
    final pushEnabled = pref?.pushEnabled ?? false;
    final smsEnabled = pref?.smsEnabled ?? false;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingXs),
        decoration: BoxDecoration(
          color: type.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Icon(
          type.icon,
          size: AppDimensions.iconSm,
          color: type.color,
        ),
      ),
      title: Text(
        type.displayName,
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(
        NotificationCategory.descriptionFor(type),
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Push toggle
          _ChannelToggle(
            icon: Icons.notifications_active,
            isEnabled: pushEnabled,
            onChanged: (enabled) {
              ref
                  .read(notificationPreferencesNotifierProvider.notifier)
                  .updatePreference(
                    type: type,
                    pushEnabled: enabled,
                    smsEnabled: smsEnabled,
                  );
            },
          ),
          const SizedBox(width: AppDimensions.spacingXs),
          // SMS toggle
          _ChannelToggle(
            icon: Icons.sms,
            isEnabled: smsEnabled,
            onChanged: (enabled) {
              ref
                  .read(notificationPreferencesNotifierProvider.notifier)
                  .updatePreference(
                    type: type,
                    pushEnabled: pushEnabled,
                    smsEnabled: enabled,
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: AppDimensions.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              'Failed to load preferences',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            ElevatedButton(
              onPressed: () => ref
                  .read(notificationPreferencesNotifierProvider.notifier)
                  .loadPreferences(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small icon toggle button for channel headers (master toggle).
class _MiniToggle extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  const _MiniToggle({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isEnabled
              ? activeColor.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? activeColor : Colors.grey,
        ),
      ),
    );
  }
}

/// Toggle button for individual notification channel (push / SMS).
class _ChannelToggle extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _ChannelToggle({
    required this.icon,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return InkWell(
      onTap: () => onChanged(!isEnabled),
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isEnabled
              ? activeColor.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? activeColor : Colors.grey,
        ),
      ),
    );
  }
}
