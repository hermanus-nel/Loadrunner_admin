// lib/core/components/empty_state.dart

import 'package:flutter/material.dart';

/// Generic empty state widget for lists and screens
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool compact;
  final Color? iconColor;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.compact = false,
    this.iconColor,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return _buildCompact(theme);
    }

    return _buildFull(theme);
  }

  Widget _buildCompact(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: iconColor ?? theme.colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            action!,
          ],
        ],
      ),
    );
  }

  Widget _buildFull(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconSize + 32,
              height: iconSize + 32,
              decoration: BoxDecoration(
                color: (iconColor ?? theme.colorScheme.outline).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ?? theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // Factory Constructors for Common Scenarios
  // ============================================================================

  /// Empty state for drivers list
  factory EmptyState.noDrivers({
    VoidCallback? onAddDriver,
    bool hasFilters = false,
    VoidCallback? onClearFilters,
  }) {
    return EmptyState(
      icon: Icons.local_shipping_outlined,
      title: hasFilters ? 'No drivers match your filters' : 'No drivers yet',
      message: hasFilters
          ? 'Try adjusting your filters to see more results.'
          : 'Drivers will appear here once they register.',
      action: hasFilters && onClearFilters != null
          ? TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear Filters'),
            )
          : onAddDriver != null
              ? FilledButton.icon(
                  onPressed: onAddDriver,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Driver'),
                )
              : null,
    );
  }

  /// Empty state for shippers list
  factory EmptyState.noShippers({
    bool hasFilters = false,
    VoidCallback? onClearFilters,
  }) {
    return EmptyState(
      icon: Icons.people_outline,
      title: hasFilters ? 'No shippers match your filters' : 'No shippers yet',
      message: hasFilters
          ? 'Try adjusting your filters to see more results.'
          : 'Shippers will appear here once they register.',
      action: hasFilters && onClearFilters != null
          ? TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear Filters'),
            )
          : null,
    );
  }

  /// Empty state for vehicles list
  factory EmptyState.noVehicles({
    bool hasFilters = false,
    VoidCallback? onClearFilters,
  }) {
    return EmptyState(
      icon: Icons.directions_car_outlined,
      title: hasFilters ? 'No vehicles match your filters' : 'No vehicles',
      message: hasFilters
          ? 'Try adjusting your filters to see more results.'
          : 'Vehicles will appear here when drivers add them.',
      action: hasFilters && onClearFilters != null
          ? TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear Filters'),
            )
          : null,
    );
  }

  /// Empty state for payments/transactions list
  factory EmptyState.noPayments({
    bool hasFilters = false,
    VoidCallback? onClearFilters,
  }) {
    return EmptyState(
      icon: Icons.payment_outlined,
      title: hasFilters ? 'No payments match your filters' : 'No payments yet',
      message: hasFilters
          ? 'Try adjusting your filters to see more results.'
          : 'Payments will appear here once transactions occur.',
      action: hasFilters && onClearFilters != null
          ? TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear Filters'),
            )
          : null,
    );
  }

  /// Empty state for disputes list
  factory EmptyState.noDisputes({
    bool hasFilters = false,
    VoidCallback? onClearFilters,
  }) {
    return EmptyState(
      icon: Icons.gavel_outlined,
      title: hasFilters ? 'No disputes match your filters' : 'No disputes',
      message: hasFilters
          ? 'Try adjusting your filters to see more results.'
          : 'Great news! There are no disputes to resolve.',
      iconColor: hasFilters ? null : Colors.green,
      action: hasFilters && onClearFilters != null
          ? TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear Filters'),
            )
          : null,
    );
  }

  /// Empty state for messages/conversations list
  factory EmptyState.noMessages({
    VoidCallback? onCompose,
    bool hasFilters = false,
    VoidCallback? onClearFilters,
  }) {
    return EmptyState(
      icon: Icons.chat_bubble_outline,
      title: hasFilters ? 'No messages match your search' : 'No messages yet',
      message: hasFilters
          ? 'Try adjusting your search to see more results.'
          : 'Start a conversation with users.',
      action: hasFilters && onClearFilters != null
          ? TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear Search'),
            )
          : onCompose != null
              ? FilledButton.icon(
                  onPressed: onCompose,
                  icon: const Icon(Icons.edit),
                  label: const Text('New Message'),
                )
              : null,
    );
  }

  /// Empty state for audit logs
  factory EmptyState.noAuditLogs({
    bool hasFilters = false,
    VoidCallback? onClearFilters,
  }) {
    return EmptyState(
      icon: Icons.history_outlined,
      title: hasFilters ? 'No logs match your filters' : 'No audit logs yet',
      message: hasFilters
          ? 'Try adjusting your filters to see more results.'
          : 'Admin actions will be recorded here.',
      action: hasFilters && onClearFilters != null
          ? TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear Filters'),
            )
          : null,
    );
  }

  /// Empty state for shipments/freight posts
  factory EmptyState.noShipments({
    bool hasFilters = false,
    VoidCallback? onClearFilters,
  }) {
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: hasFilters ? 'No shipments match your filters' : 'No shipments yet',
      message: hasFilters
          ? 'Try adjusting your filters to see more results.'
          : 'Shipments will appear here when shippers create them.',
      action: hasFilters && onClearFilters != null
          ? TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear Filters'),
            )
          : null,
    );
  }

  /// Empty state for search results
  factory EmptyState.noSearchResults({
    String? query,
    VoidCallback? onClear,
  }) {
    return EmptyState(
      icon: Icons.search_off_outlined,
      title: 'No results found',
      message: query != null
          ? 'No results for "$query". Try a different search term.'
          : 'Try searching for something else.',
      action: onClear != null
          ? TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Search'),
            )
          : null,
    );
  }

  /// Empty state for pending approvals
  factory EmptyState.noPendingApprovals() {
    return EmptyState(
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      title: 'All caught up!',
      message: 'There are no pending approvals at the moment.',
    );
  }

  /// Empty state for notifications
  factory EmptyState.noNotifications() {
    return EmptyState(
      icon: Icons.notifications_none_outlined,
      title: 'No notifications',
      message: 'You\'re all caught up! New notifications will appear here.',
    );
  }

  /// Empty state for recent activity
  factory EmptyState.noRecentActivity() {
    return EmptyState(
      icon: Icons.trending_flat_outlined,
      title: 'No recent activity',
      message: 'Recent activity will be shown here.',
    );
  }

  /// Empty state for evidence/attachments
  factory EmptyState.noAttachments({
    VoidCallback? onAdd,
  }) {
    return EmptyState(
      icon: Icons.attach_file_outlined,
      title: 'No attachments',
      message: 'No files or images have been attached yet.',
      compact: true,
      action: onAdd != null
          ? OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Attachment'),
            )
          : null,
    );
  }

  /// Empty state for notes/comments
  factory EmptyState.noNotes({
    VoidCallback? onAdd,
  }) {
    return EmptyState(
      icon: Icons.note_outlined,
      title: 'No notes',
      message: 'Add notes to keep track of important information.',
      compact: true,
      action: onAdd != null
          ? OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Note'),
            )
          : null,
    );
  }

  /// Empty state for statistics/analytics
  factory EmptyState.noData({
    String? message,
  }) {
    return EmptyState(
      icon: Icons.bar_chart_outlined,
      title: 'No data available',
      message: message ?? 'There\'s not enough data to display statistics yet.',
    );
  }

  /// Empty state for a generic error that should show empty rather than error
  factory EmptyState.loadFailed({
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'Failed to load',
      message: 'We couldn\'t load this content. Please try again.',
      action: onRetry != null
          ? FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            )
          : null,
    );
  }

  /// Empty state for coming soon features
  factory EmptyState.comingSoon() {
    return const EmptyState(
      icon: Icons.construction_outlined,
      iconColor: Colors.orange,
      title: 'Coming Soon',
      message: 'This feature is currently under development.',
    );
  }

  /// Empty state for access denied
  factory EmptyState.accessDenied() {
    return const EmptyState(
      icon: Icons.lock_outline,
      iconColor: Colors.red,
      title: 'Access Denied',
      message: 'You don\'t have permission to view this content.',
    );
  }
}

/// Animated empty state with optional illustration
class AnimatedEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool animate;

  const AnimatedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.animate = true,
  });

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: EmptyState(
            icon: widget.icon,
            title: widget.title,
            message: widget.message,
            action: widget.action,
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for empty lists
class EmptyStateShimmer extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const EmptyStateShimmer({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          height: itemHeight,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _ShimmerEffect(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        height: 14,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerEffect extends StatefulWidget {
  final Widget child;

  const _ShimmerEffect({required this.child});

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.withOpacity(0.3),
                Colors.grey.withOpacity(0.1),
                Colors.grey.withOpacity(0.3),
              ],
              stops: [
                0.0,
                _controller.value,
                1.0,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}
