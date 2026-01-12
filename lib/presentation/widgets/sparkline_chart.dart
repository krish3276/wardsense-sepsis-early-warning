/// Sparkline Chart Widget
///
/// Compact trend visualization for use in cards and list items.
/// Shows quick visual of vital sign trends.

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../domain/entities/vital_signs.dart';

/// Generic sparkline widget for any numeric data
class SparklineChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double height;
  final double width;
  final bool showDots;
  final bool showArea;
  final double? minY;
  final double? maxY;

  const SparklineChart({
    super.key,
    required this.data,
    this.color = Colors.blue,
    this.height = 40,
    this.width = 100,
    this.showDots = false,
    this.showArea = true,
    this.minY,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      return SizedBox(width: width, height: height);
    }

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    final calculatedMinY = minY ?? (data.reduce((a, b) => a < b ? a : b) * 0.9);
    final calculatedMaxY = maxY ?? (data.reduce((a, b) => a > b ? a : b) * 1.1);

    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: calculatedMinY,
          maxY: calculatedMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: showDots,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 2,
                    color: color,
                    strokeWidth: 0,
                  );
                },
              ),
              belowBarData: showArea
                  ? BarAreaData(
                      show: true,
                      color: color.withOpacity(0.2),
                    )
                  : BarAreaData(show: false),
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }
}

/// Sparkline specifically for vital signs with appropriate coloring
class VitalSparkline extends StatelessWidget {
  final List<VitalSigns> vitals;
  final VitalType vitalType;
  final double height;
  final double width;

  const VitalSparkline({
    super.key,
    required this.vitals,
    required this.vitalType,
    this.height = 40,
    this.width = 100,
  });

  @override
  Widget build(BuildContext context) {
    if (vitals.length < 2) {
      return SizedBox(width: width, height: height);
    }

    // Extract data based on vital type (most recent first, reverse for chart)
    final data = vitals.reversed.map((v) {
      switch (vitalType) {
        case VitalType.heartRate:
          return v.heartRate.toDouble();
        case VitalType.systolicBP:
          return v.systolicBP.toDouble();
        case VitalType.diastolicBP:
          return v.diastolicBP.toDouble();
        case VitalType.respiratoryRate:
          return v.respiratoryRate.toDouble();
        case VitalType.temperature:
          return v.temperature;
        case VitalType.spO2:
          return v.spO2.toDouble();
      }
    }).toList();

    // Determine color based on trend
    final trendColor = _getTrendColor(data);

    return SparklineChart(
      data: data,
      color: trendColor,
      height: height,
      width: width,
      showArea: true,
      minY: _getMinY(),
      maxY: _getMaxY(),
    );
  }

  Color _getTrendColor(List<double> data) {
    if (data.length < 2) return Colors.grey;

    // Calculate simple trend (last vs first half average)
    final firstHalf = data.sublist(0, data.length ~/ 2);
    final secondHalf = data.sublist(data.length ~/ 2);

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    final percentChange = ((secondAvg - firstAvg) / firstAvg).abs();

    // Get base color for vital type
    final baseColor = _getVitalColor();

    // If trend is significant (>5% change), show warning color
    if (percentChange > 0.10) {
      return Colors.red;
    } else if (percentChange > 0.05) {
      return Colors.orange;
    }

    return baseColor;
  }

  Color _getVitalColor() {
    switch (vitalType) {
      case VitalType.heartRate:
        return Colors.red.shade400;
      case VitalType.systolicBP:
      case VitalType.diastolicBP:
        return Colors.blue.shade400;
      case VitalType.respiratoryRate:
        return Colors.teal.shade400;
      case VitalType.temperature:
        return Colors.orange.shade400;
      case VitalType.spO2:
        return Colors.indigo.shade400;
    }
  }

  double? _getMinY() {
    switch (vitalType) {
      case VitalType.heartRate:
        return 40;
      case VitalType.systolicBP:
        return 70;
      case VitalType.diastolicBP:
        return 40;
      case VitalType.respiratoryRate:
        return 8;
      case VitalType.temperature:
        return 35;
      case VitalType.spO2:
        return 85;
    }
  }

  double? _getMaxY() {
    switch (vitalType) {
      case VitalType.heartRate:
        return 150;
      case VitalType.systolicBP:
        return 200;
      case VitalType.diastolicBP:
        return 120;
      case VitalType.respiratoryRate:
        return 35;
      case VitalType.temperature:
        return 42;
      case VitalType.spO2:
        return 100;
    }
  }
}

enum VitalType {
  heartRate,
  systolicBP,
  diastolicBP,
  respiratoryRate,
  temperature,
  spO2,
}

/// Multi-vital sparkline row for patient cards
class VitalSparklineRow extends StatelessWidget {
  final List<VitalSigns> vitals;

  const VitalSparklineRow({
    super.key,
    required this.vitals,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _SparklineWithLabel(
          label: 'HR',
          vitals: vitals,
          vitalType: VitalType.heartRate,
          icon: Icons.favorite,
          color: Colors.red,
        ),
        _SparklineWithLabel(
          label: 'BP',
          vitals: vitals,
          vitalType: VitalType.systolicBP,
          icon: Icons.speed,
          color: Colors.blue,
        ),
        _SparklineWithLabel(
          label: 'RR',
          vitals: vitals,
          vitalType: VitalType.respiratoryRate,
          icon: Icons.waves,
          color: Colors.teal,
        ),
      ],
    );
  }
}

class _SparklineWithLabel extends StatelessWidget {
  final String label;
  final List<VitalSigns> vitals;
  final VitalType vitalType;
  final IconData icon;
  final Color color;

  const _SparklineWithLabel({
    required this.label,
    required this.vitals,
    required this.vitalType,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        VitalSparkline(
          vitals: vitals,
          vitalType: vitalType,
          height: 30,
          width: 80,
        ),
      ],
    );
  }
}

/// Trend indicator arrow
class TrendIndicator extends StatelessWidget {
  final double percentChange;
  final bool isPositiveGood;

  const TrendIndicator({
    super.key,
    required this.percentChange,
    this.isPositiveGood = false,
  });

  @override
  Widget build(BuildContext context) {
    final isIncreasing = percentChange > 0;
    final isBad = isPositiveGood ? !isIncreasing : isIncreasing;
    final isSignificant = percentChange.abs() > 0.05;

    IconData icon;
    Color color;

    if (percentChange.abs() < 0.02) {
      icon = Icons.remove;
      color = Colors.grey;
    } else if (isIncreasing) {
      icon = Icons.arrow_upward;
      color = isBad && isSignificant ? Colors.red : Colors.grey;
    } else {
      icon = Icons.arrow_downward;
      color = isBad && isSignificant ? Colors.red : Colors.grey;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        Text(
          '${(percentChange.abs() * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: isSignificant ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
