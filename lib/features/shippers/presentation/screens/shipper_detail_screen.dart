// lib/features/shippers/presentation/screens/shipper_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/shipper_entity.dart';
import '../providers/shippers_providers.dart';
import '../widgets/shipper_tile.dart';

class ShipperDetailScreen extends ConsumerStatefulWidget {
  final String shipperId;

  const ShipperDetailScreen({
    super.key,
    required this.shipperId,
  });

  @override
  ConsumerState<ShipperDetailScreen> createState() => _ShipperDetailScreenState();
}

class _ShipperDetailScreenState extends ConsumerState<ShipperDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shipperDetailNotifierProvider.notifier).fetchShipperDetail(widget.shipperId);
    });
  }

  @override
  void dispose() {
    // Clear detail state when leaving
    ref.read(shipperDetailNotifierProvider.notifier).clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(shipperDetailNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(state.shipper?.displayName ?? 'Shipper'),
        actions: [
          if (state.shipper != null)
            IconButton(
              icon: const Icon(Icons.message),
              tooltip: 'Send Message',
              onPressed: () {
                context.push('/messages/compose', extra: {
                  'recipientId': widget.shipperId,
                });
              },
            ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy_id',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Copy ID'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'view_shipments',
                child: ListTile(
                  leading: Icon(Icons.local_shipping),
                  title: Text('View Shipments'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'view_disputes',
                child: ListTile(
                  leading: Icon(Icons.gavel),
                  title: Text('View Disputes'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(state),
      bottomNavigationBar: state.shipper != null
          ? _buildActionBar(state.shipper!)
          : null,
    );
  }

  Widget _buildBody(ShipperDetailState state) {
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.shipper == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Error loading shipper', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(state.error!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(shipperDetailNotifierProvider.notifier).fetchShipperDetail(widget.shipperId);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.shipper == null) {
      return const Center(child: Text('Shipper not found'));
    }

    final shipper = state.shipper!;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(shipperDetailNotifierProvider.notifier).fetchShipperDetail(widget.shipperId);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          _buildProfileHeader(shipper),
          const SizedBox(height: 16),

          // Status card
          _buildStatusCard(shipper),
          const SizedBox(height: 16),

          // Statistics
          _buildStatisticsCard(shipper),
          const SizedBox(height: 16),

          // Contact info
          _buildContactCard(shipper),
          const SizedBox(height: 16),

          // Recent shipments
          _buildRecentShipmentsCard(state.recentShipments),
          const SizedBox(height: 16),

          // Account info
          _buildAccountInfoCard(shipper),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ShipperEntity shipper) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: shipper.isCurrentlySuspended
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.primaryContainer,
                  backgroundImage: shipper.profilePhotoUrl != null
                      ? NetworkImage(shipper.profilePhotoUrl!)
                      : null,
                  child: shipper.profilePhotoUrl == null
                      ? Text(
                          shipper.initials,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: shipper.isCurrentlySuspended
                                ? theme.colorScheme.onErrorContainer
                                : theme.colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
                if (shipper.isCurrentlySuspended)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.block,
                        size: 20,
                        color: theme.colorScheme.onError,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              shipper.displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // Phone
            Text(
              shipper.phoneNumber,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),

            // Status badge
            ShipperStatusBadge(shipper: shipper),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ShipperEntity shipper) {
    final theme = Theme.of(context);

    if (!shipper.isCurrentlySuspended) {
      return Card(
        color: Colors.green.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Active',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ShipperActivityIndicator(shipper: shipper),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.block, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Account Suspended',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (shipper.suspendedReason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Reason: ${shipper.suspendedReason}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (shipper.suspendedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Suspended: ${DateFormat.yMMMd().add_jm().format(shipper.suspendedAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            if (shipper.suspensionEndsAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Ends: ${DateFormat.yMMMd().add_jm().format(shipper.suspensionEndsAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(ShipperEntity shipper) {
    final theme = Theme.of(context);
    final stats = shipper.stats ?? const ShipperStats();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.local_shipping,
                    value: '${stats.totalShipments}',
                    label: 'Total Shipments',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    icon: Icons.pending,
                    value: '${stats.activeShipments}',
                    label: 'Active',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.check_circle,
                    value: '${stats.completedShipments}',
                    label: 'Completed',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    icon: Icons.cancel,
                    value: '${stats.cancelledShipments}',
                    label: 'Cancelled',
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.attach_money,
                    value: 'R ${NumberFormat.compact().format(stats.totalSpent)}',
                    label: 'Total Spent',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    icon: Icons.star,
                    value: stats.ratingsCount > 0
                        ? stats.averageRating.toStringAsFixed(1)
                        : '-',
                    label: 'Rating (${stats.ratingsCount})',
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.gavel,
                    value: '${stats.disputesCount}',
                    label: 'Disputes',
                    color: Colors.purple,
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    icon: Icons.warning,
                    value: '${stats.openDisputesCount}',
                    label: 'Open Disputes',
                    color: stats.openDisputesCount > 0 ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(ShipperEntity shipper) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Contact Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Phone'),
            subtitle: Text(shipper.phoneNumber),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: shipper.phoneNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Phone copied')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () {
                    // TODO: Launch phone dialer
                  },
                ),
              ],
            ),
          ),
          if (shipper.email != null) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(shipper.email!),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shipper.email!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email copied')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          if (shipper.addressName != null) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Address'),
              subtitle: Text(shipper.addressName!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentShipmentsCard(List<ShipperRecentShipment> shipments) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Shipments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full shipments list
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          if (shipments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No shipments yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...shipments.map((shipment) => ListTile(
                  leading: Icon(
                    Icons.local_shipping,
                    color: _getStatusColor(shipment.status),
                  ),
                  title: Text(
                    '${shipment.pickupLocation} → ${shipment.deliveryLocation}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${shipment.status} • ${DateFormat.MMMd().format(shipment.createdAt)}',
                  ),
                  trailing: shipment.amount != null
                      ? Text(
                          'R ${NumberFormat.compact().format(shipment.amount)}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                  onTap: () {
                    // TODO: Navigate to shipment detail
                  },
                )),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(ShipperEntity shipper) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Account Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Registered'),
            subtitle: Text(DateFormat.yMMMd().add_jm().format(shipper.createdAt)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Last Login'),
            subtitle: Text(
              shipper.lastLoginAt != null
                  ? DateFormat.yMMMd().add_jm().format(shipper.lastLoginAt!)
                  : 'Never',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('User ID'),
            subtitle: Text(
              shipper.id,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: shipper.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ID copied')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(ShipperEntity shipper) {
    final theme = Theme.of(context);
    final state = ref.watch(shipperDetailNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.message),
                label: const Text('Message'),
                onPressed: () {
                  context.push('/messages/compose', extra: {
                    'recipientId': widget.shipperId,
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: shipper.isCurrentlySuspended
                  ? FilledButton.icon(
                      icon: state.isUpdating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle),
                      label: const Text('Unsuspend'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: state.isUpdating
                          ? null
                          : () => _showUnsuspendDialog(),
                    )
                  : FilledButton.icon(
                      icon: state.isUpdating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.block),
                      label: const Text('Suspend'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                      ),
                      onPressed: state.isUpdating
                          ? null
                          : () => _showSuspendDialog(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'copy_id':
        Clipboard.setData(ClipboardData(text: widget.shipperId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID copied')),
        );
        break;
      case 'view_shipments':
        // TODO: Navigate to shipments with filter
        break;
      case 'view_disputes':
        context.push('/disputes'); // TODO: Add filter param
        break;
      case 'refresh':
        ref.read(shipperDetailNotifierProvider.notifier).fetchShipperDetail(widget.shipperId);
        break;
    }
  }

  void _showSuspendDialog() {
    final reasonController = TextEditingController();
    DateTime? endsAt;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Suspend Shipper'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This will prevent the shipper from creating new shipments.'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Enter suspension reason...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Temporary Suspension'),
                subtitle: endsAt != null
                    ? Text('Ends: ${DateFormat.yMMMd().format(endsAt!)}')
                    : const Text('Permanent if not set'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => endsAt = date);
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a reason')),
                  );
                  return;
                }
                Navigator.pop(context);
                final success = await ref
                    .read(shipperDetailNotifierProvider.notifier)
                    .suspendShipper(widget.shipperId, reasonController.text, endsAt: endsAt);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shipper suspended')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Suspend'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnsuspendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsuspend Shipper'),
        content: const Text('This will reactivate the shipper\'s account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(shipperDetailNotifierProvider.notifier)
                  .unsuspendShipper(widget.shipperId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shipper reactivated')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Unsuspend'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'in transit':
        return Colors.blue;
      case 'posted':
      case 'bidding':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
