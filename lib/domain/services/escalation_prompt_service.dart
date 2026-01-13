/// Context-Aware Escalation Prompt Service
///
/// Generates clinically intelligent escalation prompts that combine:
/// - Current vital signs
/// - Trend velocity analysis
/// - Comorbidity risk profile
///
/// This is the implementation for Feature 3.
///
/// CORE PRINCIPLE:
/// "Reduce alert fatigue by providing calm, clinical-style prompts
/// that match real ward workflows."
///
/// These prompts are designed to feel like clinical reasoning,
/// not generic automated alarms.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/risk_level.dart';
import '../../domain/entities/vital_signs.dart';
import '../../domain/entities/vital_velocity.dart';
import '../../domain/entities/patient_risk_profile.dart';
import '../../domain/entities/escalation_prompt.dart';
import '../../domain/entities/alert.dart'; // For VitalType and TrendDirection
import '../../domain/services/velocity_analysis_service.dart';
import '../../domain/services/risk_adjustment_service.dart';
import '../../domain/services/trend_analysis_engine.dart';

/// Provider for the escalation prompt service
final escalationPromptServiceProvider = Provider<EscalationPromptService>((
  ref,
) {
  return EscalationPromptService(
    ref.read(velocityAnalysisServiceProvider),
    ref.read(riskAdjustmentServiceProvider),
    ref.read(trendAnalysisEngineProvider),
  );
});

/// Escalation Prompt Service
///
/// Generates context-aware, clinically-styled escalation prompts.
class EscalationPromptService {
  final VelocityAnalysisService _velocityService;
  final RiskAdjustmentService _riskService;
  final TrendAnalysisEngine _trendEngine;
  static const _uuid = Uuid();

  EscalationPromptService(
    this._velocityService,
    this._riskService,
    this._trendEngine,
  );

  /// Generate an escalation prompt based on comprehensive patient analysis
  ///
  /// Combines multiple data sources to create a single, coherent prompt
  /// that reflects clinical reasoning.
  EscalationPrompt? generatePrompt({
    required String patientId,
    required VitalSigns currentVitals,
    required PatientRiskProfile riskProfile,
    required int newsScore,
  }) {
    // Perform velocity analysis
    final velocityResult = _velocityService.analyzeVelocity(patientId);

    // Get adjusted risk assessment
    final adjustedRisk = _riskService.calculateAdjustedRisk(
      vitals: currentVitals,
      riskProfile: riskProfile,
      baseNewsScore: newsScore,
    );

    // Don't generate prompts for green patients without concerning velocities
    if (adjustedRisk.adjustedRiskLevel == RiskLevel.green &&
        !velocityResult.hasRapidDeterioration &&
        !velocityResult.hasSepsisVelocityPattern) {
      return null;
    }

    // Determine urgency based on combined assessment
    final urgency = _determineUrgency(
      adjustedRisk.adjustedRiskLevel,
      velocityResult,
      riskProfile,
    );

    // Collect triggering factors
    final triggeringFactors = _collectTriggeringFactors(
      adjustedRisk,
      velocityResult,
      riskProfile,
    );

    // Generate main prompt
    final mainPrompt = _generateMainPrompt(
      adjustedRisk,
      velocityResult,
      riskProfile,
    );

    // Generate clinical context
    final clinicalContext = _generateClinicalContext(
      currentVitals,
      velocityResult,
      riskProfile,
    );

    // Generate suggested actions
    final actions = _generateSuggestedActions(
      urgency,
      adjustedRisk.adjustedRiskLevel,
      velocityResult,
      riskProfile,
    );

    return EscalationPrompt(
      id: _uuid.v4(),
      patientId: patientId,
      urgency: urgency,
      mainPrompt: mainPrompt,
      clinicalContext: clinicalContext,
      triggeringFactors: triggeringFactors,
      suggestedActions: actions,
      riskLevel: adjustedRisk.adjustedRiskLevel,
      isHighRiskPatient: riskProfile.riskProfileLevel.showHighRiskBadge,
      hasVelocityDeteriorationFlag: velocityResult.hasRapidDeterioration,
      generatedAt: DateTime.now(),
    );
  }

