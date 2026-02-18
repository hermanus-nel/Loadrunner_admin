// lib/core/router/router_analytics.dart
// 
// ADD THIS ROUTE TO YOUR EXISTING ROUTER FILE
// 
// This file shows the route configuration needed to add the Analytics screen
// to your existing GoRouter setup.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/analytics/presentation/screens/analytics_screen.dart';

// =============================================================================
// ROUTE PATHS
// =============================================================================

/// Add to your existing route paths
class AnalyticsRoutes {
  static const String analytics = '/analytics';
}

// =============================================================================
// ROUTE CONFIGURATION
// =============================================================================

/// Add this GoRoute to your existing router configuration
/// Place it inside your authenticated routes (after auth check)
final analyticsRoute = GoRoute(
  path: AnalyticsRoutes.analytics,
  name: 'analytics',
  builder: (context, state) => const AnalyticsScreen(),
);

// =============================================================================
// EXAMPLE INTEGRATION
// =============================================================================

/// Example of how to integrate with existing router:
/// 
/// ```dart
/// final router = GoRouter(
///   routes: [
///     // ... existing routes ...
///     
///     // Add analytics route (requires authentication)
///     GoRoute(
///       path: '/analytics',
///       name: 'analytics',
///       builder: (context, state) => const AnalyticsScreen(),
///     ),
///   ],
/// );
/// ```

// =============================================================================
// NAVIGATION HELPER
// =============================================================================

/// Extension for easy navigation to analytics
extension AnalyticsNavigation on BuildContext {
  /// Navigate to analytics screen
  void goToAnalytics() {
    go(AnalyticsRoutes.analytics);
  }

  /// Push analytics screen (allows back navigation)
  void pushAnalytics() {
    push(AnalyticsRoutes.analytics);
  }
}

// =============================================================================
// INTEGRATION WITH MORE SCREEN
// =============================================================================

/// Example of adding Analytics to your More/Settings screen:
/// 
/// ```dart
/// ListTile(
///   leading: const Icon(Icons.analytics_outlined),
///   title: const Text('Analytics'),
///   subtitle: const Text('View platform metrics'),
///   trailing: const Icon(Icons.chevron_right),
///   onTap: () => context.pushAnalytics(),
/// ),
/// ```

// =============================================================================
// FULL ROUTER EXAMPLE
// =============================================================================

/// Complete router example with analytics integration:
/// 
/// ```dart
/// import 'package:go_router/go_router.dart';
/// import 'package:flutter_riverpod/flutter_riverpod.dart';
/// 
/// import '../features/auth/presentation/providers/auth_provider.dart';
/// import '../features/analytics/presentation/screens/analytics_screen.dart';
/// // ... other imports ...
/// 
/// final routerProvider = Provider<GoRouter>((ref) {
///   final authState = ref.watch(authNotifierProvider);
/// 
///   return GoRouter(
///     initialLocation: '/',
///     redirect: (context, state) {
///       final isAuthenticated = authState.isAuthenticated;
///       final isAuthRoute = state.matchedLocation == '/login' ||
///           state.matchedLocation == '/signup';
/// 
///       if (!isAuthenticated && !isAuthRoute) {
///         return '/login';
///       }
///       if (isAuthenticated && isAuthRoute) {
///         return '/';
///       }
///       return null;
///     },
///     routes: [
///       // Auth routes
///       GoRoute(
///         path: '/login',
///         builder: (context, state) => const LoginScreen(),
///       ),
///       
///       // Shell route for bottom navigation
///       ShellRoute(
///         builder: (context, state, child) => MainShell(child: child),
///         routes: [
///           GoRoute(
///             path: '/',
///             builder: (context, state) => const DashboardScreen(),
///           ),
///           GoRoute(
///             path: '/shipments',
///             builder: (context, state) => const ShipmentsScreen(),
///           ),
///           GoRoute(
///             path: '/drivers',
///             builder: (context, state) => const DriversScreen(),
///           ),
///           GoRoute(
///             path: '/more',
///             builder: (context, state) => const MoreScreen(),
///           ),
///         ],
///       ),
///       
///       // Analytics route (outside shell for full screen)
///       GoRoute(
///         path: '/analytics',
///         name: 'analytics',
///         builder: (context, state) => const AnalyticsScreen(),
///       ),
///     ],
///   );
/// });
/// ```
