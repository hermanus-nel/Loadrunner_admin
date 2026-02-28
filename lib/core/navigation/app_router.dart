// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/users/presentation/screens/users_screen.dart';
import '../../features/users/presentation/screens/driver_profile_screen.dart';
import '../../features/users/presentation/screens/vehicle_detail_screen.dart';
import '../../features/users/presentation/screens/vehicle_doc_review_screen.dart';
import '../../features/payments/presentation/screens/payments_screen.dart';
import '../../features/payments/presentation/screens/transaction_detail_screen.dart';
import '../../features/messages/presentation/screens/messages_screen.dart';
import '../../features/messages/presentation/screens/conversation_screen.dart';
import '../../features/messages/presentation/screens/compose_message_screen.dart';
import '../../features/messages/presentation/screens/broadcast_screen.dart';
import '../../features/messages/domain/entities/message_entity.dart';
import '../../features/messages/domain/entities/message_template_entity.dart';
import '../../features/disputes/presentation/screens/disputes_list_screen.dart';
import '../../features/disputes/presentation/screens/dispute_detail_screen.dart';
import '../../features/shippers/presentation/screens/shippers_list_screen.dart';
import '../../features/shippers/presentation/screens/shipper_detail_screen.dart';
import '../../features/audit_logs/presentation/screens/audit_logs_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/sms_usage/presentation/screens/sms_usage_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/notifications/presentation/screens/notification_preferences_screen.dart';
import '../../features/users/presentation/screens/document_queue_screen.dart';
import '../../features/users/presentation/screens/document_review_screen.dart';
import '../../features/users/domain/entities/document_queue_item.dart';
import '../../features/more/presentation/screens/more_screen.dart';
import '../components/main_scaffold.dart';

/// Route path constants
class AppRoutes {
  AppRoutes._();

  // Auth routes
  static const String login = '/login';

  // Main tab routes (bottom navigation)
  static const String dashboard = '/';
  static const String users = '/users';
  static const String payments = '/payments';
  static const String messages = '/messages';
  static const String more = '/more';

  // Users sub-routes
  static const String driverDetail = '/users/driver/:id';
  static const String vehicleDetail = '/users/vehicle/:id';
  static const String userShipperDetail = '/users/shipper/:id';

  // Payments sub-routes
  static const String transactionDetail = '/payments/transaction/:id';

  // Messages sub-routes
  static const String conversation = '/messages/conversation/:userId';
  static const String composeMessage = '/messages/compose';
  static const String broadcast = '/messages/broadcast';

  // Disputes routes
  static const String disputes = '/disputes';
  static const String disputeDetail = '/disputes/:id';

  // Shippers routes
  static const String shippers = '/shippers';
  static const String shipperDetail = '/shippers/:id';

  // Audit logs route
  static const String auditLogs = '/audit-logs';

  // SMS usage route
  static const String smsUsage = '/sms-usage';

  // Analytics route
  static const String analytics = '/analytics';

  // Notifications routes
  static const String notifications = '/notifications';
  static const String notificationPreferences = '/notifications/preferences';

  // Document review routes
  static const String documentQueue = '/document-queue';
  static const String documentReview = '/document-review/:id';
  static const String vehicleDocReview = '/users/vehicle/:id/document-review';

  // Helper methods for building paths
  static String driverDetailPath(String id) => '/users/driver/$id';
  static String vehicleDetailPath(String id) => '/users/vehicle/$id';
  static String userShipperDetailPath(String id) => '/users/shipper/$id';
  static String transactionDetailPath(String id) => '/payments/transaction/$id';
  static String conversationPath(String userId) => '/messages/conversation/$userId';
  static String disputeDetailPath(String id) => '/disputes/$id';
  static String shipperDetailPath(String id) => '/shippers/$id';
  static String notificationsPath() => '/notifications';
  static String notificationPreferencesPath() => '/notifications/preferences';
  static String documentReviewPath(String id) => '/document-review/$id';
  static String vehicleDocReviewPath(String id) =>
      '/users/vehicle/$id/document-review';
}

/// Navigation key for accessing navigator state
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

