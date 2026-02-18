// lib/features/payments/presentation/screens/payments_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/repositories/payments_repository.dart';
import '../providers/payments_providers.dart';
import 'transactions_list_screen.dart';

/// Main payments screen shown in the bottom navigation
/// Displays payment overview/stats and quick access to transactions
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: 'R', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    // Show the full transactions list directly
    return const TransactionsListScreen();
  }
}

/// Alternative: Payment Overview Dashboard (if you want a summary view first)
/// This can be used instead of TransactionsListScreen if you prefer a dashboard approach
class PaymentsOverviewScreen extends ConsumerWidget {
  const PaymentsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(defaultPaymentStatsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'R', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(defaultPaymentStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Revenue card
              _buildRevenueCard(theme, stats, currencyFormat),

              const SizedBox(height: 20),

              // Stats grid
              _buildStatsGrid(theme, stats, currencyFormat),

              const SizedBox(height: 20),

              // Quick actions
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context, theme),

              const SizedBox(height: 20),

              // Recent transactions section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to full transactions list
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TransactionsListScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
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
                'Failed to load payment stats',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(defaultPaymentStatsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCard(
    ThemeData theme,
    PaymentStats stats,
    NumberFormat currencyFormat,
  ) {
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Revenue (30 Days)',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(stats.totalRevenue),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildRevenueSubStat(
                  theme,
                  'Commission',
                  currencyFormat.format(stats.totalCommissions),
                ),
                const SizedBox(width: 32),
                _buildRevenueSubStat(
                  theme,
                  'Refunded',
                  currencyFormat.format(stats.refundedAmount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueSubStat(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimary.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    ThemeData theme,
    PaymentStats stats,
    NumberFormat currencyFormat,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          theme,
          'Total Transactions',
          stats.totalTransactions.toString(),
          Icons.receipt_long_outlined,
          Colors.blue,
        ),
        _buildStatCard(
          theme,
          'Success Rate',
          '${stats.successRate.toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.green,
        ),
        _buildStatCard(
          theme,
          'Successful',
          stats.successfulTransactions.toString(),
          Icons.check_circle_outline,
          Colors.green,
        ),
        _buildStatCard(
          theme,
          'Failed',
          stats.failedTransactions.toString(),
          Icons.error_outline,
          Colors.red,
        ),
        _buildStatCard(
          theme,
          'Pending',
          stats.pendingTransactions.toString(),
          Icons.schedule,
          Colors.orange,
        ),
        _buildStatCard(
          theme,
          'Refunded',
          stats.refundedTransactions.toString(),
          Icons.replay,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            theme,
            'All Transactions',
            Icons.list_alt,
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TransactionsListScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            theme,
            'Failed Payments',
            Icons.error_outline,
            () {
              // Navigate to transactions with failed filter
              // This would need router support for query params
            },
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    ThemeData theme,
    String label,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: color?.withOpacity(0.3) ??
                theme.colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color ?? theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
