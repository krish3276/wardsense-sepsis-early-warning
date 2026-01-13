/// Comorbidity-Aware Risk Adjustment Service
///
/// Adjusts risk interpretation based on patient's comorbidity profile.
/// This is the core implementation for Feature 1.
///
/// CRITICAL PRINCIPLE:
/// "The same vital sign abnormality does not mean the same risk for every patient."
///
/// This service does NOT modify raw vital values. Instead, it:
/// 1. Lowers thresholds for concern in high-risk patients
/// 2. Applies risk multipliers to NEWS-like scores
/// 3. Generates explainable risk adjustments
///
/// Example:
/// - RR 22 + Temp 37.8 in healthy adult → Monitor
/// - RR 22 + Temp 37.8 in Diabetic + CKD patient → Early sepsis alert

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/risk_level.dart';
import '../../domain/entities/patient_risk_profile.dart';
import '../../domain/entities/vital_signs.dart';

/// Provider for the risk adjustment service
final riskAdjustmentServiceProvider = Provider<RiskAdjustmentService>((ref) {
  return RiskAdjustmentService();
});

/// Result of comorbidity-aware risk assessment
class AdjustedRiskResult {
  /// Original risk level (without adjustment)
  final RiskLevel baseRiskLevel;

  /// Adjusted risk level (with comorbidity consideration)
  final RiskLevel adjustedRiskLevel;

  /// Whether the risk level was elevated
  final bool wasElevated;

  /// The risk profile used for adjustment
  final PatientRiskProfile riskProfile;

  /// Original score (e.g., NEWS score)
  final int baseScore;

  /// Adjusted score
  final double adjustedScore;

  /// Human-readable explanation of adjustment
  final String explanation;

  /// List of factors that contributed to adjustment
  final List<String> adjustmentFactors;

  /// Whether to show high-risk badge
  final bool showHighRiskBadge;

  /// Clinical recommendation based on adjusted risk
  final String recommendation;

  AdjustedRiskResult({
    required this.baseRiskLevel,
    required this.adjustedRiskLevel,
    required this.wasElevated,
    required this.riskProfile,
    required this.baseScore,
    required this.adjustedScore,
    required this.explanation,
    required this.adjustmentFactors,
    required this.showHighRiskBadge,
    required this.recommendation,
  });
}

/// Risk Adjustment Service
///
/// Provides comorbidity-aware risk interpretation for vital signs.
class RiskAdjustmentService {
  /// Calculate adjusted risk level based on vitals and patient profile
  ///
  /// This is the main entry point for comorbidity-aware assessment.
  AdjustedRiskResult calculateAdjustedRisk({
    required VitalSigns vitals,
    required PatientRiskProfile riskProfile,
    required int baseNewsScore,
  }) {
    // Calculate base risk level from NEWS score
    final baseRiskLevel = _newsScoreToRiskLevel(baseNewsScore);

    // Get the combined risk multiplier from profile
    final multiplier = riskProfile.combinedRiskMultiplier;

    // Apply multiplier to score
    // This effectively lowers the threshold for concern
    final adjustedScore = baseNewsScore * multiplier;

    // Determine adjusted risk level
    final adjustedRiskLevel = _adjustedScoreToRiskLevel(
      adjustedScore,
      riskProfile,
    );

    // Check if risk was elevated
    final wasElevated = adjustedRiskLevel.index > baseRiskLevel.index;

    // Generate explanation
    final explanation = _generateExplanation(
      baseRiskLevel,
      adjustedRiskLevel,
      riskProfile,
      wasElevated,
    );

    // Collect adjustment factors
    final adjustmentFactors = _collectAdjustmentFactors(riskProfile);

    // Generate recommendation
    final recommendation = _generateRecommendation(
      adjustedRiskLevel,
      riskProfile,
      wasElevated,
    );

    return AdjustedRiskResult(
      baseRiskLevel: baseRiskLevel,
      adjustedRiskLevel: adjustedRiskLevel,
      wasElevated: wasElevated,
      riskProfile: riskProfile,
      baseScore: baseNewsScore,
      adjustedScore: adjustedScore,
      explanation: explanation,
      adjustmentFactors: adjustmentFactors,
      showHighRiskBadge: riskProfile.riskProfileLevel.showHighRiskBadge,
      recommendation: recommendation,
    );
  }