/// Notifier that triggers GoRouter redirect re-evaluation
class _AuthChangeNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// GoRouter provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authChangeNotifier = _AuthChangeNotifier();

  ref.listen(authNotifierProvider, (previous, next) {
    authChangeNotifier.notify();
  });

  ref.onDispose(() => authChangeNotifier.dispose());

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    refreshListenable: authChangeNotifier,

    // Redirect logic for authentication
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isAuthenticated = authState.isAuthenticated && authState.isAdmin;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      // If not authenticated and not on login page, redirect to login
      if (!isAuthenticated && !isLoginRoute) {
        return AppRoutes.login;
      }

      // If authenticated and on login page, redirect to dashboard
      if (isAuthenticated && isLoginRoute) {
        return AppRoutes.dashboard;
      }

      return null; // No redirect needed
    },

    routes: [
      // ================================================================
      // AUTH ROUTES (outside shell)
      // ================================================================
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const SignupScreen(),
      ),

      // ================================================================
      // DETAIL ROUTES (outside shell for full-screen experience)
      // ================================================================

      // Driver profile/detail screen
      GoRoute(
        path: '/users/driver/:id',
        name: 'driverDetail',
        builder: (context, state) {
          final driverId = state.pathParameters['id']!;
          return DriverProfileScreen(driverId: driverId);
        },
      ),

      // Vehicle detail screen
      GoRoute(
        path: '/users/vehicle/:id',
        name: 'vehicleDetail',
        builder: (context, state) {
          final vehicleId = state.pathParameters['id']!;
          return VehicleDetailScreen(vehicleId: vehicleId);
        },
      ),

      // Vehicle document review screen
      GoRoute(
        path: '/users/vehicle/:id/document-review',
        name: 'vehicleDocReview',
        builder: (context, state) {
          final vehicleId = state.pathParameters['id']!;
          final extra = state.extra! as Map<String, dynamic>;
          return VehicleDocReviewScreen(
            vehicleId: vehicleId,
            docType: extra['docType'] as String,
            docUrl: extra['docUrl'] as String,
            currentStatus: extra['currentStatus'] as String?,
          );
        },
      ),

      // Shipper profile/detail screen (from Users tab)
      GoRoute(
        path: '/users/shipper/:id',
        name: 'userShipperDetail',
        builder: (context, state) {
          final shipperId = state.pathParameters['id']!;
          return ShipperDetailScreen(shipperId: shipperId);
        },
      ),

      // Transaction detail screen
      GoRoute(
        path: '/payments/transaction/:id',
        name: 'transactionDetail',
        builder: (context, state) {
          final paymentId = state.pathParameters['id']!;
          return TransactionDetailScreen(paymentId: paymentId);
        },
      ),

      // ================================================================
      // MESSAGES SUB-ROUTES (outside shell for full-screen)
      // ================================================================

      // Conversation screen (chat with user)
      GoRoute(
        path: '/messages/conversation/:userId',
        name: 'conversation',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ConversationScreen(userId: userId);
        },
      ),

      // Compose new message screen
      GoRoute(
        path: '/messages/compose',
        name: 'composeMessage',
        builder: (context, state) {
          // Optional: pass template or recipient via extra
          final extra = state.extra as Map<String, dynamic>?;
          return ComposeMessageScreen(
            initialRecipient: extra?['recipient'] as MessageUserInfo?,
            initialTemplate: extra?['template'] as MessageTemplateEntity?,
          );
        },
      ),

      // Broadcast message screen
      GoRoute(
        path: '/messages/broadcast',
        name: 'broadcast',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BroadcastScreen(
            initialTemplate: extra?['template'] as MessageTemplateEntity?,
          );
        },
      ),

      // ================================================================
      // DISPUTES ROUTES (outside shell for full-screen)
      // ================================================================

      // Disputes list screen
      GoRoute(
        path: '/disputes',
        name: 'disputes',
        builder: (context, state) => const DisputesListScreen(),
      ),

      // Dispute detail screen
      GoRoute(
        path: '/disputes/:id',
        name: 'disputeDetail',
        builder: (context, state) {
          final disputeId = state.pathParameters['id']!;
          return DisputeDetailScreen(disputeId: disputeId);
        },
      ),

      // ================================================================
      // SHIPPERS ROUTES (outside shell for full-screen)
      // ================================================================

      // Shippers list screen
      GoRoute(
        path: '/shippers',
        name: 'shippers',
        builder: (context, state) => const ShippersListScreen(),
      ),

      // Shipper detail screen
      GoRoute(
        path: '/shippers/:id',
        name: 'shipperDetail',
        builder: (context, state) {
          final shipperId = state.pathParameters['id']!;
          return ShipperDetailScreen(shipperId: shipperId);
        },
      ),

      // ================================================================
      // AUDIT LOGS ROUTE (outside shell for full-screen)
      // ================================================================

      // Audit logs screen
      GoRoute(
        path: '/audit-logs',
        name: 'auditLogs',
        builder: (context, state) => const AuditLogsScreen(),
      ),

      // ================================================================
      // SMS USAGE ROUTE (outside shell for full-screen)
      // ================================================================

      // SMS usage screen
      GoRoute(
        path: '/sms-usage',
        name: 'smsUsage',
        builder: (context, state) => const SmsUsageScreen(),
      ),

      // ================================================================
      // ANALYTICS ROUTE (outside shell for full-screen)
      // ================================================================

      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialTab = extra?['tab'] as int? ?? 0;
          return AnalyticsScreen(initialTab: initialTab);
        },
      ),

      // ================================================================
      // NOTIFICATIONS ROUTES (outside shell for full-screen)
      // ================================================================

      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      GoRoute(
        path: '/notifications/preferences',
        name: 'notificationPreferences',
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),

      // ================================================================
      // DOCUMENT REVIEW ROUTES (outside shell for full-screen)
      // ================================================================

      GoRoute(
        path: '/document-queue',
        name: 'documentQueue',
        builder: (context, state) => const DocumentQueueScreen(),
      ),

      GoRoute(
        path: '/document-review/:id',
        name: 'documentReview',
        builder: (context, state) {
          final documentId = state.pathParameters['id']!;
          final extra = state.extra;
          DocumentQueueItem? queueItem;
          if (extra is DocumentQueueItem) {
            queueItem = extra;
          }
          return DocumentReviewScreen(
            documentId: documentId,
            queueItem: queueItem,
          );
        },
      ),

      // ================================================================
      // MAIN APP SHELL WITH BOTTOM NAVIGATION
      // ================================================================
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          // Dashboard tab
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),

          // Users tab
          GoRoute(
            path: AppRoutes.users,
            name: 'users',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UsersScreen(),
            ),
          ),

          // Payments tab
          GoRoute(
            path: AppRoutes.payments,
            name: 'payments',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PaymentsScreen(),
            ),
          ),

          // Messages tab
          GoRoute(
            path: AppRoutes.messages,
            name: 'messages',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MessagesScreen(),
            ),
          ),

          // More tab
          GoRoute(
            path: AppRoutes.more,
            name: 'more',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MoreScreen(),
            ),
          ),
        ],
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Extension for easier navigation
extension GoRouterExtension on BuildContext {
  /// Navigate to a named route
  void goNamed(String name, {Map<String, String> params = const {}}) {
    GoRouter.of(this).goNamed(name, pathParameters: params);
  }

