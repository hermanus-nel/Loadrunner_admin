// lib/core/error/network_error_widget.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_exception.dart';
import 'error_handler.dart';

// ============================================================================
// Connectivity Service
// ============================================================================

/// Service to monitor network connectivity
class ConnectivityService {
  static ConnectivityService? _instance;
  static ConnectivityService get instance => _instance ??= ConnectivityService._();

  ConnectivityService._();

  final _connectivityController = StreamController<ConnectivityStatus>.broadcast();
  
  Stream<ConnectivityStatus> get connectivityStream => _connectivityController.stream;
  
  ConnectivityStatus _lastStatus = ConnectivityStatus.online;
  ConnectivityStatus get currentStatus => _lastStatus;
  
  Timer? _checkTimer;
  bool _isInitialized = false;

  /// List of pending actions to execute when back online
  final List<PendingAction> _pendingActions = [];

  /// Initialize connectivity monitoring
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    // Initial check
    checkConnectivity();

    // Periodic connectivity checks
    _checkTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => checkConnectivity(),
    );

    debugPrint('📡 ConnectivityService initialized');
  }

  /// Check current connectivity status
  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _updateStatus(ConnectivityStatus.online);
        return ConnectivityStatus.online;
      }
    } on SocketException catch (_) {
      _updateStatus(ConnectivityStatus.offline);
      return ConnectivityStatus.offline;
    } on TimeoutException catch (_) {
      _updateStatus(ConnectivityStatus.unstable);
      return ConnectivityStatus.unstable;
    } catch (_) {
      _updateStatus(ConnectivityStatus.offline);
      return ConnectivityStatus.offline;
    }

    _updateStatus(ConnectivityStatus.offline);
    return ConnectivityStatus.offline;
  }

  void _updateStatus(ConnectivityStatus status) {
    if (_lastStatus != status) {
      final wasOffline = _lastStatus == ConnectivityStatus.offline;
      _lastStatus = status;
      _connectivityController.add(status);

      debugPrint('📡 Connectivity changed: $status');

      // If we just came back online, process pending actions
      if (wasOffline && status == ConnectivityStatus.online) {
        _processPendingActions();
      }
    }
  }

  /// Add an action to be executed when back online
  void addPendingAction(PendingAction action) {
    _pendingActions.add(action);
    debugPrint('📋 Added pending action: ${action.name}');
  }

  /// Remove a pending action
  void removePendingAction(String id) {
    _pendingActions.removeWhere((a) => a.id == id);
  }

  /// Get pending actions count
  int get pendingActionsCount => _pendingActions.length;

  /// Process pending actions when back online
  void _processPendingActions() {
    if (_pendingActions.isEmpty) return;

    debugPrint('🔄 Processing ${_pendingActions.length} pending actions...');

    final actionsToProcess = List<PendingAction>.from(_pendingActions);
    _pendingActions.clear();

    for (final action in actionsToProcess) {
      try {
        action.execute();
        debugPrint('✅ Executed pending action: ${action.name}');
      } catch (e) {
        debugPrint('❌ Failed to execute pending action ${action.name}: $e');
        // Re-add failed actions for retry
        if (action.retryCount < action.maxRetries) {
          _pendingActions.add(action.copyWithIncrementedRetry());
        }
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _checkTimer?.cancel();
    _connectivityController.close();
    _pendingActions.clear();
    _isInitialized = false;
  }
}

/// Connectivity status
enum ConnectivityStatus {
  online,
  offline,
  unstable,
}

/// Pending action to be executed when back online
class PendingAction {
  final String id;
  final String name;
  final Future<void> Function() execute;
  final int retryCount;
  final int maxRetries;
  final DateTime createdAt;

  PendingAction({
    required this.id,
    required this.name,
    required this.execute,
    this.retryCount = 0,
    this.maxRetries = 3,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  PendingAction copyWithIncrementedRetry() {
    return PendingAction(
      id: id,
      name: name,
      execute: execute,
      retryCount: retryCount + 1,
      maxRetries: maxRetries,
      createdAt: createdAt,
    );
  }
}

// ============================================================================
// Riverpod Providers
// ============================================================================

/// Provider for ConnectivityService
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

/// Stream provider for connectivity status
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  service.initialize();
  return service.connectivityStream;
});

/// Provider for current connectivity status
final currentConnectivityProvider = Provider<ConnectivityStatus>((ref) {
  final asyncStatus = ref.watch(connectivityStatusProvider);
  return asyncStatus.valueOrNull ?? ConnectivityService.instance.currentStatus;
});

/// Provider for checking if online
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(currentConnectivityProvider);
  return status == ConnectivityStatus.online;
});