  /// Determine urgency level from combined analysis
  EscalationUrgency _determineUrgency(
    RiskLevel riskLevel,
    VelocityAnalysisResult velocityResult,
    PatientRiskProfile riskProfile,
  ) {
    // Highest urgency for critical patterns
    if (riskLevel == RiskLevel.red) {
      return EscalationUrgency.urgent;
    }

    // High urgency for rapid deterioration in high-risk patient
    if (velocityResult.hasRapidDeterioration &&
        riskProfile.riskProfileLevel.showHighRiskBadge) {
      return EscalationUrgency.urgent;
    }

    // Sepsis pattern warrants prompt attention
    if (velocityResult.hasSepsisVelocityPattern) {
      return EscalationUrgency.prompt;
    }

    // Orange level needs soon review
    if (riskLevel == RiskLevel.orange) {
      return EscalationUrgency.prompt;
    }

    // Rapid deterioration alone
    if (velocityResult.hasRapidDeterioration) {
      return EscalationUrgency.soon;
    }

    // High-risk patient with yellow status
    if (riskLevel == RiskLevel.yellow &&
        riskProfile.riskProfileLevel.showHighRiskBadge) {
      return EscalationUrgency.soon;
    }

    // Standard yellow
    if (riskLevel == RiskLevel.yellow) {
      return EscalationUrgency.routine;
    }

    return EscalationUrgency.informational;
  }

  /// Generate the main prompt message
  ///
  /// Uses clinical-style language that feels natural to healthcare workers.
  String _generateMainPrompt(
    AdjustedRiskResult adjustedRisk,
    VelocityAnalysisResult velocityResult,
    PatientRiskProfile riskProfile,
  ) {
    final isHighRisk = riskProfile.riskProfileLevel.showHighRiskBadge;

    // Sepsis velocity pattern with high risk
    if (velocityResult.hasSepsisVelocityPattern && isHighRisk) {
      return _buildSepsisPatternPrompt(velocityResult, riskProfile);
    }

    // Rapid deterioration
    if (velocityResult.hasRapidDeterioration) {
      return _buildRapidDeteriorationPrompt(velocityResult, isHighRisk);
    }

    // Elevated risk due to comorbidities
    if (adjustedRisk.wasElevated) {
      return _buildElevatedRiskPrompt(adjustedRisk, riskProfile);
    }

    // High-risk patient with concerning vitals
    if (isHighRisk &&
        adjustedRisk.adjustedRiskLevel.index >= RiskLevel.yellow.index) {
      return _buildHighRiskPatientPrompt(
        adjustedRisk.adjustedRiskLevel,
        riskProfile,
      );
    }

    // Default concerning pattern
    return _buildDefaultPrompt(adjustedRisk);
  }

  String _buildSepsisPatternPrompt(
    VelocityAnalysisResult velocityResult,
    PatientRiskProfile riskProfile,
  ) {
    final velocityDescription = _describeVelocityPattern(velocityResult);
    final profileDescription = riskProfile.riskProfileLevel.displayName;

    return 'Vital sign velocity pattern consistent with early sepsis '
        '($velocityDescription) in a $profileDescription patient — '
        'consider sepsis pathway evaluation per hospital protocol.';
  }

  String _buildRapidDeteriorationPrompt(
    VelocityAnalysisResult velocityResult,
    bool isHighRisk,
  ) {
    final velocityDescription = _describeVelocityChanges(velocityResult);
    final patientContext = isHighRisk ? ' in a high-risk patient' : '';

    return 'Rapid vital sign changes detected$patientContext: '
        '$velocityDescription. '
        'Recommend bedside review and repeat vital signs in 30 minutes.';
  }

