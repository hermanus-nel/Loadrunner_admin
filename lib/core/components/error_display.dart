import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';

/// Error message widget with optional retry button.
/// Use this as a visual component within screens to display error states.
class ErrorDisplayWidget extends StatelessWidget {
  final String message;
  final String? details;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryLabel;

  const ErrorDisplayWidget({
    super.key,
    required this.message,
    this.details,
    this.icon = Icons.error_outline,
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppDimensions.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppDimensions.iconXxl,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                details!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spacingLg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: AppDimensions.iconSm),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
