// lib/features/disputes/presentation/screens/dispute_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/dispute_entity.dart';
import '../../domain/entities/evidence_entity.dart';
import '../providers/disputes_providers.dart';
import '../widgets/dispute_status_badge.dart';
import '../widgets/dispute_priority_badge.dart';
import '../widgets/evidence_gallery.dart';
import '../widgets/dispute_timeline.dart';
import '../widgets/resolution_dialog.dart';

class DisputeDetailScreen extends ConsumerStatefulWidget {
  final String disputeId;

  const DisputeDetailScreen({
    super.key,
    required this.disputeId,
  });

  @override
  ConsumerState<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends ConsumerState<DisputeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(disputeDetailNotifierProvider.notifier).fetchDisputeDetail(widget.disputeId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(disputeDetailNotifierProvider);

    if (state.isLoading && state.dispute == null) {
      return Scaffold(
        appBar: AppBar(centerTitle: true, title: const Text('Dispute Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.dispute == null) {
      return Scaffold(
        appBar: AppBar(centerTitle: true, title: const Text('Dispute Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Error loading dispute'),
              const SizedBox(height: 8),
              Text(state.error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(disputeDetailNotifierProvider.notifier)
                      .fetchDisputeDetail(widget.disputeId);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final dispute = state.dispute!;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Dispute #${dispute.id.substring(0, 8)}'),
        actions: [
          if (state.isUpdating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showMoreOptions(context, dispute),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Details'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Evidence'),
                  if (state.evidence.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.evidence.length}',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Timeline'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DetailsTab(dispute: dispute, state: state),
          _EvidenceTab(evidence: state.evidence, disputeId: widget.disputeId),
          _TimelineTab(timeline: state.timeline, dispute: dispute),
        ],
      ),
      bottomNavigationBar: dispute.isActive
          ? _ActionBar(dispute: dispute, disputeId: widget.disputeId)
          : null,
    );
  }

  void _showMoreOptions(BuildContext context, DisputeEntity dispute) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('Copy Dispute ID'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: dispute.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dispute ID copied')),
                );
              },
            ),
            if (dispute.shipment != null)
              ListTile(
                leading: const Icon(Icons.local_shipping),
                title: const Text('View Shipment'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/shipments/${dispute.freightPostId}');
                },
              ),
            if (dispute.raisedBy != null)
              ListTile(
                leading: const Icon(Icons.person),
                title: Text('View ${dispute.raisedBy!.displayName}'),
                subtitle: const Text('Raised by'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/users/${dispute.raisedById}');
                },
              ),
            if (dispute.raisedAgainst != null)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text('View ${dispute.raisedAgainst!.displayName}'),
                subtitle: const Text('Raised against'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/users/${dispute.raisedAgainstId}');
                },
              ),
            if (dispute.isActive)
              ListTile(
                leading: const Icon(Icons.assignment_ind),
                title: const Text('Assign to me'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(disputeDetailNotifierProvider.notifier)
                      .assignToSelf(disputeId: widget.disputeId);
                },
              ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh'),
              onTap: () {
                Navigator.pop(context);
                ref.read(disputeDetailNotifierProvider.notifier)
                    .fetchDisputeDetail(widget.disputeId);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DETAILS TAB
// ============================================================================

class _DetailsTab extends StatelessWidget {
  final DisputeEntity dispute;
  final DisputeDetailState state;

  const _DetailsTab({required this.dispute, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        // Handled by parent
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status and Priority card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dispute.title,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      DisputeStatusBadge(status: dispute.status),
                      const SizedBox(width: 8),
                      DisputePriorityBadge(priority: dispute.priority),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dispute.disputeType.displayName,
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(dispute.description),
                  if (dispute.ageInDays > 0) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: dispute.ageInDays > 7
                              ? theme.colorScheme.error
                              : theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Open for ${dispute.ageInDays} days',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: dispute.ageInDays > 7
                                ? theme.colorScheme.error
                                : theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Parties involved
          Text(
            'Parties Involved',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _PartyCard(
            title: 'Raised By',
            user: dispute.raisedBy,
            userId: dispute.raisedById,
          ),
          const SizedBox(height: 8),
          _PartyCard(
            title: 'Raised Against',
            user: dispute.raisedAgainst,
            userId: dispute.raisedAgainstId,
          ),
          const SizedBox(height: 16),

          // Shipment info
          if (dispute.shipment != null) ...[
            Text(
              'Related Shipment',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _ShipmentCard(shipment: dispute.shipment!, shipmentId: dispute.freightPostId),
            const SizedBox(height: 16),
          ],

          // Admin assignment
          Text(
            'Assignment',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: dispute.adminAssigned != null
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  dispute.adminAssigned != null ? Icons.person : Icons.person_outline,
                  color: dispute.adminAssigned != null
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.outline,
                ),
              ),
              title: Text(
                dispute.adminAssigned?.displayName ?? 'Unassigned',
                style: dispute.adminAssigned == null
                    ? TextStyle(color: theme.colorScheme.outline)
                    : null,
              ),
              subtitle: dispute.adminAssigned != null
                  ? const Text('Assigned admin')
                  : const Text('No admin assigned'),
            ),
          ),
          const SizedBox(height: 16),

          // Resolution info (if resolved)
          if (dispute.isResolved) ...[
            Text(
              'Resolution',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Resolved',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (dispute.resolution != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        ResolutionType.fromString(dispute.resolution!).displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (dispute.hasRefund) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Refund: R ${dispute.refundAmount!.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (dispute.resolvedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Resolved on ${DateFormat.yMMMd().format(dispute.resolvedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                    if (dispute.resolvedBy != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'By ${dispute.resolvedBy!.displayName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Dates
          Text(
            'Dates',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Created'),
                  trailing: Text(DateFormat.yMMMd().add_jm().format(dispute.createdAt)),
                ),
                ListTile(
                  leading: const Icon(Icons.update),
                  title: const Text('Last Updated'),
                  trailing: Text(DateFormat.yMMMd().add_jm().format(dispute.updatedAt)),
                ),
                if (dispute.resolvedAt != null)
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: const Text('Resolved'),
                    trailing: Text(DateFormat.yMMMd().add_jm().format(dispute.resolvedAt!)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 80), // Bottom padding for action bar
        ],
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  final String title;
  final DisputeUserInfo? user;
  final String userId;

  const _PartyCard({
    required this.title,
    required this.user,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: user?.profilePhotoUrl != null
              ? NetworkImage(user!.profilePhotoUrl!)
              : null,
          child: user?.profilePhotoUrl == null
              ? Text(user?.initials ?? '?')
              : null,
        ),
        title: Text(user?.displayName ?? 'Unknown User'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (user?.role != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: user!.role == 'Driver' ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  user!.role!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: user!.role == 'Driver' ? Colors.blue : Colors.green,
                  ),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => context.push('/users/$userId'),
        ),
        isThreeLine: user?.role != null,
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final DisputeShipmentInfo shipment;
  final String shipmentId;

  const _ShipmentCard({
    required this.shipment,
    required this.shipmentId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => context.push('/shipments/$shipmentId'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_shipping, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Shipment #${shipmentId.substring(0, 8)}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const Spacer(),
                  if (shipment.status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        shipment.status!,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
              if (shipment.pickupLocation != null || shipment.deliveryLocation != null) ...[
                const SizedBox(height: 12),
                if (shipment.pickupLocation != null)
                  Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shipment.pickupLocation!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (shipment.deliveryLocation != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shipment.deliveryLocation!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  Text(
                    'View shipment',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EVIDENCE TAB
// ============================================================================

class _EvidenceTab extends ConsumerWidget {
  final List<EvidenceEntity> evidence;
  final String disputeId;

  const _EvidenceTab({
    required this.evidence,
    required this.disputeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Add evidence button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddEvidenceDialog(context, ref),
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add Evidence'),
                ),
              ),
            ],
          ),
        ),

        // Evidence list
        Expanded(
          child: evidence.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No evidence uploaded',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add photos or documents to support this dispute',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : EvidenceGallery(
                  evidence: evidence,
                  onAddEvidence: () => _showAddEvidenceDialog(context, ref),
                ),
        ),
      ],
    );
  }

  void _showAddEvidenceDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _AddEvidenceDialog(
        disputeId: disputeId,
        onAdd: (type, description, fileUrl, metadata) async {
          final result = await ref.read(disputeDetailNotifierProvider.notifier).addEvidence(
            disputeId: disputeId,
            type: type,
            description: description,
            fileUrl: fileUrl,
            metadata: metadata,
          );
          return result.success;
        },
      ),
    );
  }
}

class _AddEvidenceDialog extends StatefulWidget {
  final String disputeId;
  final Future<bool> Function(
    EvidenceType type,
    String description,
    String? fileUrl,
    Map<String, dynamic>? metadata,
  ) onAdd;

  const _AddEvidenceDialog({
    required this.disputeId,
    required this.onAdd,
  });

  @override
  State<_AddEvidenceDialog> createState() => _AddEvidenceDialogState();
}

class _AddEvidenceDialogState extends State<_AddEvidenceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _fileUrlController = TextEditingController();
  EvidenceType _selectedType = EvidenceType.photo;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _fileUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Evidence'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<EvidenceType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Evidence Type',
                ),
                items: EvidenceType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fileUrlController,
                decoration: const InputDecoration(
                  labelText: 'File URL (Optional)',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe this evidence...',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await widget.onAdd(
      _selectedType,
      _descriptionController.text,
      _fileUrlController.text.isEmpty ? null : _fileUrlController.text,
      null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evidence added')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add evidence')),
        );
      }
    }
  }
}

// ============================================================================
// TIMELINE TAB
// ============================================================================

class _TimelineTab extends StatelessWidget {
  final List<DisputeTimelineEvent> timeline;
  final DisputeEntity dispute;

  const _TimelineTab({
    required this.timeline,
    required this.dispute,
  });

  @override
  Widget build(BuildContext context) {
    return DisputeTimeline(
      timeline: timeline,
      dispute: dispute,
    );
  }
}

// ============================================================================
// ACTION BAR
// ============================================================================

class _ActionBar extends ConsumerWidget {
  final DisputeEntity dispute;
  final String disputeId;

  const _ActionBar({
    required this.dispute,
    required this.disputeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
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
      child: SafeArea(
        child: Row(
          children: [
            // Update status button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showStatusDialog(context, ref),
                icon: const Icon(Icons.update),
                label: const Text('Status'),
              ),
            ),
            const SizedBox(width: 8),
            // Escalate button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showEscalateDialog(context, ref),
                icon: const Icon(Icons.priority_high),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
                label: const Text('Escalate'),
              ),
            ),
            const SizedBox(width: 8),
            // Resolve button
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _showResolveDialog(context, ref),
                icon: const Icon(Icons.check),
                label: const Text('Resolve'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: DisputeStatus.values
              .where((s) => s != DisputeStatus.resolved && s != DisputeStatus.closed)
              .map((status) => ListTile(
                    leading: DisputeStatusBadge(status: status),
                    title: Text(status.displayName),
                    selected: dispute.status == status,
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(disputeDetailNotifierProvider.notifier)
                          .updateStatus(disputeId: disputeId, status: status);
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEscalateDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escalate Dispute'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will mark the dispute as urgent and escalate it for senior review.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for escalation',
                hintText: 'Explain why this needs to be escalated...',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
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
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(context);
              final result = await ref.read(disputeDetailNotifierProvider.notifier)
                  .escalateDispute(
                    disputeId: disputeId,
                    reason: reasonController.text,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.success ? 'Dispute escalated' : 'Failed to escalate',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Escalate'),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ResolutionDialog(
        disputeId: disputeId,
        dispute: dispute,
        onResolve: (resolution, notes, refundAmount) async {
          final result = await ref.read(disputeDetailNotifierProvider.notifier)
              .resolveDispute(
                disputeId: disputeId,
                resolution: resolution,
                notes: notes,
                refundAmount: refundAmount,
              );
          return result.success;
        },
      ),
    );
  }
}