  /// Evaluate specific vital signs against adjusted thresholds
  ///
  /// Returns whether each vital parameter is concerning given the
  /// patient's risk profile.
  Map<String, VitalConcern> evaluateVitalsWithProfile({
    required VitalSigns vitals,
    required PatientRiskProfile riskProfile,
  }) {
    final multiplier = riskProfile.combinedRiskMultiplier;

    return {
      'heartRate': _evaluateHeartRate(vitals.heartRate, multiplier),
      'systolicBP': _evaluateSystolicBP(vitals.systolicBP, multiplier),
      'respiratoryRate': _evaluateRespiratoryRate(
        vitals.respiratoryRate,
        multiplier,
      ),
      'temperature': _evaluateTemperature(vitals.temperature, multiplier),
      'spO2': _evaluateSpO2(vitals.spO2, multiplier),
    };
  }

  /// Check if current vitals meet sepsis screening criteria
  /// with comorbidity adjustment
  SepsisScreeningResult evaluateSepsisRisk({
    required VitalSigns vitals,
    required PatientRiskProfile riskProfile,
  }) {
    final multiplier = riskProfile.combinedRiskMultiplier;
    final criteria = <String>[];
    int qsofaScore = 0;

    // Adjusted qSOFA-like scoring
    // Standard: RR ≥22, SBP ≤100, altered mental status (not available)

    // Adjusted respiratory rate threshold
    final adjustedRRThreshold = (22 / multiplier).round();
    if (vitals.respiratoryRate >= adjustedRRThreshold) {
      qsofaScore++;
      criteria.add(
        'Respiratory rate ${vitals.respiratoryRate}/min (threshold: $adjustedRRThreshold)',
      );
    }

    // Adjusted systolic BP threshold
    final adjustedSBPThreshold = (100 * multiplier).round();
    if (vitals.systolicBP <= adjustedSBPThreshold) {
      qsofaScore++;
      criteria.add(
        'Systolic BP ${vitals.systolicBP} mmHg (threshold: $adjustedSBPThreshold)',
      );
    }

    // Check for fever (sepsis indicator)
    final adjustedFeverThreshold = 38.3 - ((multiplier - 1) * 0.5);
    if (vitals.temperature >= adjustedFeverThreshold) {
      criteria.add(
        'Temperature ${vitals.temperature}°C (threshold: ${adjustedFeverThreshold.toStringAsFixed(1)})',
      );
    }

    // Check for tachycardia
    final adjustedHRThreshold = (100 / multiplier).round();
    if (vitals.heartRate >= adjustedHRThreshold) {
      criteria.add(
        'Heart rate ${vitals.heartRate} bpm (threshold: $adjustedHRThreshold)',
      );
    }

    // Determine screening recommendation
    final shouldScreen = qsofaScore >= 1 || criteria.length >= 2;

    return SepsisScreeningResult(
      qsofaScore: qsofaScore,
      metCriteria: criteria,
      shouldScreenForSepsis: shouldScreen,
      riskMultiplier: multiplier,
      explanation: shouldScreen
          ? 'Consider sepsis screening based on adjusted criteria for high-risk patient.'
          : 'Does not currently meet adjusted sepsis screening criteria.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RISK LEVEL CALCULATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convert NEWS score to risk level (standard thresholds)
  RiskLevel _newsScoreToRiskLevel(int score) {
    if (score >= 7) return RiskLevel.red;
    if (score >= 5) return RiskLevel.orange;
    if (score >= 1) return RiskLevel.yellow;
    return RiskLevel.green;
  }

  /// Convert adjusted score to risk level
  ///
  /// For high-risk patients, we use LOWER thresholds to trigger
  /// earlier escalation.
  RiskLevel _adjustedScoreToRiskLevel(
    double adjustedScore,
    PatientRiskProfile profile,
  ) {
    // Adjust thresholds based on profile level
    switch (profile.riskProfileLevel) {
      case RiskProfileLevel.veryHigh:
        // Very high risk: escalate much earlier
        if (adjustedScore >= 4) return RiskLevel.red;
        if (adjustedScore >= 2.5) return RiskLevel.orange;
        if (adjustedScore >= 0.5) return RiskLevel.yellow;
        return RiskLevel.green;

      case RiskProfileLevel.high:
        // High risk: escalate earlier
        if (adjustedScore >= 5) return RiskLevel.red;
        if (adjustedScore >= 3) return RiskLevel.orange;
        if (adjustedScore >= 1) return RiskLevel.yellow;
        return RiskLevel.green;

      case RiskProfileLevel.elevated:
        // Elevated risk: slightly earlier escalation
        if (adjustedScore >= 6) return RiskLevel.red;
        if (adjustedScore >= 4) return RiskLevel.orange;
        if (adjustedScore >= 1) return RiskLevel.yellow;
        return RiskLevel.green;

      case RiskProfileLevel.standard:
        // Standard thresholds
        return _newsScoreToRiskLevel(adjustedScore.round());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VITAL PARAMETER EVALUATION
  // ═══════════════════════════════════════════════════════════════════════════

  VitalConcern _evaluateHeartRate(int hr, double multiplier) {
    // Adjusted thresholds for tachycardia/bradycardia
    final upperThreshold = (100 / multiplier).round();
    final lowerThreshold = (50 * multiplier).round();

    if (hr > 130 || hr < 40) {
      return VitalConcern.critical;
    }
    if (hr > upperThreshold || hr < lowerThreshold) {
      return VitalConcern.concerning;
    }
    if (hr > 90 || hr < 51) {
      return VitalConcern.borderline;
    }
    return VitalConcern.normal;
  }

  VitalConcern _evaluateSystolicBP(int sbp, double multiplier) {
    // For BP, we're concerned about low values
    // Multiplier RAISES the threshold for concern
    final lowThreshold = (100 * multiplier).round();
    final criticalThreshold = (90 * multiplier).round();

    if (sbp < criticalThreshold) {
      return VitalConcern.critical;
    }
    if (sbp < lowThreshold) {
      return VitalConcern.concerning;
    }
    if (sbp < 111) {
      return VitalConcern.borderline;
    }
    return VitalConcern.normal;
  }

  VitalConcern _evaluateRespiratoryRate(int rr, double multiplier) {
    final upperThreshold = (22 / multiplier).round();
    final criticalThreshold = (25 / multiplier).round();

    if (rr >= criticalThreshold || rr < 8) {
      return VitalConcern.critical;
    }
    if (rr >= upperThreshold) {
      return VitalConcern.concerning;
    }
    if (rr > 20 || rr < 12) {
      return VitalConcern.borderline;
    }
    return VitalConcern.normal;
  }

  VitalConcern _evaluateTemperature(double temp, double multiplier) {
    // Adjust fever threshold DOWN for high-risk patients
    // They may not mount a strong fever response
    final feverThreshold = 38.3 - ((multiplier - 1) * 0.5);

    if (temp > 39.5 || temp < 35.0) {
      return VitalConcern.critical;
    }
    if (temp >= feverThreshold || temp < 36.0) {
      return VitalConcern.concerning;
    }
    if (temp > 38.0 || temp < 36.1) {
      return VitalConcern.borderline;
    }
    return VitalConcern.normal;
  }

  VitalConcern _evaluateSpO2(int spo2, double multiplier) {
    // Adjust hypoxia threshold UP for high-risk patients
    final threshold = (96 + ((multiplier - 1) * 2)).round().clamp(96, 99);

    if (spo2 < 92) {
      return VitalConcern.critical;
    }
    if (spo2 < threshold) {
      return VitalConcern.concerning;
    }
    if (spo2 < 96) {
      return VitalConcern.borderline;
    }
    return VitalConcern.normal;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPLANATION GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  String _generateExplanation(
    RiskLevel baseLevel,
    RiskLevel adjustedLevel,
    PatientRiskProfile profile,
    bool wasElevated,
  ) {
    if (!wasElevated) {
      if (profile.riskProfileLevel == RiskProfileLevel.standard) {
        return 'Standard risk assessment applied. No comorbidity adjustment needed.';
      }
      return 'Comorbidity-adjusted assessment confirms ${adjustedLevel.displayName} status. '
          'Patient risk profile: ${profile.riskProfileLevel.displayName}.';
    }

    final riskPercent = ((profile.combinedRiskMultiplier - 1.0) * 100).round();

    return 'Risk level elevated from ${baseLevel.displayName} to ${adjustedLevel.displayName} '
        'based on patient risk profile.\n\n'
        'Risk sensitivity increased by $riskPercent% due to: ${profile.shortSummary}.\n\n'
        'RATIONALE: The same vital sign abnormality does not mean the same risk for every patient. '
        'This patient\'s reduced physiological reserve warrants earlier escalation.';
  }

  List<String> _collectAdjustmentFactors(PatientRiskProfile profile) {
    final factors = <String>[];

    if (profile.isElderly) {
      factors.add(
        'Age ${profile.age} (${profile.ageCategory.displayName})',
      );
    }

    for (final c in profile.activeComorbidities) {
      factors.add('${c.displayName}: ${c.clinicalRationale}');
    }

    if (profile.hasRecentSurgery) {
      factors.add('Recent surgery within 30 days');
    }

    if (profile.hasRecentHospitalization) {
      factors.add('Recent hospitalization within 90 days');
    }

    if (profile.hasIndwellingDevices) {
      factors.add('Indwelling medical devices present');
    }

    return factors;
  }

  String _generateRecommendation(
    RiskLevel adjustedLevel,
    PatientRiskProfile profile,
    bool wasElevated,
  ) {
    final baseRec = switch (adjustedLevel) {
      RiskLevel.red =>
        'Immediate senior review required. Consider sepsis pathway activation.',
      RiskLevel.orange =>
        'Notify duty doctor promptly. Increase monitoring frequency.',
      RiskLevel.yellow =>
        'Close monitoring advised. Repeat vitals in 1-2 hours.',
      RiskLevel.green => 'Continue routine monitoring as per protocol.',
    };

    if (wasElevated && profile.riskProfileLevel.showHighRiskBadge) {
      return '$baseRec\n\nNote: This patient has a HIGH-RISK PROFILE. '
          'Lower threshold for escalation is appropriate.';
    }

    return baseRec;
  }
}

/// Level of concern for a vital parameter
enum VitalConcern {
  normal,
  borderline,
  concerning,
  critical,
}

extension VitalConcernExtension on VitalConcern {
  String get displayName {
    switch (this) {
      case VitalConcern.normal:
        return 'Normal';
      case VitalConcern.borderline:
        return 'Borderline';
      case VitalConcern.concerning:
        return 'Concerning';
      case VitalConcern.critical:
        return 'Critical';
    }
  }

  bool get isConcerning =>
      this == VitalConcern.concerning || this == VitalConcern.critical;
}

/// Result of sepsis screening evaluation
class SepsisScreeningResult {
  final int qsofaScore;
  final List<String> metCriteria;
  final bool shouldScreenForSepsis;
  final double riskMultiplier;
  final String explanation;

  SepsisScreeningResult({
    required this.qsofaScore,
    required this.metCriteria,
    required this.shouldScreenForSepsis,
    required this.riskMultiplier,
    required this.explanation,
  });
}