  /// Push a named route
  void pushNamed(String name, {Map<String, String> params = const {}}) {
    GoRouter.of(this).pushNamed(name, pathParameters: params);
  }

  /// Pop the current route
  void pop() {
    GoRouter.of(this).pop();
  }

  /// Check if can pop
  bool canPop() {
    return GoRouter.of(this).canPop();
  }
}

/// Extension for type-safe navigation
extension TypeSafeNavigation on BuildContext {
  // User navigation
  void goToDriverDetail(String driverId) => push(AppRoutes.driverDetailPath(driverId));
  void goToVehicleDetail(String vehicleId) => push(AppRoutes.vehicleDetailPath(vehicleId));
  void goToUserShipperDetail(String shipperId) => push(AppRoutes.userShipperDetailPath(shipperId));

  // Payment navigation
  void goToTransactionDetail(String transactionId) => push(AppRoutes.transactionDetailPath(transactionId));

  // Message navigation
  void goToConversation(String userId) => push(AppRoutes.conversationPath(userId));
  void goToComposeMessage({String? recipientId, dynamic template}) {
    push(
      AppRoutes.composeMessage,
      extra: {
        if (recipientId != null) 'recipientId': recipientId,
        if (template != null) 'template': template,
      },
    );
  }
  void goToBroadcast({dynamic template}) {
    push(
      AppRoutes.broadcast,
      extra: {
        if (template != null) 'template': template,
      },
    );
  }

  // Dispute navigation
  void goToDisputes() => push(AppRoutes.disputes);
  void goToDisputeDetail(String disputeId) => push(AppRoutes.disputeDetailPath(disputeId));

  // Shipper navigation
  void goToShippers() => push(AppRoutes.shippers);
  void goToShipperDetail(String shipperId) => push(AppRoutes.shipperDetailPath(shipperId));

  // Audit logs navigation
  void goToAuditLogs() => push(AppRoutes.auditLogs);

  // SMS usage navigation
  void goToSmsUsage() => push(AppRoutes.smsUsage);

  // Analytics navigation
  void goToAnalytics({int tab = 0}) => push(AppRoutes.analytics, extra: {'tab': tab});

  // Notifications navigation
  void goToNotifications() => push(AppRoutes.notifications);
  void goToNotificationPreferences() => push(AppRoutes.notificationPreferences);

  // Document review navigation
  void goToDocumentQueue() => push(AppRoutes.documentQueue);
  void goToDocumentReview({required String documentId, Object? extra}) =>
      push(AppRoutes.documentReviewPath(documentId), extra: extra);

  // Main tabs
  void goToDashboard() => go(AppRoutes.dashboard);
  void goToUsers() => go(AppRoutes.users);
  void goToPayments() => go(AppRoutes.payments);
  void goToMessages() => go(AppRoutes.messages);
  void goToMore() => go(AppRoutes.more);
}
