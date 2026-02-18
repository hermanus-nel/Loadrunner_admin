import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../error/network_error_widget.dart';
import '../navigation/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Main scaffold widget with bottom navigation bar
/// Wraps the main app content and provides persistent navigation
class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  /// Get current tab index based on route
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    
    if (location.startsWith(AppRoutes.users)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.payments)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.messages)) {
      return 3;
    }
    if (location.startsWith(AppRoutes.more)) {
      return 4;
    }
    
    // Default to dashboard
    return 0;
  }

  /// Handle tab selection
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.users);
        break;
      case 2:
        context.go(AppRoutes.payments);
        break;
      case 3:
        context.go(AppRoutes.messages);
        break;
      case 4:
        context.go(AppRoutes.more);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: OfflineBanner(child: widget.child),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: AppDimensions.bottomNavHeight,
            child: BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) => _onItemTapped(index, context),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: isDark 
                  ? AppColors.primaryDark 
                  : AppColors.primaryLight,
              unselectedItemColor: isDark 
                  ? AppColors.textTertiaryDark 
                  : AppColors.textTertiaryLight,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              iconSize: AppDimensions.iconMd,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'Users',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.payments_outlined),
                  activeIcon: Icon(Icons.payments),
                  label: 'Payments',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.mail_outline),
                  activeIcon: Icon(Icons.mail),
                  label: 'Messages',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz),
                  activeIcon: Icon(Icons.more_horiz),
                  label: 'More',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
