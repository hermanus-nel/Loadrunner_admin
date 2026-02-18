import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';

/// Information display card for showing key-value details.
class InfoCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final List<InfoCardItem> items;
  final Widget? trailing;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    this.title,
    this.icon,
    required this.items,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimensions.borderRadiusMd,
        child: Padding(
          padding: AppDimensions.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: AppDimensions.iconSm,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppDimensions.spacingXs),
                    ],
                    Expanded(
                      child: Text(
                        title!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                const Divider(height: 1),
                const SizedBox(height: AppDimensions.spacingSm),
              ],
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(
                        bottom: AppDimensions.spacingXs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            item.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        Expanded(
                          child: item.widget ??
                              Text(
                                item.value ?? '-',
                                style: theme.textTheme.bodyMedium,
                              ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single item in an InfoCard.
class InfoCardItem {
  final String label;
  final String? value;
  final Widget? widget;

  const InfoCardItem({
    required this.label,
    this.value,
    this.widget,
  });
}
