/// Risk Summary Bar Widget
///
/// Horizontal bar showing distribution of patients by risk level.
/// Provides quick visual overview of ward status.

import 'package:flutter/material.dart';
import '../../../core/constants/risk_level.dart';
import '../../../domain/entities/patient.dart';

class RiskSummaryBar extends StatelessWidget {
  final List<Patient> patients;
  final RiskLevel? selectedRiskLevel;
  final ValueChanged<RiskLevel?>? onRiskLevelTap;

  const RiskSummaryBar({
    super.key,
    required this.patients,
    this.selectedRiskLevel,
    this.onRiskLevelTap,
  });

  @override
  Widget build(BuildContext context) {
    final counts = _calculateCounts();
    final total = patients.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ward Overview',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '$total patients',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Visual bar
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: RiskLevel.values.map((level) {
                    final count = counts[level] ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Expanded(
                      flex: count,
                      child: Container(color: level.color),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Count chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RiskLevel.values.map((level) {
              final count = counts[level] ?? 0;
              final isSelected = selectedRiskLevel == level;

              return GestureDetector(
                onTap: () {
                  if (onRiskLevelTap != null) {
                    onRiskLevelTap!(isSelected ? null : level);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? level.color : level.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: level.color,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        level.icon,
                        size: 14,
                        color: isSelected ? Colors.white : level.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$count ${level.displayName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : level.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Map<RiskLevel, int> _calculateCounts() {
    final counts = <RiskLevel, int>{};
    for (final level in RiskLevel.values) {
      counts[level] = patients.where((p) => p.currentRiskLevel == level).length;
    }
    return counts;
  }
}

/// Compact version for smaller spaces
class CompactRiskSummary extends StatelessWidget {
  final List<Patient> patients;

  const CompactRiskSummary({super.key, required this.patients});

  @override
  Widget build(BuildContext context) {
    final counts = _calculateCounts();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: RiskLevel.values.map((level) {
        final count = counts[level] ?? 0;
        return _RiskCountChip(level: level, count: count);
      }).toList(),
    );
  }

  Map<RiskLevel, int> _calculateCounts() {
    final counts = <RiskLevel, int>{};
    for (final level in RiskLevel.values) {
      counts[level] = patients.where((p) => p.currentRiskLevel == level).length;
    }
    return counts;
  }
}

class _RiskCountChip extends StatelessWidget {
  final RiskLevel level;
  final int count;

  const _RiskCountChip({required this.level, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: level.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: level.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            level.displayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: level.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Alert badge for critical patient count
class CriticalAlertBadge extends StatelessWidget {
  final int criticalCount;
  final VoidCallback? onTap;

  const CriticalAlertBadge({
    super.key,
    required this.criticalCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (criticalCount == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: RiskLevel.red.color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              '$criticalCount critical',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
