import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class HealthTrendsChart extends StatefulWidget {
  const HealthTrendsChart({super.key});

  @override
  State<HealthTrendsChart> createState() => _HealthTrendsChartState();
}

class _HealthTrendsChartState extends State<HealthTrendsChart> {
  String _selectedMetric = 'Blood Pressure';

  final List<String> _availableMetrics = [
    'Blood Pressure',
    'Weight',
    'Blood Sugar',
    'Heart Rate',
    'Exercise Hours',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with metric selector
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Health Trends',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedMetric,
                  underline: const SizedBox.shrink(),
                  items: _availableMetrics.map((metric) {
                    return DropdownMenuItem(
                      value: metric,
                      child: Text(metric),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMetric = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Chart
          Expanded(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 4.w).copyWith(bottom: 4.w),
              child: _buildChart(),
            ),
          ),

          // Legend
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 4.w).copyWith(bottom: 2.h),
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _getHorizontalInterval(),
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.lightTheme.colorScheme.outline.withAlpha(51),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AppTheme.lightTheme.colorScheme.outline.withAlpha(51),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: _bottomTitleWidgets,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _getHorizontalInterval(),
              getTitlesWidget: _leftTitleWidgets,
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline.withAlpha(51),
          ),
        ),
        minX: 0,
        maxX: 6,
        minY: _getMinY(),
        maxY: _getMaxY(),
        lineBarsData: [
          LineChartBarData(
            spots: _getChartData(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.lightTheme.colorScheme.primary,
                AppTheme.lightTheme.colorScheme.primary.withAlpha(77),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: AppTheme.lightTheme.colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.lightTheme.colorScheme.primary.withAlpha(26),
                  AppTheme.lightTheme.colorScheme.primary.withAlpha(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppTheme.lightTheme.colorScheme.surface,
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  '${_selectedMetric}\n${touchedSpot.y.toStringAsFixed(1)}${_getUnit()}',
                  TextStyle(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          '$_selectedMetric Trend (Last 6 Months)',
          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface.withAlpha(179),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _getChartData() {
    switch (_selectedMetric) {
      case 'Blood Pressure':
        return const [
          FlSpot(0, 118),
          FlSpot(1, 122),
          FlSpot(2, 115),
          FlSpot(3, 120),
          FlSpot(4, 116),
          FlSpot(5, 118),
          FlSpot(6, 114),
        ];
      case 'Weight':
        return const [
          FlSpot(0, 76.2),
          FlSpot(1, 75.8),
          FlSpot(2, 75.5),
          FlSpot(3, 75.1),
          FlSpot(4, 74.8),
          FlSpot(5, 74.5),
          FlSpot(6, 74.2),
        ];
      case 'Blood Sugar':
        return const [
          FlSpot(0, 98),
          FlSpot(1, 102),
          FlSpot(2, 95),
          FlSpot(3, 97),
          FlSpot(4, 94),
          FlSpot(5, 96),
          FlSpot(6, 93),
        ];
      case 'Heart Rate':
        return const [
          FlSpot(0, 75),
          FlSpot(1, 73),
          FlSpot(2, 74),
          FlSpot(3, 72),
          FlSpot(4, 71),
          FlSpot(5, 73),
          FlSpot(6, 72),
        ];
      case 'Exercise Hours':
        return const [
          FlSpot(0, 3.5),
          FlSpot(1, 4.0),
          FlSpot(2, 3.8),
          FlSpot(3, 4.2),
          FlSpot(4, 4.5),
          FlSpot(5, 4.8),
          FlSpot(6, 5.0),
        ];
      default:
        return const [];
    }
  }

  double _getMinY() {
    switch (_selectedMetric) {
      case 'Blood Pressure':
        return 110;
      case 'Weight':
        return 74;
      case 'Blood Sugar':
        return 90;
      case 'Heart Rate':
        return 70;
      case 'Exercise Hours':
        return 3;
      default:
        return 0;
    }
  }

  double _getMaxY() {
    switch (_selectedMetric) {
      case 'Blood Pressure':
        return 130;
      case 'Weight':
        return 77;
      case 'Blood Sugar':
        return 105;
      case 'Heart Rate':
        return 80;
      case 'Exercise Hours':
        return 6;
      default:
        return 100;
    }
  }

  double _getHorizontalInterval() {
    switch (_selectedMetric) {
      case 'Blood Pressure':
        return 5;
      case 'Weight':
        return 1;
      case 'Blood Sugar':
        return 5;
      case 'Heart Rate':
        return 2;
      case 'Exercise Hours':
        return 1;
      default:
        return 10;
    }
  }

  String _getUnit() {
    switch (_selectedMetric) {
      case 'Blood Pressure':
        return ' mmHg';
      case 'Weight':
        return ' kg';
      case 'Blood Sugar':
        return ' mg/dL';
      case 'Heart Rate':
        return ' bpm';
      case 'Exercise Hours':
        return ' hrs';
      default:
        return '';
    }
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 10,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('Jan', style: style);
        break;
      case 1:
        text = const Text('Feb', style: style);
        break;
      case 2:
        text = const Text('Mar', style: style);
        break;
      case 3:
        text = const Text('Apr', style: style);
        break;
      case 4:
        text = const Text('May', style: style);
        break;
      case 5:
        text = const Text('Jun', style: style);
        break;
      case 6:
        text = const Text('Jul', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 10,
    );

    return Text(
      value.toInt().toString(),
      style: style,
      textAlign: TextAlign.left,
    );
  }
}
