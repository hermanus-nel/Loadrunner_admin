import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../users/presentation/providers/document_queue_providers.dart';

/// More screen - Settings, analytics, and additional features
/// TODO: Implement sub-screens in later steps
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final queueCount = ref.watch(documentQueueCountProvider);
    final queueBadge = queueCount.whenOrNull(
      data: (count) => count > 0 ? count.toString() : null,
    );
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
        title: const Text('More'),
      ),
      body: ListView(
        padding: AppDimensions.pagePadding,
        children: [
          // Analytics section
          _buildSectionHeader(context, 'Analytics'),
          _buildMenuCard(
            context,
            isDark,
            children: [
              _buildMenuItem(
                context,
                icon: Icons.bar_chart,
                title: 'Activity Metrics',
                subtitle: 'User and shipment analytics',
                onTap: () {
                  context.push(AppRoutes.analytics, extra: {'tab': 0});
                },
              ),
              _buildDivider(),
              _buildMenuItem(
                context,
                icon: Icons.attach_money,
                title: 'Financial Metrics',
                subtitle: 'Revenue and transaction data',
                onTap: () {
                  context.push(AppRoutes.analytics, extra: {'tab': 1});
                },
              ),
              _buildDivider(),
              _buildMenuItem(
                context,
                icon: Icons.trending_up,
                title: 'Growth Metrics',
                subtitle: 'User growth and trends',
                onTap: () {
                  context.push(AppRoutes.analytics, extra: {'tab': 2});
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          
          // Management section
          _buildSectionHeader(context, 'Management'),
          _buildMenuCard(
            context,
            isDark,
            children: [
              _buildMenuItem(
                context,
                icon: Icons.assignment_outlined,
                title: 'Document Queue',
                subtitle: 'Review pending driver documents',
                badge: queueBadge,
                badgeColor: Colors.orange,
                onTap: () {
                  context.goToDocumentQueue();
                },
              ),
              _buildDivider(),
              _buildMenuItem(
                context,
                icon: Icons.gavel,
                title: 'Disputes',
                subtitle: 'Resolve user disputes',
                badge: '3',
                badgeColor: AppColors.warning,
                onTap: () {
                  // TODO: Navigate to disputes
                },
              ),
              _buildDivider(),
              _buildMenuItem(
                context,
                icon: Icons.account_balance,
                title: 'Bank Verifications',
                subtitle: 'Verify bank accounts',
                badge: '5',
                badgeColor: AppColors.info,
                onTap: () {
                  // TODO: Navigate to bank verifications
                },
              ),
              _buildDivider(),
              _buildMenuItem(
                context,
                icon: Icons.sms,
                title: 'SMS Usage',
                subtitle: 'Track SMS costs and usage',
                onTap: () {
                  context.push('/sms-usage');
                },
              ),
              _buildDivider(),
              _buildMenuItem(
                context,
                icon: Icons.history,
                title: 'Audit Logs',
                subtitle: 'View admin actions history',
                onTap: () {
                  // TODO: Navigate to audit logs
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          
          // Settings section
          _buildSectionHeader(context, 'Settings'),
          _buildMenuCard(
            context,
            isDark,
            children: [
              _buildMenuItem(
                context,
                icon: Icons.person_outline,
                title: 'My Profile',
                subtitle: 'View and edit your profile',
                onTap: () {
                  // TODO: Navigate to profile
                },
              ),
              _buildDivider(),
              _buildMenuItem(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage notification settings',
                onTap: () {
                  context.push(AppRoutes.notificationPreferences);
                },
              ),
              _buildDivider(),
              _buildMenuItem(
                context,
                icon: Icons.dark_mode_outlined,
                title: 'Appearance',
                subtitle: 'Theme and display settings',
                onTap: () {
                  // TODO: Navigate to appearance settings
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          
          // Account section
          _buildSectionHeader(context, 'Account'),
          _buildMenuCard(
            context,
            isDark,
            children: [
              _buildMenuItem(
                context,
                icon: Icons.security,
                title: 'Security',
                subtitle: 'Password and 2FA settings',
                onTap: () {
                  // TODO: Navigate to security settings
                },
              ),
              _buildDivider(),
              _buildMenuItem(
                context,
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                isDestructive: true,
                onTap: () {
                  _showLogoutDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          
          // Version info
          Center(
            child: Text(
              'LoadRunner Admin v1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.spacingXs,
        bottom: AppDimensions.spacingXs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    bool isDark, {
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final textColor = isDestructive
        ? (isDark ? AppColors.errorDark : AppColors.errorLight)
        : null;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingXs),
        decoration: BoxDecoration(
          color: (isDestructive
                  ? (isDark ? AppColors.errorDark : AppColors.errorLight)
                  : primaryColor)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Icon(
          icon,
          size: AppDimensions.iconSm,
          color: isDestructive
              ? (isDark ? AppColors.errorDark : AppColors.errorLight)
              : primaryColor,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingXs,
                vertical: AppDimensions.spacingXxs,
              ),
              decoration: BoxDecoration(
                color: badgeColor ?? primaryColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                badge,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: AppDimensions.spacingXs),
          Icon(
            Icons.chevron_right,
            size: AppDimensions.iconSm,
            color: isDark 
                ? AppColors.textTertiaryDark 
                : AppColors.textTertiaryLight,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: AppDimensions.spacingXl + AppDimensions.spacingMd,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await FcmService.instance.removeToken();
              // TODO: Implement actual logout
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorLight,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
