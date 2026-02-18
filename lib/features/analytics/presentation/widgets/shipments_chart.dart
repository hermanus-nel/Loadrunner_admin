// lib/features/analytics/presentation/widgets/shipments_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/activity_metrics.dart';

/// Bar chart showing shipments by day with per-status stacked bars
class ShipmentsBarChart extends StatelessWidget {
  final List<DailyShipments> data;

  const ShipmentsBarChart({
    super.key,
    required this.data,
  });

  static const List<String> _statusLabels = [
    'Bidding',
    'Pickup',
    'On Route',
    'Delivered',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _EmptyChart(message: 'No shipment data');
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColors = AppColors.shipmentStatusChartColors(theme.brightness);

    // Calculate max Y
    double maxY = 0;
    for (final day in data) {
      if (day.count > maxY) maxY = day.count.toDouble();
    }
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY == 0) maxY = 10;

    return Column(
      children: [
        // Legend
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: List.generate(_statusLabels.length, (i) {
              return _LegendItem(
                color: statusColors[i],
                label: _statusLabels[i],
              );
            }),
          ),
        ),

        // Chart
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final day = data[groupIndex];
                    return BarTooltipItem(
                      '${_formatDate(day.date)}\n',
                      TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: 'Bidding: ${day.bidding}\n',
                          style: TextStyle(
                            color: statusColors[0],
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: 'Pickup: ${day.pickup}\n',
                          style: TextStyle(
                            color: statusColors[1],
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: 'On Route: ${day.onRoute}\n',
                          style: TextStyle(
                            color: statusColors[2],
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: 'Delivered: ${day.delivered}\n',
                          style: TextStyle(
                            color: statusColors[3],
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: 'Cancelled: ${day.cancelled}',
                          style: TextStyle(
                            color: statusColors[4],
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        value.toInt().toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) return const SizedBox();
                      // Only show some labels if too many
                      if (data.length > 10 && index % 2 != 0) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _formatDateShort(data[index].date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                final counts = [
                  day.bidding,
                  day.pickup,
                  day.onRoute,
                  day.delivered,
                  day.cancelled,
                ];

                // Build stacked segments
                final stackItems = <BarChartRodStackItem>[];
                double fromY = 0;
                for (var i = 0; i < counts.length; i++) {
                  if (counts[i] > 0) {
                    final toY = fromY + counts[i].toDouble();
                    stackItems.add(
                      BarChartRodStackItem(fromY, toY, statusColors[i]),
                    );
                    fromY = toY;
                  }
                }

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: day.count.toDouble(),
                      width: data.length > 15 ? 8 : 16,
                      color: Colors.transparent,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      rodStackItems: stackItems,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

/// Pie/donut chart showing shipments by status
class ShipmentsByStatusChart extends StatefulWidget {
  final ShipmentsByStatus data;

  const ShipmentsByStatusChart({
    super.key,
    required this.data,
  });

  @override
  State<ShipmentsByStatusChart> createState() => _ShipmentsByStatusChartState();
}

class _ShipmentsByStatusChartState extends State<ShipmentsByStatusChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.total == 0) {
      return const _EmptyChart(message: 'No shipment data');
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chartData = widget.data.toChartData();
    final statusColors = AppColors.shipmentStatusChartColors(theme.brightness);

    return Row(
      children: [
        // Pie chart
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: chartData.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isTouched = index == touchedIndex;
                final radius = isTouched ? 60.0 : 50.0;
                final color = index < statusColors.length
                    ? statusColors[index]
                    : Color(item.color);

                return PieChartSectionData(
                  value: item.value.toDouble(),
                  title: isTouched ? item.value.toString() : '',
                  color: color,
                  radius: radius,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList(),
              centerSpaceRadius: 25,
              sectionsSpace: 2,
            ),
          ),
        ),

        // Legend
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: chartData.asMap().entries
                .where((entry) => entry.value.value > 0)
                .map((entry) {
              final index = entry.key;
              final item = entry.value;
              final color = index < statusColors.length
                  ? statusColors[index]
                  : Color(item.color);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${item.label} (${item.value.toInt()})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Daily active users line chart
class ActiveUsersChart extends StatelessWidget {
  final List<DailyActiveUsers> data;
  final Color totalColor;
  final Color driversColor;
  final Color shippersColor;

  const ActiveUsersChart({
    super.key,
    required this.data,
    this.totalColor = const Color(0xFF9C27B0),
    this.driversColor = const Color(0xFF2196F3),
    this.shippersColor = const Color(0xFFFF9800),
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _EmptyChart(message: 'No user activity data');
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate max Y
    double maxY = 0;
    for (final day in data) {
      if (day.totalUsers > maxY) maxY = day.totalUsers.toDouble();
    }
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY == 0) maxY = 100;

    // Prepare spots
    final totalSpots = <FlSpot>[];
    final driverSpots = <FlSpot>[];
    final shipperSpots = <FlSpot>[];

    for (var i = 0; i < data.length; i++) {
      totalSpots.add(FlSpot(i.toDouble(), data[i].totalUsers.toDouble()));
      driverSpots.add(FlSpot(i.toDouble(), data[i].drivers.toDouble()));
      shipperSpots.add(FlSpot(i.toDouble(), data[i].shippers.toDouble()));
    }

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: totalColor, label: 'Total'),
            const SizedBox(width: 16),
            _LegendItem(color: driversColor, label: 'Drivers'),
            const SizedBox(width: 16),
            _LegendItem(color: shippersColor, label: 'Shippers'),
          ],
        ),
        const SizedBox(height: 16),

        // Chart
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        value.toInt().toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: data.length > 7 ? 2 : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${data[index].date.day}/${data[index].date.month}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              lineBarsData: [
                _createLine(totalSpots, totalColor, true),
                _createLine(driverSpots, driversColor, false),
                _createLine(shipperSpots, shippersColor, false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _createLine(List<FlSpot> spots, Color color, bool isPrimary) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: isPrimary ? 3 : 2,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: isPrimary
          ? BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.0),
                ],
              ),
            )
          : BarAreaData(show: false),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Empty chart placeholder
class _EmptyChart extends StatelessWidget {
  final String message;

  const _EmptyChart({this.message = 'No data'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 40,
            color: colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
