import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';

/// Reusable button with primary, secondary, outline, and text variants.
enum ButtonVariant { primary, secondary, outline, text, destructive }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? height;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonHeight = height ?? AppDimensions.buttonHeightMd;

    Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _foregroundColor(theme),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppDimensions.iconSm),
                const SizedBox(width: AppDimensions.spacingXs),
              ],
              Text(label),
            ],
          );

    final button = switch (variant) {
      ButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      ButtonVariant.secondary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
          ),
          child: child,
        ),
      ButtonVariant.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      ButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      ButtonVariant.destructive => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: child,
        ),
    };

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: buttonHeight,
      child: button,
    );
  }

  Color _foregroundColor(ThemeData theme) {
    return switch (variant) {
      ButtonVariant.primary => theme.colorScheme.onPrimary,
      ButtonVariant.secondary => theme.colorScheme.onSecondary,
      ButtonVariant.outline => theme.colorScheme.primary,
      ButtonVariant.text => theme.colorScheme.primary,
      ButtonVariant.destructive => theme.colorScheme.onError,
    };
  }
}
