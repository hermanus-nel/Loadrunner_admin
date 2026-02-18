// lib/core/error/error_display.dart

import 'package:flutter/material.dart';

import 'app_exception.dart';
import 'error_handler.dart';

/// Utility class for displaying errors to users
class ErrorDisplay {
  const ErrorDisplay._();

  /// Show error as a SnackBar
  static void showSnackBar(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    final appException = error is AppException
        ? error
        : ErrorHandler.instance.handleError(error, silent: true);

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            _getIconForCategory(appException.category),
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              appException.userMessage,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: behavior,
      duration: duration,
      action: appException.isRetryable && onRetry != null
          ? SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                onRetry();
              },
            )
          : null,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Show success message as a SnackBar
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: duration,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Show warning message as a SnackBar
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: Colors.orange,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      action: onAction != null && actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                onAction();
              },
            )
          : null,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Show info message as a SnackBar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: Colors.blue,
      behavior: SnackBarBehavior.floating,
      duration: duration,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Show error as a Dialog
  static Future<void> showDialog(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
    String? title,
    bool dismissible = true,
  }) async {
    final appException = error is AppException
        ? error
        : ErrorHandler.instance.handleError(error, silent: true);

    await showAdaptiveDialog<void>(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) => ErrorDialog(
        error: appException,
        title: title,
        onRetry: onRetry,
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDangerous = false,
  }) async {
    return await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDangerous
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  static IconData _getIconForCategory(String category) {
    switch (category) {
      case 'network':
        return Icons.wifi_off;
      case 'auth':
        return Icons.lock_outline;
      case 'database':
        return Icons.storage;
      case 'validation':
        return Icons.warning_amber;
      case 'rate_limit':
        return Icons.speed;
      default:
        return Icons.error_outline;
    }
  }
}

/// Error dialog widget
class ErrorDialog extends StatelessWidget {
  final AppException error;
  final String? title;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    required this.error,
    this.title,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getIcon(),
          color: theme.colorScheme.error,
          size: 32,
        ),
      ),
      title: Text(title ?? _getTitle()),
      content: Text(
        error.userMessage,
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (error.isRetryable && onRetry != null)
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onRetry!();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          )
        else
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
      ],
    );
  }

  IconData _getIcon() {
    switch (error.category) {
      case 'network':
        return Icons.wifi_off;
      case 'auth':
        return Icons.lock_outline;
      case 'database':
        return Icons.storage;
      case 'validation':
        return Icons.warning_amber;
      case 'rate_limit':
        return Icons.hourglass_empty;
      default:
        return Icons.error_outline;
    }
  }

  String _getTitle() {
    switch (error.category) {
      case 'network':
        return 'Connection Error';
      case 'auth':
        return 'Authentication Error';
      case 'database':
        return 'Data Error';
      case 'validation':
        return 'Invalid Data';
      case 'rate_limit':
        return 'Please Wait';
      default:
        return 'Error';
    }
  }
}

/// Error banner that can be shown at the top of a screen
class ErrorBanner extends StatelessWidget {
  final AppException error;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const ErrorBanner({
    super.key,
    required this.error,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error.userMessage,
                  style: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                    fontSize: 14,
                  ),
                ),
              ),
              if (error.isRetryable && onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDismiss,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline error message for forms
class InlineErrorMessage extends StatelessWidget {
  final String message;
  final bool visible;

  const InlineErrorMessage({
    super.key,
    required this.message,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 12),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 14,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Extension Methods
// ============================================================================

/// Extension on BuildContext for easy error display
extension ErrorDisplayExtension on BuildContext {
  /// Show error as SnackBar
  void showError(Object error, {VoidCallback? onRetry}) {
    ErrorDisplay.showSnackBar(this, error, onRetry: onRetry);
  }

  /// Show success message
  void showSuccess(String message) {
    ErrorDisplay.showSuccess(this, message);
  }

  /// Show warning message
  void showWarning(String message, {VoidCallback? onAction, String? actionLabel}) {
    ErrorDisplay.showWarning(this, message, onAction: onAction, actionLabel: actionLabel);
  }

  /// Show info message
  void showInfo(String message) {
    ErrorDisplay.showInfo(this, message);
  }

  /// Show error dialog
  Future<void> showErrorDialog(Object error, {VoidCallback? onRetry, String? title}) {
    return ErrorDisplay.showDialog(this, error, onRetry: onRetry, title: title);
  }

  /// Show confirmation dialog
  Future<bool?> showConfirmation({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDangerous = false,
  }) {
    return ErrorDisplay.showConfirmation(
      this,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDangerous: isDangerous,
    );
  }
}

/// Extension for easy error handling in async operations
extension AsyncErrorHandling<T> on Future<T> {
  /// Execute with error display on failure
  Future<T?> withErrorDisplay(
    BuildContext context, {
    VoidCallback? onRetry,
    bool showDialog = false,
  }) async {
    try {
      return await this;
    } catch (error) {
      if (context.mounted) {
        if (showDialog) {
          await ErrorDisplay.showDialog(context, error, onRetry: onRetry);
        } else {
          ErrorDisplay.showSnackBar(context, error, onRetry: onRetry);
        }
      }
      return null;
    }
  }
}
