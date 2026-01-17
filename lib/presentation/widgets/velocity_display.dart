/// Vital Velocity Display Widgets
///
/// Displays the rate of change (velocity) of vital signs in an
/// explainable, clinically meaningful way.
///
/// Shows:
/// - Direction of change (rising/falling/stable)
/// - Absolute change over time window
/// - Rate per hour
/// - Severity classification
/// - Human-readable explanation

import 'package:flutter/material.dart';
import '../../domain/entities/vital_velocity.dart';
import '../../domain/entities/alert.dart'; // For VitalType and TrendDirection

/// Compact velocity indicator for vital sign display
class VelocityIndicator extends StatelessWidget {
  final VitalVelocity velocity;
  final bool showDetails;

  const VelocityIndicator({
    super.key,
    required this.velocity,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!velocity.isConcerning &&
        velocity.severity == VelocitySeverity.stable) {
      return const SizedBox.shrink();
    }

    final color = _getColorForSeverity(velocity.severity);
    final icon = _getIconForDirection(velocity.direction);

    return GestureDetector(
      onTap: () => _showVelocityDialog(context, velocity),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 2),
            Text(
              _formatChange(velocity),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (showDetails) ...[
              const SizedBox(width: 4),
              Text(
                velocity.severity.displayName,
                style: TextStyle(fontSize: 9, color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatChange(VitalVelocity v) {
    final sign = v.absoluteChange > 0 ? '+' : '';
    return '$sign${v.absoluteChange.toStringAsFixed(0)}';
  }

  IconData _getIconForDirection(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.rising:
        return Icons.trending_up;
      case TrendDirection.falling:
        return Icons.trending_down;
      case TrendDirection.stable:
      case TrendDirection.unknown:
        return Icons.trending_flat;
    }
  }

  Color _getColorForSeverity(VelocitySeverity severity) {
    switch (severity) {
      case VelocitySeverity.critical:
        return const Color(0xFFD32F2F);
      case VelocitySeverity.rapid:
        return const Color(0xFFEF6C00);
      case VelocitySeverity.moderate:
        return const Color(0xFFF9A825);
      case VelocitySeverity.mild:
        return const Color(0xFF7CB342);
      case VelocitySeverity.stable:
        return const Color(0xFF78909C);
    }
  }

  void _showVelocityDialog(BuildContext context, VitalVelocity velocity) {
    showDialog(
      context: context,
      builder: (context) => VelocityDetailDialog(velocity: velocity),
    );
  }
}

/// Full velocity analysis card
class VelocityAnalysisCard extends StatelessWidget {
  final VelocityAnalysisResult result;
  final VoidCallback? onTap;

  const VelocityAnalysisCard({
    super.key,
    required this.result,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final concerningVelocities = result.concerningVelocities;
    final hasConcerns =
        concerningVelocities.isNotEmpty || result.hasSepsisVelocityPattern;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: result.hasRapidDeterioration
              ? const Color(0xFFEF6C00)
              : hasConcerns
                  ? const Color(0xFFF9A825)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: result.hasRapidDeterioration ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.speed,
                    size: 18,
                    color: result.hasRapidDeterioration
                        ? const Color(0xFFEF6C00)
                        : hasConcerns
                            ? const Color(0xFFF9A825)
                            : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Trend Velocity Analysis',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${result.window.hours}h window',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Sepsis pattern warning
              if (result.hasSepsisVelocityPattern) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF6C00).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEF6C00).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Color(0xFFEF6C00),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Velocity pattern consistent with early sepsis',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFEF6C00),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Velocity rows
              if (concerningVelocities.isEmpty &&
                  !result.hasSepsisVelocityPattern) ...[
                // Show stable state
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'All vitals stable - no concerning rate of change detected',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ...concerningVelocities.map(
                  (v) => _VelocityRow(velocity: v),
                ),
              ],

              // Summary
              const SizedBox(height: 8),
              Text(
                result.summary,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VelocityRow extends StatelessWidget {
  final VitalVelocity velocity;

  const _VelocityRow({required this.velocity});

  @override
  Widget build(BuildContext context) {
    final color = _getColorForSeverity(velocity.severity);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Direction icon
          Icon(
            _getIconForDirection(velocity.direction),
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),

          // Vital name
          SizedBox(
            width: 80,
            child: Text(
              _getVitalName(velocity.vitalType),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),

          // Change amount
          Expanded(
            child: Text(
              _formatChangeDescription(velocity),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),

          // Severity badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              velocity.severity.displayName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatChangeDescription(VitalVelocity v) {
    final sign = v.absoluteChange > 0 ? '+' : '';
    final unit = _getUnit(v.vitalType);
    final hours = v.actualTimeSpan.inHours;
    return '$sign${v.absoluteChange.toStringAsFixed(0)}$unit in ${hours}h';
  }

  String _getVitalName(VitalType type) {
    switch (type) {
      case VitalType.heartRate:
        return 'Heart Rate';
      case VitalType.systolicBP:
        return 'Systolic BP';
      case VitalType.diastolicBP:
        return 'Diastolic BP';
      case VitalType.respiratoryRate:
        return 'Resp Rate';
      case VitalType.temperature:
        return 'Temp';
      case VitalType.spO2:
        return 'SpO₂';
    }
  }

  String _getUnit(VitalType type) {
    switch (type) {
      case VitalType.heartRate:
        return ' bpm';
      case VitalType.systolicBP:
      case VitalType.diastolicBP:
        return ' mmHg';
      case VitalType.respiratoryRate:
        return '/min';
      case VitalType.temperature:
        return '°C';
      case VitalType.spO2:
        return '%';
    }
  }

  IconData _getIconForDirection(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.rising:
        return Icons.trending_up;
      case TrendDirection.falling:
        return Icons.trending_down;
      case TrendDirection.stable:
      case TrendDirection.unknown:
        return Icons.trending_flat;
    }
  }

  Color _getColorForSeverity(VelocitySeverity severity) {
    switch (severity) {
      case VelocitySeverity.critical:
        return const Color(0xFFD32F2F);
      case VelocitySeverity.rapid:
        return const Color(0xFFEF6C00);
      case VelocitySeverity.moderate:
        return const Color(0xFFF9A825);
      case VelocitySeverity.mild:
        return const Color(0xFF7CB342);
      case VelocitySeverity.stable:
        return const Color(0xFF78909C);
    }
  }
}

/// Detailed velocity dialog
class VelocityDetailDialog extends StatelessWidget {
  final VitalVelocity velocity;

  const VelocityDetailDialog({super.key, required this.velocity});

  @override
  Widget build(BuildContext context) {
    final color = _getColorForSeverity(velocity.severity);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            _getIconForDirection(velocity.direction),
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getVitalName(velocity.vitalType)),
                Text(
                  'Trend Velocity',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              velocity.severity.displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Core explanation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              velocity.explanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

          const SizedBox(height: 16),

          // Metrics grid
          _MetricRow(
            label: 'Start value',
            value:
                '${velocity.startValue.toStringAsFixed(0)}${_getUnit(velocity.vitalType)}',
          ),
          _MetricRow(
            label: 'Current value',
            value:
                '${velocity.endValue.toStringAsFixed(0)}${_getUnit(velocity.vitalType)}',
          ),
          _MetricRow(
            label: 'Change',
            value:
                '${velocity.absoluteChange > 0 ? '+' : ''}${velocity.absoluteChange.toStringAsFixed(0)}${_getUnit(velocity.vitalType)}',
            valueColor: color,
          ),
          _MetricRow(
            label: 'Rate',
            value:
                '${velocity.ratePerHour.toStringAsFixed(1)}${_getUnit(velocity.vitalType)}/hour',
          ),
          _MetricRow(
            label: 'Time span',
            value:
                '${velocity.actualTimeSpan.inHours}h ${velocity.actualTimeSpan.inMinutes % 60}m',
          ),
          _MetricRow(
            label: 'Data points',
            value: '${velocity.dataPointCount} readings',
          ),

          const SizedBox(height: 16),

          // Interpretation
          Text(
            'Interpretation',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            velocity.interpretation,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _getVitalName(VitalType type) {
    switch (type) {
      case VitalType.heartRate:
        return 'Heart Rate';
      case VitalType.systolicBP:
        return 'Systolic BP';
      case VitalType.diastolicBP:
        return 'Diastolic BP';
      case VitalType.respiratoryRate:
        return 'Respiratory Rate';
      case VitalType.temperature:
        return 'Temperature';
      case VitalType.spO2:
        return 'SpO₂';
    }
  }

  String _getUnit(VitalType type) {
    switch (type) {
      case VitalType.heartRate:
        return ' bpm';
      case VitalType.systolicBP:
      case VitalType.diastolicBP:
        return ' mmHg';
      case VitalType.respiratoryRate:
        return '/min';
      case VitalType.temperature:
        return '°C';
      case VitalType.spO2:
        return '%';
    }
  }

  IconData _getIconForDirection(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.rising:
        return Icons.trending_up;
      case TrendDirection.falling:
        return Icons.trending_down;
      case TrendDirection.stable:
      case TrendDirection.unknown:
        return Icons.trending_flat;
    }
  }

  Color _getColorForSeverity(VelocitySeverity severity) {
    switch (severity) {
      case VelocitySeverity.critical:
        return const Color(0xFFD32F2F);
      case VelocitySeverity.rapid:
        return const Color(0xFFEF6C00);
      case VelocitySeverity.moderate:
        return const Color(0xFFF9A825);
      case VelocitySeverity.mild:
        return const Color(0xFF7CB342);
      case VelocitySeverity.stable:
        return const Color(0xFF78909C);
    }
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