  String _buildElevatedRiskPrompt(
    AdjustedRiskResult adjustedRisk,
    PatientRiskProfile riskProfile,
  ) {
    final baseLevel = adjustedRisk.baseRiskLevel.displayName;
    final adjustedLevel = adjustedRisk.adjustedRiskLevel.displayName;
    final factors = riskProfile.shortSummary;

    return 'Vital signs would typically indicate "$baseLevel" status, '
        'but risk is elevated to "$adjustedLevel" given patient factors: $factors. '
        'Consider earlier review due to reduced physiological reserve.';
  }

  String _buildHighRiskPatientPrompt(
    RiskLevel riskLevel,
    PatientRiskProfile riskProfile,
  ) {
    final status = riskLevel.displayName;
    final factors = riskProfile.shortSummary;

    return 'High-risk patient ($factors) showing $status status. '
        'Enhanced monitoring and lower threshold for escalation advised.';
  }

  String _buildDefaultPrompt(AdjustedRiskResult adjustedRisk) {
    return 'Current assessment: ${adjustedRisk.adjustedRiskLevel.displayName}. '
        '${adjustedRisk.recommendation}';
  }

  /// Generate clinical context section
  String _generateClinicalContext(
    VitalSigns vitals,
    VelocityAnalysisResult velocityResult,
    PatientRiskProfile riskProfile,
  ) {
    final parts = <String>[];

    // Current vitals summary
    parts.add(
      'Current vitals: HR ${vitals.heartRate}, '
      'BP ${vitals.systolicBP}/${vitals.diastolicBP}, '
      'RR ${vitals.respiratoryRate}, '
      'Temp ${vitals.temperature.toStringAsFixed(1)}°C, '
      'SpO₂ ${vitals.spO2}%',
    );

    // Velocity summary if concerning
    if (velocityResult.concerningVelocities.isNotEmpty) {
      final velocityParts = velocityResult.concerningVelocities
          .map((v) => v.explanation)
          .join(' ');
      parts.add('Velocity trends: $velocityParts');
    }

    // Risk profile summary
    if (riskProfile.riskProfileLevel.showHighRiskBadge) {
      parts.add(
        'Risk factors: ${riskProfile.shortSummary} '
        '(sensitivity +${((riskProfile.combinedRiskMultiplier - 1) * 100).round()}%)',
      );
    }

    return parts.join('\n\n');
  }

  /// Collect triggering factors for display
  List<String> _collectTriggeringFactors(
    AdjustedRiskResult adjustedRisk,
    VelocityAnalysisResult velocityResult,
    PatientRiskProfile riskProfile,
  ) {
    final factors = <String>[];

    // Velocity-based factors
    for (final v in velocityResult.concerningVelocities) {
      factors.add(
        '${_getVitalTypeName(v.vitalType)} ${v.direction.name} '
        '(${v.absoluteChange > 0 ? '+' : ''}${v.absoluteChange.toStringAsFixed(0)} in ${v.actualTimeSpan.inHours}h)',
      );
    }

    // Risk adjustment factors
    if (adjustedRisk.wasElevated) {
      factors.add('Risk elevated due to patient comorbidities');
    }

    // Sepsis pattern
    if (velocityResult.hasSepsisVelocityPattern) {
      factors.add('Velocity pattern consistent with early sepsis');
    }

    // High-risk profile
    if (riskProfile.riskProfileLevel.showHighRiskBadge) {
      factors.add(
        'Patient classified as ${riskProfile.riskProfileLevel.displayName}',
      );
    }

    return factors;
  }

