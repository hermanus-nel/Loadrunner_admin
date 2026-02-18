// lib/features/payments/presentation/screens/transactions_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/components/loading_state.dart';
import '../../domain/entities/payment_entity.dart';
import '../providers/payments_providers.dart';
import '../widgets/payment_list_tile.dart';
import '../widgets/payment_status_badge.dart';

/// Screen displaying list of all transactions with filtering capabilities
class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() =>
      _TransactionsListScreenState();
}

class _TransactionsListScreenState
    extends ConsumerState<TransactionsListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Fetch payments on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentsListNotifierProvider.notifier).fetchPayments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paymentsListNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(paymentsListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Transactions'),
        actions: [
          // Filter toggle button
          IconButton(
            icon: Badge(
              isLabelVisible: state.filters.hasActiveFilters,
              child: Icon(
                _showFilters ? Icons.filter_list_off : Icons.filter_list,
              ),
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Toggle Filters',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading
                ? null
                : () => ref
                    .read(paymentsListNotifierProvider.notifier)
                    .fetchPayments(refresh: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by transaction ID or user name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(paymentsListNotifierProvider.notifier)
                              .search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                ref.read(paymentsListNotifierProvider.notifier).search(value);
              },
            ),
          ),

          // Filter panel
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _showFilters
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildFilterPanel(theme, state),
            secondChild: const SizedBox.shrink(),
          ),

          // Payment stats summary
          if (!state.isLoading && state.payments.isNotEmpty)
            _buildStatsSummary(theme, state),

          // Payments list
          Expanded(
            child: _buildPaymentsList(theme, state),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(ThemeData theme, PaymentsListState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status filter chips
          Text(
            'Status',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PaymentStatusChip(
                status: null,
                isSelected: state.filters.status == null,
                onTap: () => ref
                    .read(paymentsListNotifierProvider.notifier)
                    .filterByStatus(null),
              ),
              ...PaymentStatus.values.map(
                (status) => PaymentStatusChip(
                  status: status,
                  isSelected: state.filters.status == status,
                  onTap: () => ref
                      .read(paymentsListNotifierProvider.notifier)
                      .filterByStatus(status),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Date range filter
          Text(
            'Date Range',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateFilterButton(
                  label: 'From',
                  date: state.filters.startDate,
                  onTap: () => _selectStartDate(state.filters.startDate),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateFilterButton(
                  label: 'To',
                  date: state.filters.endDate,
                  onTap: () => _selectEndDate(state.filters.endDate),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick date filters
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickDateChip(
                label: 'Today',
                onTap: () => _setDateRange(
                  DateTime.now().copyWith(hour: 0, minute: 0, second: 0),
                  DateTime.now(),
                ),
              ),
              _QuickDateChip(
                label: 'Last 7 Days',
                onTap: () => _setDateRange(
                  DateTime.now().subtract(const Duration(days: 7)),
                  DateTime.now(),
                ),
              ),
              _QuickDateChip(
                label: 'Last 30 Days',
                onTap: () => _setDateRange(
                  DateTime.now().subtract(const Duration(days: 30)),
                  DateTime.now(),
                ),
              ),
              _QuickDateChip(
                label: 'This Month',
                onTap: () => _setDateRange(
                  DateTime(DateTime.now().year, DateTime.now().month, 1),
                  DateTime.now(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Amount range filter
          Text(
            'Amount Range',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minAmountController,
                  decoration: InputDecoration(
                    labelText: 'Min',
                    prefixText: 'R ',
                    hintText: '0',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _applyAmountFilter(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('–'),
              ),
              Expanded(
                child: TextField(
                  controller: _maxAmountController,
                  decoration: InputDecoration(
                    labelText: 'Max',
                    prefixText: 'R ',
                    hintText: '0',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _applyAmountFilter(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: _applyAmountFilter,
                tooltip: 'Apply amount filter',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Clear filters button
          if (state.filters.hasActiveFilters)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _minAmountController.clear();
                  _maxAmountController.clear();
                  ref.read(paymentsListNotifierProvider.notifier).clearFilters();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All Filters'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(ThemeData theme, PaymentsListState state) {
    final currencyFormat = NumberFormat.currency(symbol: 'R', decimalDigits: 2);
    
    // Calculate summary from current filtered results
    double totalAmount = 0;
    int successCount = 0;
    int failedCount = 0;

    for (final payment in state.payments) {
      totalAmount += payment.amount;
      if (payment.status == PaymentStatus.success) successCount++;
      if (payment.status == PaymentStatus.failed) failedCount++;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            theme,
            'Total',
            currencyFormat.format(totalAmount),
            Icons.account_balance_wallet_outlined,
          ),
          _buildStatDivider(theme),
          _buildStatItem(
            theme,
            'Showing',
            '${state.payments.length} of ${state.pagination.totalCount}',
            Icons.list_alt,
          ),
          _buildStatDivider(theme),
          _buildStatItem(
            theme,
            'Success',
            '$successCount',
            Icons.check_circle_outline,
            color: Colors.green,
          ),
          _buildStatDivider(theme),
          _buildStatItem(
            theme,
            'Failed',
            '$failedCount',
            Icons.error_outline,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: color ?? theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(ThemeData theme) {
    return Container(
      height: 40,
      width: 1,
      color: theme.colorScheme.outline.withOpacity(0.2),
    );
  }

  Widget _buildPaymentsList(ThemeData theme, PaymentsListState state) {
    if (state.isLoading && state.payments.isEmpty) {
      return const ShimmerList(itemCount: 6, itemHeight: 80);
    }

    if (state.error != null && state.payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load transactions',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(paymentsListNotifierProvider.notifier)
                  .fetchPayments(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              state.filters.hasActiveFilters
                  ? 'No transactions match your filters'
                  : 'No transactions yet',
              style: theme.textTheme.titleMedium,
            ),
            if (state.filters.hasActiveFilters) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _minAmountController.clear();
                  _maxAmountController.clear();
                  ref.read(paymentsListNotifierProvider.notifier).clearFilters();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(paymentsListNotifierProvider.notifier)
          .fetchPayments(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: state.payments.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.payments.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final payment = state.payments[index];
          return PaymentListTile(
            payment: payment,
            onTap: () => context.goToTransactionDetail(payment.id),
          );
        },
      ),
    );
  }

  Future<void> _selectStartDate(DateTime? currentDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      ref.read(paymentsListNotifierProvider.notifier).filterByDateRange(
            date,
            ref.read(paymentsListNotifierProvider).filters.endDate,
          );
    }
  }

  Future<void> _selectEndDate(DateTime? currentDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      ref.read(paymentsListNotifierProvider.notifier).filterByDateRange(
            ref.read(paymentsListNotifierProvider).filters.startDate,
            date,
          );
    }
  }

  void _setDateRange(DateTime start, DateTime end) {
    ref.read(paymentsListNotifierProvider.notifier).filterByDateRange(start, end);
  }

  void _applyAmountFilter() {
    final min = double.tryParse(_minAmountController.text);
    final max = double.tryParse(_maxAmountController.text);
    ref.read(paymentsListNotifierProvider.notifier).filterByAmountRange(min, max);
  }
}

/// Date filter button widget
class _DateFilterButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateFilterButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    date != null ? dateFormat.format(date!) : 'Select date',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: date != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick date filter chip
class _QuickDateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickDateChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
