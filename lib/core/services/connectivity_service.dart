import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logger_service.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService _instance = ConnectivityService._();
  static ConnectivityService get instance => _instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (error) {
        logError('Connectivity error', error);
      },
    );

    logDebug('Connectivity service initialized');
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;

    // Consider connected if any network is available
    _isConnected = results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);

    if (wasConnected != _isConnected) {
      logInfo('Connectivity changed: ${_isConnected ? 'Online' : 'Offline'}');
      _connectivityController.add(_isConnected);
    }
  }

  /// Check if connected to WiFi
  Future<bool> isOnWifi() async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  /// Check if connected to mobile data
  Future<bool> isOnMobileData() async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.mobile);
  }

  /// Get current connection type
  Future<String> getConnectionType() async {
    final results = await _connectivity.checkConnectivity();

    if (results.contains(ConnectivityResult.wifi)) {
      return 'WiFi';
    } else if (results.contains(ConnectivityResult.mobile)) {
      return 'Mobile Data';
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    } else if (results.contains(ConnectivityResult.vpn)) {
      return 'VPN';
    } else if (results.contains(ConnectivityResult.bluetooth)) {
      return 'Bluetooth';
    } else if (results.contains(ConnectivityResult.other)) {
      return 'Other';
    }

    return 'None';
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}

/// Provider for connectivity status
final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityService.instance.connectivityStream;
});

/// Provider to check if currently connected
final isConnectedProvider = Provider<bool>((ref) {
  return ConnectivityService.instance.isConnected;
});
