/// Patient Risk Profile entity
///
/// Comprehensive risk profile combining patient demographics, comorbidities,
/// and derived risk sensitivity adjustments.
///
/// CORE PRINCIPLE:
/// "The same vital sign abnormality does not mean the same risk for every patient."
///
/// This entity does NOT modify raw vital values. Instead, it adjusts
/// the INTERPRETATION sensitivity for risk calculations.

import 'package:equatable/equatable.dart';
import 'comorbidity.dart';

/// Age-based risk categories
///
/// Age is an independent risk factor for sepsis mortality.
/// Elderly patients (≥65) have reduced physiological reserve.
enum AgeRiskCategory {
  /// Young adult (18-44): baseline risk
  youngAdult,

  /// Middle aged (45-64): slightly elevated risk
  middleAged,

  /// Elderly (65-74): significantly elevated risk
  elderly,

  /// Very elderly (≥75): highest age-related risk
  veryElderly,
}

extension AgeRiskCategoryExtension on AgeRiskCategory {
  String get displayName {
    switch (this) {
      case AgeRiskCategory.youngAdult:
        return 'Young Adult (18-44)';
      case AgeRiskCategory.middleAged:
        return 'Middle Aged (45-64)';
      case AgeRiskCategory.elderly:
        return 'Elderly (65-74)';
      case AgeRiskCategory.veryElderly:
        return 'Very Elderly (75+)';
    }
  }

  /// Age-based risk multiplier
  ///
  /// Based on clinical evidence showing increased sepsis mortality
  /// with advancing age.
  double get riskMultiplier {
    switch (this) {
      case AgeRiskCategory.youngAdult:
        return 1.0; // Baseline
      case AgeRiskCategory.middleAged:
        return 1.1; // 10% increased sensitivity
      case AgeRiskCategory.elderly:
        return 1.25; // 25% increased sensitivity
      case AgeRiskCategory.veryElderly:
        return 1.4; // 40% increased sensitivity
    }
  }
}

/// Overall risk profile classification
enum RiskProfileLevel {
  /// No significant risk factors
  standard,

  /// Some risk factors present (1 comorbidity or elderly)
  elevated,

  /// Multiple risk factors (2+ comorbidities or very elderly + comorbidity)
  high,

  /// Severe risk profile (3+ comorbidities or immunosuppression + others)
  veryHigh,
}

extension RiskProfileLevelExtension on RiskProfileLevel {
  String get displayName {
    switch (this) {
      case RiskProfileLevel.standard:
        return 'Standard Risk';
      case RiskProfileLevel.elevated:
        return 'Elevated Risk';
      case RiskProfileLevel.high:
        return 'High Risk';
      case RiskProfileLevel.veryHigh:
        return 'Very High Risk';
    }
  }

  String get shortLabel {
    switch (this) {
      case RiskProfileLevel.standard:
        return 'Standard';
      case RiskProfileLevel.elevated:
        return 'Elevated';
      case RiskProfileLevel.high:
        return 'High';
      case RiskProfileLevel.veryHigh:
        return 'Very High';
    }
  }

  /// Whether to show the high-risk badge in UI
  bool get showHighRiskBadge => this != RiskProfileLevel.standard;
}

/// Patient Risk Profile
///
/// Encapsulates all factors that modify how we interpret vital sign
/// abnormalities for a specific patient.
class PatientRiskProfile extends Equatable {
  /// Patient ID reference
  final String patientId;

  /// Patient age in years
  final int age;

  /// List of active comorbidities
  final List<Comorbidity> comorbidities;

  /// Recent surgery (within 30 days) - increases infection risk
  final bool hasRecentSurgery;

  /// Recent hospitalization (within 90 days) - increased HAI risk
  final bool hasRecentHospitalization;

  /// Presence of indwelling devices (catheter, central line)
  final bool hasIndwellingDevices;

  /// Known allergies that may affect treatment
  final List<String> allergies;

  /// Timestamp when profile was last updated
  final DateTime lastUpdated;

  /// Clinical notes about risk factors
  final String? notes;

