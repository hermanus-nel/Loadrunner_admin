// lib/features/users/presentation/widgets/search_header.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

/// Search header with search input and optional filter button
class SearchHeader extends StatefulWidget {
  final String hintText;
  final String initialValue;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onFilterTap;
  final bool showFilter;
  final bool hasActiveFilters;

  const SearchHeader({
    super.key,
    this.hintText = 'Search...',
    this.initialValue = '',
    required this.onSearchChanged,
    this.onFilterTap,
    this.showFilter = false,
    this.hasActiveFilters = false,
  });

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(SearchHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearchChanged('');
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.borderDark
                : AppColors.borderLight,
            width: AppDimensions.borderWidth,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMd,
                  vertical: AppDimensions.spacingSm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    width: AppDimensions.borderWidth,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          if (widget.showFilter) ...[
            const SizedBox(width: AppDimensions.spacingSm),
            _FilterButton(
              onTap: widget.onFilterTap,
              hasActiveFilters: widget.hasActiveFilters,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool hasActiveFilters;

  const _FilterButton({
    this.onTap,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Material(
          color: isDark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.spacingSm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: hasActiveFilters
                      ? Theme.of(context).colorScheme.primary
                      : (isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight),
                  width: AppDimensions.borderWidth,
                ),
              ),
              child: Icon(
                Icons.tune,
                size: 20,
                color: hasActiveFilters
                    ? Theme.of(context).colorScheme.primary
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
            ),
          ),
        ),
        if (hasActiveFilters)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

/// Simple search field without header styling
class SearchField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const SearchField({
    super.key,
    this.hintText = 'Search...',
    this.controller,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: controller != null && controller!.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                },
              )
            : null,
        filled: true,
        fillColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