/// Provider for pending actions count
final pendingActionsCountProvider = Provider<int>((ref) {
  // Watch connectivity to refresh when status changes
  ref.watch(connectivityStatusProvider);
  return ConnectivityService.instance.pendingActionsCount;
});

// ============================================================================
// Widgets
// ============================================================================

/// Offline indicator banner
class OfflineBanner extends ConsumerWidget {
  final Widget child;

  const OfflineBanner({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(currentConnectivityProvider);
    final pendingCount = ref.watch(pendingActionsCountProvider);

    return Column(
      children: [
        if (status != ConnectivityStatus.online)
          _OfflineIndicator(
            status: status,
            pendingActionsCount: pendingCount,
          ),
        Expanded(child: child),
      ],
    );
  }
}

class _OfflineIndicator extends StatelessWidget {
  final ConnectivityStatus status;
  final int pendingActionsCount;

  const _OfflineIndicator({
    required this.status,
    required this.pendingActionsCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: status == ConnectivityStatus.offline
          ? theme.colorScheme.error
          : Colors.orange,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                status == ConnectivityStatus.offline
                    ? Icons.wifi_off
                    : Icons.wifi_tethering,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status == ConnectivityStatus.offline
                      ? 'No internet connection'
                      : 'Unstable connection',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (pendingActionsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pendingActionsCount pending',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Network error widget with retry functionality
class NetworkErrorWidget extends StatelessWidget {
  final Object? error;
  final VoidCallback? onRetry;
  final String? title;
  final String? message;
  final bool compact;
  final bool showOfflineIndicator;

  const NetworkErrorWidget({
    super.key,
    this.error,
    this.onRetry,
    this.title,
    this.message,
    this.compact = false,
    this.showOfflineIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final isNetworkError = error is NetworkException;
    final networkError = isNetworkError ? error as NetworkException : null;

    final effectiveTitle = title ??
        (networkError?.isOffline == true
            ? 'No Internet Connection'
            : networkError?.isTimeout == true
                ? 'Connection Timeout'
                : 'Network Error');

    final effectiveMessage = message ??
        (error is AppException
            ? (error as AppException).userMessage
            : 'Please check your internet connection and try again.');

    if (compact) {
      return _buildCompact(context, effectiveTitle, effectiveMessage);
    }

    return _buildFull(context, effectiveTitle, effectiveMessage, networkError);
  }

  Widget _buildCompact(BuildContext context, String title, String message) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.wifi_off,
                color: theme.colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFull(
    BuildContext context,
    String title,
    String message,
    NetworkException? networkError,
  ) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                networkError?.isOffline == true
                    ? Icons.wifi_off
                    : networkError?.isTimeout == true
                        ? Icons.hourglass_empty
                        : Icons.cloud_off,
                size: 48,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Retry button
            if (onRetry != null)
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),

            // Check connectivity button
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                final status = await ConnectivityService.instance.checkConnectivity();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        status == ConnectivityStatus.online
                            ? 'Connected! Try again.'
                            : 'Still offline. Please check your connection.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Check Connection'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Retry wrapper widget
class RetryableWidget extends StatefulWidget {
  final Future<Widget> Function() builder;
  final Widget? loadingWidget;
  final Widget Function(Object error, VoidCallback retry)? errorBuilder;

  const RetryableWidget({
    super.key,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
  });

  @override
  State<RetryableWidget> createState() => _RetryableWidgetState();
}

class _RetryableWidgetState extends State<RetryableWidget> {
  late Future<Widget> _future;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  void _loadContent() {
    _future = widget.builder();
  }

  void _retry() {
    setState(() {
      _loadContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingWidget ?? const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final error = snapshot.error!;
          if (widget.errorBuilder != null) {
            return widget.errorBuilder!(error, _retry);
          }

          if (error is NetworkException) {
            return NetworkErrorWidget(
              error: error,
              onRetry: _retry,
            );
          }

          return _CompactErrorWidget(
            error: error,
            onRetry: _retry,
          );
        }

        return snapshot.data ?? const SizedBox.shrink();
      },
    );
  }
}

class _CompactErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _CompactErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = error is AppException
        ? (error as AppException).userMessage
        : 'An error occurred';

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
