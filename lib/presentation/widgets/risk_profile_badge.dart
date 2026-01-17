/// Risk Profile Badge Widget
///
/// Displays a visual indicator when a patient has elevated risk factors.
/// Designed to be non-alarming but clearly visible.
///
/// Shows:
/// - "High-risk patient profile" badge
/// - Comorbidity codes
/// - Explains WHY risk was adjusted

import 'package:flutter/material.dart';
import '../../domain/entities/patient_risk_profile.dart';
import '../../domain/entities/comorbidity.dart';

/// Compact badge showing high-risk status
class RiskProfileBadge extends StatelessWidget {
  final PatientRiskProfile riskProfile;
  final bool showDetails;
  final VoidCallback? onTap;

  const RiskProfileBadge({
    super.key,
    required this.riskProfile,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!riskProfile.riskProfileLevel.showHighRiskBadge) {
      return const SizedBox.shrink();
    }

    final level = riskProfile.riskProfileLevel;
    final color = _getColorForLevel(level);

    return GestureDetector(
      onTap: onTap ?? () => _showRiskExplanationDialog(context, riskProfile),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              level.shortLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.info_outline, size: 10, color: color.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  Color _getColorForLevel(RiskProfileLevel level) {
    switch (level) {
      case RiskProfileLevel.veryHigh:
        return const Color(0xFFD32F2F); // Red
      case RiskProfileLevel.high:
        return const Color(0xFFEF6C00); // Orange
      case RiskProfileLevel.elevated:
        return const Color(0xFFF9A825); // Yellow/Amber
      case RiskProfileLevel.standard:
        return const Color(0xFF2E7D32); // Green
    }
  }

  void _showRiskExplanationDialog(
    BuildContext context,
    PatientRiskProfile profile,
  ) {
    showDialog(
      context: context,
      builder: (context) => RiskExplanationDialog(riskProfile: profile),
    );
  }
}

/// Full explanation dialog for risk profile
class RiskExplanationDialog extends StatelessWidget {
  final PatientRiskProfile riskProfile;

  const RiskExplanationDialog({super.key, required this.riskProfile});

  @override
  Widget build(BuildContext context) {
    final level = riskProfile.riskProfileLevel;
    final color = _getColorForLevel(level);
    final riskPercent =
        ((riskProfile.combinedRiskMultiplier - 1.0) * 100).round();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning_amber_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${level.displayName} Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '+$riskPercent% sensitivity adjustment',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Core principle callout
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The same vital sign abnormality does not mean '
                      'the same risk for every patient.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Risk factors
            Text(
              'Risk Factors',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // Age factor
            if (riskProfile.isElderly)
              _RiskFactorTile(
                icon: Icons.person,
                title: 'Age ${riskProfile.age}',
                subtitle: riskProfile.ageCategory.displayName,
                detail: 'Reduced physiological reserve',
              ),

            // Comorbidities
            ...riskProfile.activeComorbidities.map(
              (c) => _RiskFactorTile(
                icon: _getIconForComorbidity(c.type),
                title: c.displayName,
                subtitle: c.type.shortCode,
                detail: c.clinicalRationale,
              ),
            ),

            // Additional factors
            if (riskProfile.hasRecentSurgery)
              const _RiskFactorTile(
                icon: Icons.medical_services,
                title: 'Recent Surgery',
                subtitle: 'Within 30 days',
                detail: 'Increased infection risk',
              ),

            if (riskProfile.hasRecentHospitalization)
              const _RiskFactorTile(
                icon: Icons.local_hospital,
                title: 'Recent Hospitalization',
                subtitle: 'Within 90 days',
                detail: 'Healthcare-associated infection risk',
              ),

            if (riskProfile.hasIndwellingDevices)
              const _RiskFactorTile(
                icon: Icons.cable,
                title: 'Indwelling Devices',
                subtitle: 'Catheter/Line',
                detail: 'Device-associated infection risk',
              ),

            const SizedBox(height: 16),

            // Clinical impact
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clinical Impact',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Thresholds for concern are lowered\n'
                    '• Earlier escalation is warranted\n'
                    '• Closer monitoring recommended\n'
                    '• Raw vital values are NOT modified',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Understood'),
        ),
      ],
    );
  }

  Color _getColorForLevel(RiskProfileLevel level) {
    switch (level) {
      case RiskProfileLevel.veryHigh:
        return const Color(0xFFD32F2F);
      case RiskProfileLevel.high:
        return const Color(0xFFEF6C00);
      case RiskProfileLevel.elevated:
        return const Color(0xFFF9A825);
      case RiskProfileLevel.standard:
        return const Color(0xFF2E7D32);
    }
  }

  IconData _getIconForComorbidity(ComorbidityType type) {
    switch (type) {
      case ComorbidityType.diabetesMellitus:
        return Icons.bloodtype;
      case ComorbidityType.chronicKidneyDisease:
        return Icons.water_drop;
      case ComorbidityType.copd:
        return Icons.air;
      case ComorbidityType.immunosuppression:
        return Icons.shield;
      case ComorbidityType.heartFailure:
        return Icons.heart_broken;
      case ComorbidityType.liverCirrhosis:
        return Icons.science;
      case ComorbidityType.malignancy:
        return Icons.healing;
    }
  }
}

class _RiskFactorTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String detail;

  const _RiskFactorTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subtitle,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact comorbidity chip for lists
class ComorbidityChip extends StatelessWidget {
  final ComorbidityType type;
  final bool showTooltip;

  const ComorbidityChip({
    super.key,
    required this.type,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Text(
        type.shortCode,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );

    if (showTooltip) {
      return Tooltip(
        message: '${type.displayName}\n${type.clinicalRationale}',
        child: chip,
      );
    }

    return chip;
  }
}