  const PatientRiskProfile({
    required this.patientId,
    required this.age,
    this.comorbidities = const [],
    this.hasRecentSurgery = false,
    this.hasRecentHospitalization = false,
    this.hasIndwellingDevices = false,
    this.allergies = const [],
    required this.lastUpdated,
    this.notes,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPUTED RISK PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get age risk category
  AgeRiskCategory get ageCategory {
    if (age >= 75) return AgeRiskCategory.veryElderly;
    if (age >= 65) return AgeRiskCategory.elderly;
    if (age >= 45) return AgeRiskCategory.middleAged;
    return AgeRiskCategory.youngAdult;
  }

  /// Whether patient is considered elderly (≥65 years)
  bool get isElderly => age >= 65;

  /// Whether patient has any active comorbidities
  bool get hasComorbidities => activeComorbidities.isNotEmpty;

  /// Get only active comorbidities
  List<Comorbidity> get activeComorbidities =>
      comorbidities.where((c) => c.isActive).toList();

  /// Count of active comorbidities
  int get comorbidityCount => activeComorbidities.length;

  /// Whether patient has immunosuppression
  bool get isImmunosuppressed => activeComorbidities.any(
        (c) => c.type == ComorbidityType.immunosuppression,
      );

  /// Calculate combined risk sensitivity multiplier
  ///
  /// ALGORITHM:
  /// 1. Start with age-based multiplier
  /// 2. Add comorbidity contributions (capped to avoid excessive amplification)
  /// 3. Add modifiers for surgery, hospitalization, devices
  ///
  /// The final multiplier is used to LOWER thresholds for concern,
  /// effectively making us MORE sensitive to smaller deviations
  /// in high-risk patients.
  double get combinedRiskMultiplier {
    double multiplier = ageCategory.riskMultiplier;

    // Add comorbidity contributions
    // Use diminishing returns to avoid extreme values
    if (activeComorbidities.isNotEmpty) {
      // Sort by risk to prioritize highest risk comorbidities
      final sortedComorbidities = List<Comorbidity>.from(activeComorbidities)
        ..sort((a, b) => b.riskMultiplier.compareTo(a.riskMultiplier));

      // First comorbidity: full contribution
      // Second: 50% contribution
      // Third+: 25% each
      for (int i = 0; i < sortedComorbidities.length; i++) {
        final comorbidityContribution =
            sortedComorbidities[i].riskMultiplier - 1.0;
        if (i == 0) {
          multiplier += comorbidityContribution;
        } else if (i == 1) {
          multiplier += comorbidityContribution * 0.5;
        } else {
          multiplier += comorbidityContribution * 0.25;
        }
      }
    }

    // Additional risk modifiers
    if (hasRecentSurgery) multiplier += 0.1;
    if (hasRecentHospitalization) multiplier += 0.1;
    if (hasIndwellingDevices) multiplier += 0.15;

    // Cap at 2.5x to maintain clinical validity
    return multiplier.clamp(1.0, 2.5);
  }

  /// Get overall risk profile level
  RiskProfileLevel get riskProfileLevel {
    final multiplier = combinedRiskMultiplier;

    if (multiplier >= 2.0 || (isImmunosuppressed && comorbidityCount >= 2)) {
      return RiskProfileLevel.veryHigh;
    }
    if (multiplier >= 1.6 || comorbidityCount >= 2) {
      return RiskProfileLevel.high;
    }
    if (multiplier >= 1.2 || comorbidityCount >= 1 || isElderly) {
      return RiskProfileLevel.elevated;
    }
    return RiskProfileLevel.standard;
  }

  /// Generate human-readable explanation of why risk is adjusted
  ///
  /// This is critical for trust and explainability.
  /// Clinicians must understand WHY the system is more sensitive.
  String get riskExplanation {
    if (riskProfileLevel == RiskProfileLevel.standard) {
      return 'Standard risk profile - no significant risk factors identified.';
    }

    final factors = <String>[];

    // Age factor
    if (isElderly) {
      factors.add('${ageCategory.displayName} (reduced physiological reserve)');
    }

    // Comorbidity factors
    for (final c in activeComorbidities) {
      factors.add('${c.displayName}: ${c.clinicalRationale}');
    }

    // Additional factors
    if (hasRecentSurgery) {
      factors.add('Recent surgery within 30 days');
    }
    if (hasRecentHospitalization) {
      factors.add('Recent hospitalization within 90 days');
    }
    if (hasIndwellingDevices) {
      factors.add('Indwelling medical devices present');
    }

    final riskPercent = ((combinedRiskMultiplier - 1.0) * 100).round();
    final header =
        'Risk sensitivity increased by $riskPercent% due to the following factors:';

    return '$header\n\n• ${factors.join('\n• ')}';
  }

  /// Get short summary for card display
  String get shortSummary {
    final parts = <String>[];

    if (isElderly) parts.add('Elderly');
    for (final c in activeComorbidities.take(3)) {
      parts.add(c.type.shortCode);
    }
    if (activeComorbidities.length > 3) {
      parts.add('+${activeComorbidities.length - 3}');
    }

    return parts.isEmpty ? 'No risk factors' : parts.join(' • ');
  }

  /// Get list of comorbidity short codes for badge display
  List<String> get comorbidityBadges =>
      activeComorbidities.map((c) => c.type.shortCode).toList();

  @override
  List<Object?> get props => [
        patientId,
        age,
        comorbidities,
        hasRecentSurgery,
        hasRecentHospitalization,
        hasIndwellingDevices,
        allergies,
        lastUpdated,
        notes,
      ];

  PatientRiskProfile copyWith({
    String? patientId,
    int? age,
    List<Comorbidity>? comorbidities,
    bool? hasRecentSurgery,
    bool? hasRecentHospitalization,
    bool? hasIndwellingDevices,
    List<String>? allergies,
    DateTime? lastUpdated,
    String? notes,
  }) {
    return PatientRiskProfile(
      patientId: patientId ?? this.patientId,
      age: age ?? this.age,
      comorbidities: comorbidities ?? this.comorbidities,
      hasRecentSurgery: hasRecentSurgery ?? this.hasRecentSurgery,
      hasRecentHospitalization:
          hasRecentHospitalization ?? this.hasRecentHospitalization,
      hasIndwellingDevices: hasIndwellingDevices ?? this.hasIndwellingDevices,
      allergies: allergies ?? this.allergies,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notes: notes ?? this.notes,
    );
  }

  /// Create an empty/default profile for a patient
  factory PatientRiskProfile.empty(String patientId, int age) {
    return PatientRiskProfile(
      patientId: patientId,
      age: age,
      lastUpdated: DateTime.now(),
    );
  }
}
