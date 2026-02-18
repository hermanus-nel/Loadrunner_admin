// lib/features/analytics/presentation/widgets/revenue_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../domain/entities/financial_metrics.dart';

/// Line chart showing revenue over time
class RevenueChart extends StatelessWidget {
  final List<DailyRevenue> data;
  final bool showCommission;
  final Color revenueColor;
  final Color commissionColor;

  const RevenueChart({
    super.key,
    required this.data,
    this.showCommission = false,
    this.revenueColor = const Color(0xFF4CAF50),
    this.commissionColor = const Color(0xFF2196F3),
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _EmptyChart(message: 'No revenue data');
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Prepare data points
    final revenueSpots = <FlSpot>[];
    final commissionSpots = <FlSpot>[];
    double maxY = 0;

    for (var i = 0; i < data.length; i++) {
      revenueSpots.add(FlSpot(i.toDouble(), data[i].revenue));
      commissionSpots.add(FlSpot(i.toDouble(), data[i].commission));
      if (data[i].revenue > maxY) maxY = data[i].revenue;
      if (showCommission && data[i].commission > maxY) maxY = data[i].commission;
    }

    // Add padding to max
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 1000;

    return LineChart(
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
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  _formatCurrency(value),
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
              interval: _getXInterval(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatDate(data[index].date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
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
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final isCommission = spot.barIndex == 1;
              return LineTooltipItem(
                'R${spot.y.toStringAsFixed(0)}',
                TextStyle(
                  color: isCommission ? commissionColor : revenueColor,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          // Revenue line
          LineChartBarData(
            spots: revenueSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: revenueColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: data.length <= 14,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: revenueColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  revenueColor.withOpacity(0.3),
                  revenueColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
          // Commission line (if enabled)
          if (showCommission)
            LineChartBarData(
              spots: commissionSpots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: commissionColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              dashArray: [5, 3],
            ),
        ],
      ),
    );
  }

  double _getXInterval() {
    if (data.length <= 7) return 1;
    if (data.length <= 14) return 2;
    if (data.length <= 30) return 5;
    return 7;
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) return 'R${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'R${(value / 1000).toStringAsFixed(0)}K';
    return 'R${value.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

/// Pie chart showing payments by status
class PaymentsPieChart extends StatefulWidget {
  final PaymentsByStatus data;

  const PaymentsPieChart({
    super.key,
    required this.data,
  });

  @override
  State<PaymentsPieChart> createState() => _PaymentsPieChartState();
}

class _PaymentsPieChartState extends State<PaymentsPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.total == 0) {
      return const _EmptyChart(message: 'No payment data');
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chartData = widget.data.toPieChartData();

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

                return PieChartSectionData(
                  value: item.value,
                  title: isTouched ? '${item.percentage.toStringAsFixed(1)}%' : '',
                  color: Color(item.color),
                  radius: radius,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList(),
              centerSpaceRadius: 30,
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
            children: chartData.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(item.color),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
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
            Icons.show_chart_outlined,
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