  /// Generate suggested actions based on urgency and context
  List<EscalationAction> _generateSuggestedActions(
    EscalationUrgency urgency,
    RiskLevel riskLevel,
    VelocityAnalysisResult velocityResult,
    PatientRiskProfile riskProfile,
  ) {
    final actions = <EscalationAction>[];
    int priority = 1;

    // Actions depend on urgency and risk level
    switch (urgency) {
      case EscalationUrgency.urgent:
        actions.add(
          EscalationAction(
            type: EscalationActionType.seniorReview,
            priority: priority++,
          ),
        );
        if (velocityResult.hasSepsisVelocityPattern) {
          actions.add(
            EscalationAction(
              type: EscalationActionType.considerSepsisPathway,
              priority: priority++,
            ),
          );
        }
        actions.add(
          EscalationAction(
            type: EscalationActionType.repeatVitals,
            priority: priority++,
            contextNotes: 'Repeat in 15-30 minutes',
          ),
        );
        break;

      case EscalationUrgency.prompt:
        actions.add(
          EscalationAction(
            type: EscalationActionType.informDutyDoctor,
            priority: priority++,
          ),
        );
        actions.add(
          EscalationAction(
            type: EscalationActionType.bedsideReview,
            priority: priority++,
          ),
        );
        actions.add(
          EscalationAction(
            type: EscalationActionType.repeatVitals,
            priority: priority++,
            contextNotes: 'Repeat in 30 minutes',
          ),
        );
        break;

      case EscalationUrgency.soon:
        actions.add(
          EscalationAction(
            type: EscalationActionType.bedsideReview,
            priority: priority++,
          ),
        );
        actions.add(
          EscalationAction(
            type: EscalationActionType.repeatVitals,
            priority: priority++,
            contextNotes: 'Repeat in 30-60 minutes',
          ),
        );
        actions.add(
          EscalationAction(
            type: EscalationActionType.informNurseInCharge,
            priority: priority++,
          ),
        );
        break;

      case EscalationUrgency.routine:
        actions.add(
          EscalationAction(
            type: EscalationActionType.closeMonitoring,
            priority: priority++,
          ),
        );
        actions.add(
          EscalationAction(
            type: EscalationActionType.repeatVitals,
            priority: priority++,
            contextNotes: 'Repeat in 1-2 hours',
          ),
        );
        break;

      case EscalationUrgency.informational:
        actions.add(
          EscalationAction(
            type: EscalationActionType.documentAssessment,
            priority: priority++,
          ),
        );
        break;
    }

    // Add fluid consideration for hypotension pattern
    if (_hasHypotensionPattern(velocityResult)) {
      actions.add(
        EscalationAction(
          type: EscalationActionType.considerFluids,
          priority: priority++,
        ),
      );
    }

    return actions;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  String _describeVelocityPattern(VelocityAnalysisResult result) {
    final parts = <String>[];

    final hr = result.heartRateVelocity;
    final bp = result.systolicBPVelocity;
    final rr = result.respiratoryRateVelocity;

    if (hr != null && hr.direction == TrendDirection.rising) {
      parts.add('rising heart rate');
    }
    if (bp != null && bp.direction == TrendDirection.falling) {
      parts.add('falling blood pressure');
    }
    if (rr != null && rr.direction == TrendDirection.rising) {
      parts.add('rising respiratory rate');
    }

    return parts.join(', ');
  }

  String _describeVelocityChanges(VelocityAnalysisResult result) {
    final parts = <String>[];

    for (final v in result.concerningVelocities) {
      final name = _getVitalTypeName(v.vitalType);
      final change = v.absoluteChange > 0 ? '+' : '';
      final unit = _getVitalUnit(v.vitalType);
      final hours = v.actualTimeSpan.inHours;
      parts.add(
        '$name $change${v.absoluteChange.toStringAsFixed(0)}$unit in ${hours}h',
      );
    }

    return parts.join(', ');
  }

  bool _hasHypotensionPattern(VelocityAnalysisResult result) {
    final bp = result.systolicBPVelocity;
    return bp != null &&
        bp.direction == TrendDirection.falling &&
        bp.severity.requiresAttention;
  }

  String _getVitalTypeName(VitalType type) {
    switch (type) {
      case VitalType.heartRate:
        return 'Heart rate';
      case VitalType.systolicBP:
        return 'Systolic BP';
      case VitalType.diastolicBP:
        return 'Diastolic BP';
      case VitalType.respiratoryRate:
        return 'Respiratory rate';
      case VitalType.temperature:
        return 'Temperature';
      case VitalType.spO2:
        return 'SpO₂';
    }
  }

  String _getVitalUnit(VitalType type) {
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
}
