import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/admin_notification_entity.dart';
import '../providers/notifications_providers.dart';
import '../widgets/notification_tile.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_dimensions.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsListNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              ref
                  .read(notificationsListNotifierProvider.notifier)
                  .markAllAsRead();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Notification settings',
            onPressed: () {
              context.push(AppRoutes.notificationPreferences);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(context, state),

          // Notifications list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? _buildError(context, state.error!)
                    : state.notifications.isEmpty
                        ? _buildEmpty(context)
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(
                                  notificationsListNotifierProvider.notifier,
                                )
                                .refresh(),
                            child: ListView.separated(
                              controller: _scrollController,
                              itemCount: state.notifications.length +
                                  (state.isLoadingMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                if (index >= state.notifications.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        AppDimensions.spacingMd,
                                      ),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final notification =
                                    state.notifications[index];
                                return NotificationTile(
                                  notification: notification,
                                  onTap: () =>
                                      _onNotificationTap(notification),
                                  onDismissed: () {
                                    ref
                                        .read(
                                          notificationsListNotifierProvider
                                              .notifier,
                                        )
                                        .archiveNotification(notification.id);
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    NotificationsListState state,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingXs,
      ),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected:
                state.typeFilter == null && !state.unreadOnly,
            onSelected: (_) {
              ref
                  .read(notificationsListNotifierProvider.notifier)
                  .setTypeFilter(null);
              ref
                  .read(notificationsListNotifierProvider.notifier)
                  .setUnreadOnly(false);
            },
          ),
          const SizedBox(width: AppDimensions.spacingXs),
          FilterChip(
            label: const Text('Unread'),
            selected: state.unreadOnly,
            onSelected: (selected) {
              ref
                  .read(notificationsListNotifierProvider.notifier)
                  .setUnreadOnly(selected);
            },
          ),
          const SizedBox(width: AppDimensions.spacingXs),
          FilterChip(
            label: const Text('Disputes'),
            selected: state.typeFilter == AdminNotificationType.disputeFiled ||
                state.typeFilter == AdminNotificationType.disputeEscalated ||
                state.typeFilter == AdminNotificationType.disputeResolved,
            onSelected: (_) {
              // Cycle through dispute types or set to first
              ref
                  .read(notificationsListNotifierProvider.notifier)
                  .setTypeFilter(AdminNotificationType.disputeFiled);
            },
          ),
          const SizedBox(width: AppDimensions.spacingXs),
          FilterChip(
            label: const Text('Drivers'),
            selected: state.typeFilter ==
                    AdminNotificationType.driverPendingApproval ||
                state.typeFilter ==
                    AdminNotificationType.driverDocumentUploaded ||
                state.typeFilter == AdminNotificationType.driverSuspended,
            onSelected: (_) {
              ref
                  .read(notificationsListNotifierProvider.notifier)
                  .setTypeFilter(AdminNotificationType.driverPendingApproval);
            },
          ),
          const SizedBox(width: AppDimensions.spacingXs),
          FilterChip(
            label: const Text('Payments'),
            selected:
                state.typeFilter == AdminNotificationType.paymentFailed ||
                    state.typeFilter ==
                        AdminNotificationType.paymentRefundRequested,
            onSelected: (_) {
              ref
                  .read(notificationsListNotifierProvider.notifier)
                  .setTypeFilter(AdminNotificationType.paymentFailed);
            },
          ),
          const SizedBox(width: AppDimensions.spacingXs),
          FilterChip(
            label: const Text('System'),
            selected:
                state.typeFilter == AdminNotificationType.adminSystemAlert,
            onSelected: (_) {
              ref
                  .read(notificationsListNotifierProvider.notifier)
                  .setTypeFilter(AdminNotificationType.adminSystemAlert);
            },
          ),
        ],
      ),
    );
  }

  void _onNotificationTap(AdminNotificationEntity notification) {
    // Mark as read
    if (!notification.isRead) {
      ref
          .read(notificationsListNotifierProvider.notifier)
          .markAsRead(notification.id);
    }

    // Navigate based on type
    final type = notification.type;
    final relatedId = notification.relatedId;

    if (type == null || relatedId == null) return;

    switch (type) {
      case AdminNotificationType.disputeFiled:
      case AdminNotificationType.disputeEscalated:
      case AdminNotificationType.disputeResolved:
        context.push(AppRoutes.disputeDetailPath(relatedId));
      case AdminNotificationType.driverPendingApproval:
      case AdminNotificationType.driverDocumentUploaded:
      case AdminNotificationType.driverSuspended:
        context.push(AppRoutes.driverDetailPath(relatedId));
      case AdminNotificationType.paymentFailed:
      case AdminNotificationType.paymentRefundRequested:
        context.push(AppRoutes.transactionDetailPath(relatedId));
      case AdminNotificationType.adminSystemAlert:
        break; // No deep link for system alerts
    }
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: AppDimensions.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              'Failed to load notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.spacingXs),
            Text(error, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppDimensions.spacingMd),
            ElevatedButton(
              onPressed: () => ref
                  .read(notificationsListNotifierProvider.notifier)
                  .refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'No notifications',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            'You\'re all caught up!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
