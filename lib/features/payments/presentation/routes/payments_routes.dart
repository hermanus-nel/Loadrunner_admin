// lib/features/payments/presentation/routes/payments_routes.dart
//
// Add these routes to your app_router.dart file
//
// Import at top of app_router.dart:
// import '../../features/payments/presentation/screens/transactions_list_screen.dart';
// import '../../features/payments/presentation/screens/transaction_detail_screen.dart';

/*

// ============================================================================
// ROUTES TO ADD TO APP_ROUTER.dart
// ============================================================================

// Add this route inside your ShellRoute children (for the bottom nav):
GoRoute(
  path: '/payments',
  name: 'payments',
  builder: (context, state) => const PaymentsScreen(),
),

// Add this route at the root level (outside ShellRoute) for detail screen:
GoRoute(
  path: '/payments/:id',
  name: 'payment-detail',
  builder: (context, state) {
    final paymentId = state.pathParameters['id']!;
    return TransactionDetailScreen(paymentId: paymentId);
  },
),

// ============================================================================
// FULL EXAMPLE app_router.dart structure:
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/users/presentation/screens/users_screen.dart';
import '../features/payments/presentation/screens/payments_screen.dart';
import '../features/payments/presentation/screens/transaction_detail_screen.dart';
import '../features/messages/presentation/screens/messages_screen.dart';
import '../features/more/presentation/screens/more_screen.dart';
import '../shell/main_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    // Auth route
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const SignupScreen(),
    ),
    
    // Main shell with bottom navigation
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/users',
          name: 'users',
          builder: (context, state) => const UsersScreen(),
        ),
        GoRoute(
          path: '/payments',
          name: 'payments',
          builder: (context, state) => const PaymentsScreen(),
        ),
        GoRoute(
          path: '/messages',
          name: 'messages',
          builder: (context, state) => const MessagesScreen(),
        ),
        GoRoute(
          path: '/more',
          name: 'more',
          builder: (context, state) => const MoreScreen(),
        ),
      ],
    ),
    
    // Detail routes (outside shell for full-screen experience)
    GoRoute(
      path: '/payments/:id',
      name: 'payment-detail',
      builder: (context, state) {
        final paymentId = state.pathParameters['id']!;
        return TransactionDetailScreen(paymentId: paymentId);
      },
    ),
    
    // Add other detail routes here...
  ],
  
  // Redirect logic
  redirect: (context, state) {
    // Add your auth redirect logic here
    return null;
  },
);

*/
