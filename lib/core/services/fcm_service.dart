import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'logger_service.dart';
import 'session_service.dart';
import 'supabase_provider.dart';

/// Data class for notification tap events used for deep-link navigation.
class NotificationTapEvent {
  final String? notificationType;
  final String? relatedId;
  final Map<String, dynamic> data;

  const NotificationTapEvent({
    this.notificationType,
    this.relatedId,
    this.data = const {},
  });
}

/// Top-level background message handler.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.messageId}');
}

/// Singleton service for Firebase Cloud Messaging.
/// Follows the ConnectivityService / StorageService pattern.
class FcmService {
  FcmService._();

  static final FcmService _instance = FcmService._();
  static FcmService get instance => _instance;

  FirebaseMessaging? _messaging;
  String? _currentToken;
  bool _initialized = false;
  SessionService? _sessionService;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool get isInitialized => _initialized;
  String? get currentToken => _currentToken;

  /// Set the session service for user ID access.
  void setSessionService(SessionService sessionService) {
    _sessionService = sessionService;
  }

  String? get _userId => _sessionService?.userId;

  final _notificationController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get notificationStream => _notificationController.stream;

  final _notificationTapController = StreamController<NotificationTapEvent>.broadcast();
  Stream<NotificationTapEvent> get notificationTapStream => _notificationTapController.stream;

  /// Initialize Firebase and FCM. Call after Firebase.initializeApp().
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _messaging = FirebaseMessaging.instance;

      // Request notification permissions
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      logDebug('FCM permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        logWarning('FCM notifications denied by user');
        _initialized = true;
        return;
      }

      // Create the notification channel (required on Android 8+)
      await _createNotificationChannel();

      // Get and register FCM token
      _currentToken = await _messaging!.getToken();
      if (_currentToken != null) {
        await _registerToken(_currentToken!);
      }

      // Listen for token refresh
      _messaging!.onTokenRefresh.listen(_handleTokenRefresh);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps (app opened from background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check for initial message (app opened from terminated state)
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      logInfo('FCM service initialized with token: ${_currentToken?.substring(0, 20)}...');
    } catch (e) {
      logError('FCM initialization failed', e);
      _initialized = true; // Mark as initialized so app continues
    }
  }

  /// Register FCM token in device_tokens table.
  Future<void> _registerToken(String token) async {
    try {
      final userId = _userId;
      if (userId == null) return;

      await SupabaseProvider().client.from('device_tokens').upsert(
        {
          'user_id': userId,
          'fcm_token': token,
          'device_name': defaultTargetPlatform.name,
          'platform': defaultTargetPlatform.name.toLowerCase(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,fcm_token',
      );
      logDebug('FCM token registered for user $userId');
    } catch (e) {
      logError('Failed to register FCM token', e);
    }
  }

  /// Create the Android notification channel and initialize local notifications.
  Future<void> _createNotificationChannel() async {
    try {
      // Initialize the local notifications plugin
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(initSettings);

      // Create the admin notification channel
      const androidChannel = AndroidNotificationChannel(
        'loadrunner_admin_notifications',
        'Admin Notifications',
        description: 'Notifications for LoadRunner Admin events',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
      logDebug('Notification channel created: loadrunner_admin_notifications');
    } catch (e) {
      logError('Failed to create notification channel', e);
    }
  }

  /// Register the current FCM token for the logged-in user.
  /// Call after login when userId becomes available.
  Future<void> registerCurrentToken() async {
    if (_currentToken != null) {
      await _registerToken(_currentToken!);
    }
  }

  /// Remove the current device token on logout.
  Future<void> removeToken() async {
    try {
      final userId = _userId;
      if (userId == null || _currentToken == null) return;

      await SupabaseProvider().client
          .from('device_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('fcm_token', _currentToken!);
      logDebug('FCM token removed for user $userId');
    } catch (e) {
      logError('Failed to remove FCM token', e);
    }
  }

  /// Handle token refresh — re-register with new token.
  Future<void> _handleTokenRefresh(String newToken) async {
    logDebug('FCM token refreshed');
    // Remove old token if we have one
    if (_currentToken != null && _currentToken != newToken) {
      try {
        final userId = _userId;
        if (userId != null) {
          await SupabaseProvider().client
              .from('device_tokens')
              .delete()
              .eq('user_id', userId)
              .eq('fcm_token', _currentToken!);
        }
      } catch (e) {
        logError('Failed to remove old FCM token', e);
      }
    }
    _currentToken = newToken;
    await _registerToken(newToken);
  }

  /// Handle foreground message — show local notification and emit to stream.
  void _handleForegroundMessage(RemoteMessage message) {
    logDebug('Foreground message: ${message.notification?.title}');
    _showLocalNotification(message);
    _notificationController.add(message);
  }

  /// Show a local notification so foreground messages are visible.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'loadrunner_admin_notifications',
        'Admin Notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
      );

      const details = NotificationDetails(android: androidDetails);

      final title = message.notification?.title ??
          message.data['title'] as String? ??
          'LoadRunner Admin';
      final body = message.notification?.body ??
          message.data['body'] as String? ??
          'New notification';

      await _localNotifications.show(
        message.hashCode,
        title,
        body,
        details,
      );
      logDebug('Local notification shown: $title');
    } catch (e) {
      logError('Failed to show local notification', e);
    }
  }

  /// Handle notification tap — extract type + related_id for navigation.
  void _handleNotificationTap(RemoteMessage message) {
    logDebug('Notification tapped: ${message.data}');
    _notificationTapController.add(
      NotificationTapEvent(
        notificationType: message.data['notification_type'] as String?,
        relatedId: message.data['related_id'] as String?,
        data: message.data,
      ),
    );
  }

  /// Dispose resources.
  void dispose() {
    _notificationController.close();
    _notificationTapController.close();
  }
}
