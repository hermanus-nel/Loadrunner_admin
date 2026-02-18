// lib/core/components/loading_state.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_exception.dart';
import '../error/error_display.dart';
import 'empty_state.dart';

/// A wrapper widget that handles loading, error, and empty states
class LoadingStateWidget<T> extends StatelessWidget {
  /// The data to display
  final T? data;
  
  /// Whether data is currently loading
  final bool isLoading;
  
  /// Error if any
  final Object? error;
  
  /// Callback to retry loading
  final VoidCallback? onRetry;
  
  /// Builder for the success state
  final Widget Function(T data) builder;
  
  /// Custom loading widget
  final Widget? loadingWidget;
  
  /// Custom error widget builder
  final Widget Function(Object error, VoidCallback? retry)? errorBuilder;
  
  /// Custom empty state widget
  final Widget? emptyWidget;
  
  /// Check if data is empty (for showing empty state)
  final bool Function(T data)? isEmpty;

  const LoadingStateWidget({
    super.key,
    required this.data,
    required this.isLoading,
    this.error,
    this.onRetry,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.emptyWidget,
    this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (isLoading && data == null) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (error != null && data == null) {
      if (errorBuilder != null) {
        return errorBuilder!(error!, onRetry);
      }
      return _DefaultErrorWidget(
        error: error!,
        onRetry: onRetry,
      );
    }

    // Empty state
    if (data == null || (isEmpty != null && isEmpty!(data as T))) {
      return emptyWidget ?? EmptyState.noData();
    }

    // Success state (may still show loading indicator for refresh)
    return Stack(
      children: [
        builder(data as T),
        if (isLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
          ),
      ],
    );
  }
}

/// Widget for handling AsyncValue states from Riverpod
class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> asyncValue;
  final Widget Function(T data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace? stack)? error;
  final VoidCallback? onRetry;
  final Widget? emptyWidget;
  final bool Function(T data)? isEmpty;

  const AsyncValueWidget({
    super.key,
    required this.asyncValue,
    required this.data,
    this.loading,
    this.error,
    this.onRetry,
    this.emptyWidget,
    this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (value) {
        if (isEmpty != null && isEmpty!(value)) {
          return emptyWidget ?? EmptyState.noData();
        }
        return data(value);
      },
      loading: () => loading?.call() ?? const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        if (error != null) {
          return error!(err, stack);
        }
        return _DefaultErrorWidget(
          error: err,
          onRetry: onRetry,
        );
      },
    );
  }
}

/// Loading overlay that shows on top of content
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.3),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(message!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Button with loading state
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? loadingChild;
  final ButtonStyle? style;
  final bool filled;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
    this.loadingChild,
    this.style,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveChild = isLoading
        ? loadingChild ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: filled
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Loading...'),
              ],
            )
        : child;

    if (filled) {
      return FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: effectiveChild,
      );
    }

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: effectiveChild,
    );
  }
}

/// Icon button with loading state
class LoadingIconButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;

  const LoadingIconButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isLoading ? null : onPressed,
      tooltip: tooltip,
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : icon,
    );
  }
}

/// Pull to refresh wrapper with error handling
class RefreshableContent<T> extends StatelessWidget {
  final T? data;
  final bool isLoading;
  final Object? error;
  final Future<void> Function() onRefresh;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final bool Function(T data)? isEmpty;

  const RefreshableContent({
    super.key,
    required this.data,
    required this.isLoading,
    this.error,
    required this.onRefresh,
    required this.builder,
    this.loadingWidget,
    this.emptyWidget,
    this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    // Initial loading
    if (isLoading && data == null && error == null) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    // Error with no data
    if (error != null && data == null) {
      return _DefaultErrorWidget(
        error: error!,
        onRetry: onRefresh,
      );
    }

    // Empty state
    if (data == null || (isEmpty != null && isEmpty!(data as T))) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: emptyWidget ?? EmptyState.noData(),
          ),
        ),
      );
    }

    // Success state with refresh capability
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: builder(data as T),
    );
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const _DefaultErrorWidget({
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAppException = error is AppException;
    final appException = isAppException ? error as AppException : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appException?.userMessage ?? 'An unexpected error occurred.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null && (appException?.isRetryable ?? true)) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for loading states
class ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerPlaceholder({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                theme.colorScheme.surfaceContainerHighest,
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                theme.colorScheme.surfaceContainerHighest,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Card shimmer placeholder
class ShimmerCard extends StatelessWidget {
  final double height;

  const ShimmerCard({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ShimmerPlaceholder(
              width: 56,
              height: 56,
              borderRadius: BorderRadius.circular(28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerPlaceholder(
                    width: 150,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  ShimmerPlaceholder(
                    width: 100,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List shimmer placeholder
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets padding;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerCard(height: itemHeight),
        );
      },
    );
  }
}
