// lib/features/analytics/presentation/widgets/date_range_selector.dart

import 'package:flutter/material.dart';

import '../../domain/entities/date_range.dart';

/// A widget for selecting date ranges with presets and custom option
class DateRangeSelector extends StatelessWidget {
  final DateRange selectedRange;
  final ValueChanged<DateRange> onRangeChanged;
  final bool showLabel;

  const DateRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        if (showLabel) ...[
          Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: InkWell(
            onTap: () => _showRangeSelector(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedRange.displayText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showRangeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DateRangeBottomSheet(
        selectedRange: selectedRange,
        onRangeSelected: (range) {
          Navigator.pop(context);
          onRangeChanged(range);
        },
      ),
    );
  }
}

/// Bottom sheet for date range selection
class _DateRangeBottomSheet extends StatefulWidget {
  final DateRange selectedRange;
  final ValueChanged<DateRange> onRangeSelected;

  const _DateRangeBottomSheet({
    required this.selectedRange,
    required this.onRangeSelected,
  });

  @override
  State<_DateRangeBottomSheet> createState() => _DateRangeBottomSheetState();
}

class _DateRangeBottomSheetState extends State<_DateRangeBottomSheet> {
  late DateRangePreset _selectedPreset;
  late DateTime _customStart;
  late DateTime _customEnd;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.selectedRange.preset;
    _customStart = widget.selectedRange.startDate;
    _customEnd = widget.selectedRange.endDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Date Range',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preset options
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DateRangePreset.values
                .where((p) => p != DateRangePreset.custom)
                .map((preset) => _PresetChip(
                      preset: preset,
                      isSelected: _selectedPreset == preset,
                      onTap: () {
                        setState(() => _selectedPreset = preset);
                        widget.onRangeSelected(preset.toDateRange());
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),

          // Custom range option
          Text(
            'Custom Range',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Start and end date pickers
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: 'Start',
                  date: _customStart,
                  onDateChanged: (date) {
                    setState(() {
                      _customStart = date;
                      _selectedPreset = DateRangePreset.custom;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePickerField(
                  label: 'End',
                  date: _customEnd,
                  onDateChanged: (date) {
                    setState(() {
                      _customEnd = date;
                      _selectedPreset = DateRangePreset.custom;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Apply button for custom range
          if (_selectedPreset == DateRangePreset.custom)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onRangeSelected(DateRange(
                    startDate: _customStart,
                    endDate: _customEnd,
                    preset: DateRangePreset.custom,
                  ));
                },
                child: const Text('Apply Custom Range'),
              ),
            ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }
}

/// Preset chip widget
class _PresetChip extends StatelessWidget {
  final DateRangePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            preset.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Date picker field
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onDateChanged(picked);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(date),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Compact date range selector for tight spaces
class CompactDateRangeSelector extends StatelessWidget {
  final DateRange selectedRange;
  final ValueChanged<DateRange> onRangeChanged;

  const CompactDateRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopupMenuButton<DateRangePreset>(
      initialValue: selectedRange.preset,
      onSelected: (preset) {
        onRangeChanged(preset.toDateRange());
      },
      offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              selectedRange.displayText,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => DateRangePreset.values
          .where((p) => p != DateRangePreset.custom)
          .map((preset) => PopupMenuItem(
                value: preset,
                child: Text(preset.label),
              ))
          .toList(),
    );
  }
}
