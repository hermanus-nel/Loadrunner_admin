import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';

/// Consistent loading indicator used across the app.
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final double strokeWidth;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 36.0,
    this.strokeWidth = 3.0,
    this.color,
  });

  /// Full-screen centered loading indicator.
  const LoadingIndicator.fullScreen({
    super.key,
    this.message,
  })  : size = 48.0,
        strokeWidth = 3.5,
        color = null;

  /// Inline compact loading indicator.
  const LoadingIndicator.inline({
    super.key,
    this.color,
  })  : message = null,
        size = 20.0,
        strokeWidth = 2.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.colorScheme.primary;

    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: indicatorColor,
      ),
    );

    if (message == null) {
      return Center(child: indicator);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
