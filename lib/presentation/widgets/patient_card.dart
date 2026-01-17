/// Patient Card Widget
///
/// A compact, color-coded card displaying patient summary for use in lists.
/// Supports tap navigation to patient details.

import 'package:flutter/material.dart';
import '../../../core/constants/risk_level.dart';
import '../../../core/utils/app_utils.dart';
import '../../../domain/entities/patient.dart';
import '../../../domain/entities/vital_signs.dart';
import 'risk_profile_badge.dart';

class PatientCard extends StatelessWidget {
  final Patient patient;
  final VitalSigns? latestVitals;
  final VoidCallback? onTap;
  final bool showSparkline;

  const PatientCard({
    super.key,
    required this.patient,
    this.latestVitals,
    this.onTap,
    this.showSparkline = false,
  });

  @override
  Widget build(BuildContext context) {
    final riskLevel = patient.currentRiskLevel;

    return Card(
      elevation: riskLevel.index >= RiskLevel.orange.index ? 2 : 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: riskLevel.color.withOpacity(0.3),
          width: riskLevel.index >= RiskLevel.orange.index ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [riskLevel.backgroundColor, Theme.of(context).cardColor],
              stops: const [0.0, 0.3],
            ),
          ),
          child: Row(
            children: [
              // Risk indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: riskLevel.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(riskLevel.icon, color: riskLevel.color, size: 20),
                    const SizedBox(height: 2),
                    Text(
                      riskLevel.displayName[0],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: riskLevel.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Patient info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            patient.bedDisplay,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            patient.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${patient.age}y • ${patient.gender}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        // Risk Profile Badge - NEW FEATURE
                        if (patient.comorbidities.isNotEmpty)
                          RiskProfileBadge(
                            riskProfile: patient.riskProfile,
                            showDetails: false,
                          ),
                        if (patient.lastVitalsTime != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                AppUtils.formatRelativeTime(
                                    patient.lastVitalsTime!),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Latest vitals summary - only show if there's enough space
              if (latestVitals != null)
                Flexible(
                  flex: 0,
                  child: _VitalsSummary(vitals: latestVitals!),
                ),

              // Arrow
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VitalsSummary extends StatelessWidget {
  final VitalSigns vitals;

  const _VitalsSummary({required this.vitals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, size: 10, color: Colors.red.shade400),
              const SizedBox(width: 2),
              Text(
                '${vitals.heartRate}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(width: 4),
              Icon(Icons.speed, size: 10, color: Colors.blue.shade400),
              const SizedBox(width: 2),
              Text(
                '${vitals.systolicBP}/${vitals.diastolicBP}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.thermostat, size: 10, color: Colors.orange.shade400),
              const SizedBox(width: 2),
              Text(
                vitals.temperature.toStringAsFixed(1),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(width: 4),
              Icon(Icons.air, size: 10, color: Colors.indigo.shade400),
              const SizedBox(width: 2),
              Text(
                '${vitals.spO2}%',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact patient card for critical lists
class CompactPatientCard extends StatelessWidget {
  final Patient patient;
  final String? subtitle;
  final VoidCallback? onTap;

  const CompactPatientCard({
    super.key,
    required this.patient,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final riskLevel = patient.currentRiskLevel;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: riskLevel.backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(riskLevel.icon, color: riskLevel.color, size: 20),
      ),
      title: Text(
        patient.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle ?? '${patient.bedDisplay} • ${patient.age}y ${patient.gender}',
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
