import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class HealthTrendsCard extends StatefulWidget {
  const HealthTrendsCard({super.key});

  @override
  State<HealthTrendsCard> createState() => _HealthTrendsCardState();
}

class _HealthTrendsCardState extends State<HealthTrendsCard> {
  int selectedMetricIndex = 0;

  final List<Map<String, dynamic>> healthMetrics = [
    {
      "title": "Blood Pressure",
      "unit": "mmHg",
      "data": [
        {"date": "Jan 1", "systolic": 120, "diastolic": 80},
        {"date": "Jan 3", "systolic": 118, "diastolic": 78},
        {"date": "Jan 5", "systolic": 122, "diastolic": 82},
        {"date": "Jan 7", "systolic": 119, "diastolic": 79},
        {"date": "Jan 9", "systolic": 121, "diastolic": 81},
      ],
      "color": AppTheme.lightTheme.colorScheme.primary,
    },
    {
      "title": "Weight",
      "unit": "kg",
      "data": [
        {"date": "Jan 1", "value": 75.2},
        {"date": "Jan 3", "value": 75.0},
        {"date": "Jan 5", "value": 74.8},
        {"date": "Jan 7", "value": 74.5},
        {"date": "Jan 9", "value": 74.3},
      ],
      "color": AppTheme.successLight,
    },
    {
      "title": "Blood Glucose",
      "unit": "mg/dL",
      "data": [
        {"date": "Jan 1", "value": 95},
        {"date": "Jan 3", "value": 92},
        {"date": "Jan 5", "value": 98},
        {"date": "Jan 7", "value": 90},
        {"date": "Jan 9", "value": 94},
      ],
      "color": AppTheme.warningLight,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Health Trends',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Last 7 Days',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          _buildMetricSelector(),
          SizedBox(height: 3.h),
          _buildChart(),
        ],
      ),
    );
  }

  Widget _buildMetricSelector() {
    return Container(
      height: 5.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: healthMetrics.length,
        itemBuilder: (context, index) {
          final metric = healthMetrics[index];
          final isSelected = index == selectedMetricIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedMetricIndex = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 3.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? (metric["color"] as Color).withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? (metric["color"] as Color)
                      : AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  metric["title"] as String,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? (metric["color"] as Color)
                        : AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChart() {
    final selectedMetric = healthMetrics[selectedMetricIndex];
    final data = selectedMetric["data"] as List<Map<String, dynamic>>;
    final color = selectedMetric["color"] as Color;

    return Container(
      height: 25.h,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        data[value.toInt()]["date"] as String,
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: selectedMetricIndex == 0
                    ? 10
                    : (selectedMetricIndex == 1 ? 0.5 : 5),
                reservedSize: 42,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toInt().toString(),
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.1),
            ),
          ),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: _getMinY(data),
          maxY: _getMaxY(data),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                double value;

                if (selectedMetricIndex == 0) {
                  // Blood pressure - use systolic
                  value = (item["systolic"] as int).toDouble();
                } else {
                  value = (item["value"] as num).toDouble();
                }

                return FlSpot(index.toDouble(), value);
              }).toList(),
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: AppTheme.lightTheme.colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMinY(List<Map<String, dynamic>> data) {
    if (selectedMetricIndex == 0) {
      // Blood pressure
      final values =
          data.map((item) => (item["diastolic"] as int).toDouble()).toList();
      return values.reduce((a, b) => a < b ? a : b) - 10;
    } else {
      final values =
          data.map((item) => (item["value"] as num).toDouble()).toList();
      return values.reduce((a, b) => a < b ? a : b) - 5;
    }
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    if (selectedMetricIndex == 0) {
      // Blood pressure
      final values =
          data.map((item) => (item["systolic"] as int).toDouble()).toList();
      return values.reduce((a, b) => a > b ? a : b) + 10;
    } else {
      final values =
          data.map((item) => (item["value"] as num).toDouble()).toList();
      return values.reduce((a, b) => a > b ? a : b) + 5;
    }
  }
}
