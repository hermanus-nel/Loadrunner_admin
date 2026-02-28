// lib/main.dart
// LoadRunner Admin Dashboard entry point
// Adapted from main LoadRunner app's initialization pattern

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/error/error_boundary.dart';
import 'core/error/error_handler.dart';
import 'core/navigation/app_router.dart';
import 'core/services/bulksms_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/core_providers.dart';
import 'core/services/fcm_service.dart';
import 'core/services/jwt_recovery_handler.dart';
import 'core/services/logger_service.dart';
import 'core/services/session_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/supabase_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_config.dart';

/// Application entry point
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  debugPrint('Firebase initialized');

  // Initialize configuration
  await AppConfig.initialize();

  // Initialize global error handler
  ErrorHandler.instance.initialize();

  // Initialize logger
  LoggerService.instance.initialize();
  debugPrint('🚀 Starting LoadRunner Admin Dashboard...');

  // Initialize storage
  await StorageService.instance.initialize();
  debugPrint('✅ Storage initialized');

  // Initialize connectivity monitoring
  await ConnectivityService.instance.initialize();
  debugPrint('✅ Connectivity service initialized');

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Supabase
  if (!AppConfig.instance.isSupabaseConfigured) {
    debugPrint('⚠️ Supabase not configured - check .env file');
    runApp(const _ConfigurationErrorApp());
    return;
  }

  await Supabase.initialize(
    url: AppConfig.instance.supabaseUrl,
    anonKey: AppConfig.instance.supabaseAnonKey,
  );
  debugPrint('✅ Supabase initialized');

  // Initialize SessionService
  final sessionService = SessionService(
    supabaseClient: Supabase.instance.client,
    edgeFunctionUrl: '${AppConfig.instance.supabaseUrl}/functions/v1/auth-handler',
    apiKey: AppConfig.instance.supabaseAnonKey,
    prefs: prefs,
  );
  await sessionService.initialize();
  debugPrint('✅ SessionService initialized');

  // Initialize FCM service (after SessionService, needs userId for token registration)
  FcmService.instance.setSessionService(sessionService);
  await FcmService.instance.initialize();
  debugPrint('✅ FCM service initialized');

  // Initialize SupabaseProvider
  final supabaseProvider = SupabaseProvider();
  supabaseProvider.initialize();
  supabaseProvider.setSessionService(sessionService);
  debugPrint('✅ SupabaseProvider initialized');

  // Initialize JwtRecoveryHandler
  final jwtHandler = JwtRecoveryHandler();
  jwtHandler.initialize(
    sessionService: sessionService,
    supabaseProvider: supabaseProvider,
  );
  debugPrint('✅ JwtRecoveryHandler initialized');

  // Initialize BulkSmsService
  if (!AppConfig.instance.isBulkSmsConfigured) {
    debugPrint('⚠️ BulkSMS not configured - check .env file');
    runApp(const _ConfigurationErrorApp(message: 'BulkSMS credentials not configured.'));
    return;
  }

  final bulkSmsService = BulkSmsService(
    username: AppConfig.instance.bulkSmsUsername,
    password: AppConfig.instance.bulkSmsPassword,
  );
  debugPrint('✅ BulkSmsService initialized');

  // Set preferred orientations (portrait only for mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  debugPrint('✅ App initialization complete');

  runApp(
    ProviderScope(
      overrides: [
        // Override providers with initialized instances
        sessionServiceProvider.overrideWithValue(sessionService),
        supabaseProviderInstance.overrideWithValue(supabaseProvider),
        jwtRecoveryHandlerProvider.overrideWithValue(jwtHandler),
        bulkSmsServiceProvider.overrideWithValue(bulkSmsService),
      ],
      child: const LoadRunnerAdminApp(),
    ),
  );
}

/// Main application widget for LoadRunner Admin Dashboard
class LoadRunnerAdminApp extends ConsumerStatefulWidget {
  const LoadRunnerAdminApp({super.key});

  @override
  ConsumerState<LoadRunnerAdminApp> createState() => _LoadRunnerAdminAppState();
}

class _LoadRunnerAdminAppState extends ConsumerState<LoadRunnerAdminApp> {
  StreamSubscription<NotificationTapEvent>? _tapSubscription;

  @override
  void initState() {
    super.initState();
    _tapSubscription = FcmService.instance.notificationTapStream.listen(
      _handleNotificationTap,
    );
  }

  @override
  void dispose() {
    _tapSubscription?.cancel();
    super.dispose();
  }

  void _handleNotificationTap(NotificationTapEvent event) {
    final router = ref.read(appRouterProvider);
    final type = event.notificationType;
    final relatedId = event.relatedId;

    if (type == null) {
      router.go(AppRoutes.notifications);
      return;
    }

    switch (type) {
      case 'dispute_lodged':
      case 'dispute_escalated':
      case 'dispute_resolved':
        if (relatedId != null) {
          router.go(AppRoutes.disputeDetailPath(relatedId));
        } else {
          router.go(AppRoutes.disputes);
        }
      case 'new_user':
      case 'driver_registered':
      case 'driver_document_uploaded':
      case 'driver_suspended':
        if (relatedId != null) {
          router.go(AppRoutes.driverDetailPath(relatedId));
        } else {
          router.go(AppRoutes.users);
        }
      case 'payment_completed':
      case 'driver_payout':
        if (relatedId != null) {
          router.go(AppRoutes.transactionDetailPath(relatedId));
        } else {
          router.go(AppRoutes.payments);
        }
      case 'new_shipment':
        router.go(AppRoutes.dashboard);
      default:
        router.go(AppRoutes.notifications);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'LoadRunner Admin',
      debugShowCheckedModeBanner: !AppConfig.instance.isProduction,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Router configuration
      routerConfig: router,

      // Wrap all screens with ErrorBoundary for render error catching
      builder: (context, child) {
        return ErrorBoundary(
          screenName: 'App',
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Configuration error app - shown when .env is not properly configured
class _ConfigurationErrorApp extends StatelessWidget {
  final String? message;

  const _ConfigurationErrorApp({this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Configuration Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message ?? 'Please check your .env file and ensure all required environment variables are set.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Required environment variables:\n'
                  '• SUPABASE_URL\n'
                  '• SUPABASE_ANONKEY\n'
                  '• BULKSMS_USERNAME\n'
                  '• BULKSMS_PASSWORD',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
