import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';

/// Consistent search input widget used across feature screens.
class AdminSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final Widget? trailing;
  final bool autofocus;

  const AdminSearchBar({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.trailing,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText =
        controller != null && controller!.text.isNotEmpty;

    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: AppDimensions.iconSm),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasText)
              IconButton(
                icon: const Icon(Icons.clear, size: AppDimensions.iconSm),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                  onChanged?.call('');
                },
              ),
            if (trailing != null) trailing!,
          ],
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusSm,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusSm,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusSm,
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: AppDimensions.borderWidthMd,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
      ),
    );
  }
}
