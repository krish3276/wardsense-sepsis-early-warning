/// Comorbidity entity representing patient comorbid conditions
///
/// Comorbidities significantly affect sepsis risk interpretation.
/// A patient with multiple comorbidities may show deterioration earlier
/// or have reduced physiological reserve to compensate.
///
/// CLINICAL RATIONALE:
/// "The same vital sign abnormality does not mean the same risk for every patient."
/// - A healthy 30-year-old with HR 100 may be dehydrated
/// - A 70-year-old diabetic with CKD and HR 100 may be developing sepsis

import 'package:equatable/equatable.dart';

/// Supported comorbid conditions that affect sepsis risk sensitivity
///
/// Each comorbidity carries a risk weight that adjusts interpretation
/// of vital signs without modifying the raw values.
enum ComorbidityType {
  /// Diabetes Mellitus - impairs immune response, masks fever
  /// Risk multiplier: 1.3x
  diabetesMellitus,

  /// Chronic Kidney Disease - reduced ability to handle infection
  /// Risk multiplier: 1.4x
  chronicKidneyDisease,

  /// Chronic Obstructive Pulmonary Disease - compromised respiratory reserve
  /// Risk multiplier: 1.3x
  copd,

  /// Immunosuppression (steroids, chemotherapy, HIV, transplant)
  /// Risk multiplier: 1.5x
  immunosuppression,

  /// Heart Failure - reduced cardiac reserve
  /// Risk multiplier: 1.3x
  heartFailure,

  /// Liver Cirrhosis - impaired clotting, immune dysfunction
  /// Risk multiplier: 1.4x
  liverCirrhosis,

  /// Malignancy/Cancer - immunocompromised state
  /// Risk multiplier: 1.4x
  malignancy,
}

/// Extension methods for ComorbidityType
extension ComorbidityTypeExtension on ComorbidityType {
  /// Human-readable display name
  String get displayName {
    switch (this) {
      case ComorbidityType.diabetesMellitus:
        return 'Diabetes Mellitus';
      case ComorbidityType.chronicKidneyDisease:
        return 'Chronic Kidney Disease (CKD)';
      case ComorbidityType.copd:
        return 'COPD';
      case ComorbidityType.immunosuppression:
        return 'Immunosuppression';
      case ComorbidityType.heartFailure:
        return 'Heart Failure';
      case ComorbidityType.liverCirrhosis:
        return 'Liver Cirrhosis';
      case ComorbidityType.malignancy:
        return 'Malignancy';
    }
  }

  /// Short code for compact display
  String get shortCode {
    switch (this) {
      case ComorbidityType.diabetesMellitus:
        return 'DM';
      case ComorbidityType.chronicKidneyDisease:
        return 'CKD';
      case ComorbidityType.copd:
        return 'COPD';
      case ComorbidityType.immunosuppression:
        return 'IMMUNO';
      case ComorbidityType.heartFailure:
        return 'HF';
      case ComorbidityType.liverCirrhosis:
        return 'LIVER';
      case ComorbidityType.malignancy:
        return 'MALIG';
    }
  }

  /// Risk sensitivity multiplier for this comorbidity
  ///
  /// Applied to threshold-based risk calculations.
  /// Values based on clinical literature showing increased sepsis
  /// mortality in patients with these conditions.
  double get riskMultiplier {
    switch (this) {
      case ComorbidityType.diabetesMellitus:
        return 1.3; // 30% increased sensitivity
      case ComorbidityType.chronicKidneyDisease:
        return 1.4; // 40% increased sensitivity
      case ComorbidityType.copd:
        return 1.3;
      case ComorbidityType.immunosuppression:
        return 1.5; // Highest risk - immune system compromised
      case ComorbidityType.heartFailure:
        return 1.3;
      case ComorbidityType.liverCirrhosis:
        return 1.4;
      case ComorbidityType.malignancy:
        return 1.4;
    }
  }

  /// Clinical explanation for why this comorbidity increases risk
  String get clinicalRationale {
    switch (this) {
      case ComorbidityType.diabetesMellitus:
        return 'Impaired immune response and may mask typical fever response';
      case ComorbidityType.chronicKidneyDisease:
        return 'Reduced ability to clear infection, fluid imbalance vulnerability';
      case ComorbidityType.copd:
        return 'Compromised respiratory reserve, rapid deterioration possible';
      case ComorbidityType.immunosuppression:
        return 'Weakened immune system, atypical infection presentation';
      case ComorbidityType.heartFailure:
        return 'Reduced cardiac reserve to compensate for sepsis stress';
      case ComorbidityType.liverCirrhosis:
        return 'Impaired clotting, immune dysfunction, portal hypertension';
      case ComorbidityType.malignancy:
        return 'Immunocompromised state, may have treatment-related neutropenia';
    }
  }

  /// Icon suggestion for UI
  String get iconName {
    switch (this) {
      case ComorbidityType.diabetesMellitus:
        return 'bloodtype';
      case ComorbidityType.chronicKidneyDisease:
        return 'water_drop';
      case ComorbidityType.copd:
        return 'air';
      case ComorbidityType.immunosuppression:
        return 'shield';
      case ComorbidityType.heartFailure:
        return 'heart_broken';
      case ComorbidityType.liverCirrhosis:
        return 'science';
      case ComorbidityType.malignancy:
        return 'healing';
    }
  }
}

/// Comorbidity entity with additional patient-specific data
class Comorbidity extends Equatable {
  /// The type of comorbidity
  final ComorbidityType type;

  /// Optional severity level (mild, moderate, severe)
  final String? severity;

  /// Date when diagnosed or documented
  final DateTime? diagnosedDate;

  /// Additional clinical notes
  final String? notes;

  /// Whether this condition is currently active/relevant
  final bool isActive;

  const Comorbidity({
    required this.type,
    this.severity,
    this.diagnosedDate,
    this.notes,
    this.isActive = true,
  });

  /// Get display name from type
  String get displayName => type.displayName;

  /// Get risk multiplier from type
  double get riskMultiplier => type.riskMultiplier;

  /// Get clinical rationale from type
  String get clinicalRationale => type.clinicalRationale;

  @override
  List<Object?> get props => [type, severity, diagnosedDate, notes, isActive];

  Comorbidity copyWith({
    ComorbidityType? type,
    String? severity,
    DateTime? diagnosedDate,
    String? notes,
    bool? isActive,
  }) {
    return Comorbidity(
      type: type ?? this.type,
      severity: severity ?? this.severity,
      diagnosedDate: diagnosedDate ?? this.diagnosedDate,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }
}
