import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notifications_providers.dart';

/// Bell icon button with a red unread count badge overlay.
/// Watches [unreadNotificationCountProvider] for real-time updates.
class NotificationBadge extends ConsumerWidget {
  final VoidCallback onTap;

  const NotificationBadge({required this.onTap, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unreadNotificationCountProvider);
    final count = countAsync.when(
      data: (c) => c,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return IconButton(
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(
          count > 99 ? '99+' : count.toString(),
          style: const TextStyle(fontSize: 10),
        ),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: onTap,
    );
  }
}
