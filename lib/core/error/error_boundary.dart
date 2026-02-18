// lib/core/error/error_boundary.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_handler.dart';
import 'app_exception.dart';

/// Error boundary widget that catches errors in its child widget tree
/// and displays a fallback UI instead of crashing
class ErrorBoundary extends ConsumerStatefulWidget {
  /// The child widget tree to wrap
  final Widget child;

  /// Optional custom fallback widget builder
  final Widget Function(BuildContext context, Object error, VoidCallback retry)? fallbackBuilder;

  /// Optional callback when an error occurs
  final void Function(Object error, StackTrace? stackTrace)? onError;

  /// Whether to show a compact error UI
  final bool compact;

  /// Screen name for error reporting
  final String? screenName;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackBuilder,
    this.onError,
    this.compact = false,
    this.screenName,
  });

  @override
  ConsumerState<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends ConsumerState<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    _setupErrorWidget();
  }

  void _setupErrorWidget() {
    // Override the error widget to catch errors in the child tree
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _handleError(details.exception, details.stack);
      return _buildErrorWidget(details.exception);
    };
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    // Report error
    ErrorHandler.instance.handleError(
      error,
      stackTrace: stackTrace,
      context: widget.screenName != null ? 'Screen: ${widget.screenName}' : null,
    );

    // Call custom error handler
    widget.onError?.call(error, stackTrace);

    // Update state to show error UI
    if (mounted) {
      setState(() {
        _error = error;
        _stackTrace = stackTrace;
      });
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  Widget _buildErrorWidget(Object error) {
    if (widget.fallbackBuilder != null) {
      return widget.fallbackBuilder!(context, error, _retry);
    }

    if (widget.compact) {
      return _CompactErrorWidget(
        error: error,
        onRetry: _retry,
      );
    }

    return _FullErrorWidget(
      error: error,
      stackTrace: _stackTrace,
      onRetry: _retry,
      screenName: widget.screenName,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget(_error!);
    }

    return widget.child;
  }
}

/// Full-screen error widget with details
class _FullErrorWidget extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback onRetry;
  final String? screenName;

  const _FullErrorWidget({
    required this.error,
    this.stackTrace,
    required this.onRetry,
    this.screenName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exception = error is AppException ? error as AppException : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 40,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Something went wrong',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // User-friendly message
              Text(
                exception?.userMessage ?? 'An unexpected error occurred.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Retry button
              if (exception?.isRetryable ?? true)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              const SizedBox(height: 12),

              // Go back button
              TextButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Go Back'),
              ),

              // Debug info (only in debug mode)
              if (screenName != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Screen: $screenName',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact error widget for use in smaller spaces
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
    final exception = error is AppException ? error as AppException : null;

    return Container(
      padding: const EdgeInsets.all(16),
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
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exception?.userMessage ?? 'An error occurred',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          if (exception?.isRetryable ?? true) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error wrapper that can be used around async operations in widgets
class AsyncErrorBoundary extends ConsumerWidget {
  final AsyncValue<dynamic> asyncValue;
  final Widget Function(dynamic data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace? stackTrace, VoidCallback retry)? error;
  final VoidCallback? onRetry;

  const AsyncErrorBoundary({
    super.key,
    required this.asyncValue,
    required this.data,
    this.loading,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncValue.when(
      data: data,
      loading: () => loading?.call() ?? const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        final retry = onRetry ?? () => ref.invalidate(asyncValue as ProviderBase);
        if (error != null) {
          return error!(err, stack, retry);
        }
        return _CompactErrorWidget(error: err, onRetry: retry);
      },
    );
  }
}

/// Mixin for StatefulWidgets to easily catch errors
mixin ErrorBoundaryMixin<T extends StatefulWidget> on State<T> {
  Object? _error;
  StackTrace? _stackTrace;

  bool get hasError => _error != null;
  Object? get currentError => _error;
  StackTrace? get currentStackTrace => _stackTrace;

  void catchError(Object error, [StackTrace? stackTrace]) {
    ErrorHandler.instance.handleError(error, stackTrace: stackTrace);
    if (mounted) {
      setState(() {
        _error = error;
        _stackTrace = stackTrace;
      });
    }
  }

  void clearError() {
    if (mounted) {
      setState(() {
        _error = null;
        _stackTrace = null;
      });
    }
  }

  /// Wrap an async operation with error handling
  Future<T?> runSafe<T>(Future<T> Function() operation) async {
    try {
      clearError();
      return await operation();
    } catch (error, stackTrace) {
      catchError(error, stackTrace);
      return null;
    }
  }

  /// Build error widget if there's an error
  Widget buildWithErrorHandling({
    required Widget Function() builder,
    Widget Function(Object error, VoidCallback retry)? errorBuilder,
  }) {
    if (hasError) {
      return errorBuilder?.call(_error!, clearError) ??
          _CompactErrorWidget(error: _error!, onRetry: clearError);
    }
    return builder();
  }
}

/// Provider for managing error state in a feature
class ErrorStateNotifier extends StateNotifier<ErrorState> {
  ErrorStateNotifier() : super(const ErrorState());

  void setError(Object error, [StackTrace? stackTrace]) {
    final appException = ErrorHandler.instance.handleError(
      error,
      stackTrace: stackTrace,
      silent: true,
    );
    state = ErrorState(error: appException, stackTrace: stackTrace);
  }

  void clearError() {
    state = const ErrorState();
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

class ErrorState {
  final AppException? error;
  final StackTrace? stackTrace;
  final bool isLoading;

  const ErrorState({
    this.error,
    this.stackTrace,
    this.isLoading = false,
  });

  bool get hasError => error != null;

  ErrorState copyWith({
    AppException? error,
    StackTrace? stackTrace,
    bool? isLoading,
    bool clearError = false,
  }) {
    return ErrorState(
      error: clearError ? null : (error ?? this.error),
      stackTrace: clearError ? null : (stackTrace ?? this.stackTrace),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
