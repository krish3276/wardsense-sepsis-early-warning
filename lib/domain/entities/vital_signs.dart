/// Vital signs entity representing a single vital signs measurement
///
/// Core domain entity that captures all vital parameters collected
/// during a single patient assessment. Designed for intermittent
/// monitoring in general hospital wards.

import 'package:equatable/equatable.dart';

/// AVPU consciousness level scale
/// Used in NEWS2 scoring for neurological assessment
enum ConsciousnessLevel {
  /// Alert - Patient is fully awake and responsive
  alert,

  /// Voice - Patient responds to verbal stimuli
  voice,

  /// Pain - Patient responds only to painful stimuli
  pain,

  /// Unresponsive - Patient does not respond to any stimuli
  unresponsive,
}

/// Extension for ConsciousnessLevel display properties
extension ConsciousnessLevelExtension on ConsciousnessLevel {
  /// Display name for UI
  String get displayName {
    switch (this) {
      case ConsciousnessLevel.alert:
        return 'Alert';
      case ConsciousnessLevel.voice:
        return 'Voice';
      case ConsciousnessLevel.pain:
        return 'Pain';
      case ConsciousnessLevel.unresponsive:
        return 'Unresponsive';
    }
  }

  /// Short code (A, V, P, U)
  String get code {
    switch (this) {
      case ConsciousnessLevel.alert:
        return 'A';
      case ConsciousnessLevel.voice:
        return 'V';
      case ConsciousnessLevel.pain:
        return 'P';
      case ConsciousnessLevel.unresponsive:
        return 'U';
    }
  }

  /// NEWS2 score contribution (Alert = 0, others = 3)
  int get newsScore {
    return this == ConsciousnessLevel.alert ? 0 : 3;
  }
}

/// Vital signs entity
///
/// Represents a complete set of vital signs taken at a specific time.
/// All vital parameters are required for accurate risk assessment.
class VitalSigns extends Equatable {
  /// Unique identifier for this vital signs entry
  final String id;

  /// Reference to the patient
  final String patientId;

  /// Heart rate in beats per minute
  final int heartRate;

  /// Systolic blood pressure in mmHg
  final int systolicBP;

  /// Diastolic blood pressure in mmHg
  final int diastolicBP;

  /// Respiratory rate in breaths per minute
  final int respiratoryRate;

  /// Body temperature in Celsius
  final double temperature;

  /// Oxygen saturation percentage
  final int spO2;

  /// Whether patient is on supplemental oxygen
  /// Important for NEWS2 SpO2 scoring (Scale 1 vs Scale 2)
  final bool isOnSupplementalOxygen;

  /// Consciousness level using AVPU scale
  /// A = Alert, V = Voice, P = Pain, U = Unresponsive
  final ConsciousnessLevel consciousnessLevel;

  /// Timestamp when vitals were measured (not when entered)
  final DateTime timestamp;

  /// Timestamp when this entry was created in the system
  final DateTime createdAt;

  /// ID of the user who recorded the vitals (nurse/doctor)
  final String? recordedBy;

  /// Optional notes about this measurement
  final String? notes;

  /// Whether this reading has been reviewed by a doctor
  final bool isReviewed;

  /// Computed NEWS score for this reading (if calculated)
  final int? newsScore;

  const VitalSigns({
    required this.id,
    required this.patientId,
    required this.heartRate,
    required this.systolicBP,
    required this.diastolicBP,
    required this.respiratoryRate,
    required this.temperature,
    required this.spO2,
    required this.timestamp,
    required this.createdAt,
    this.isOnSupplementalOxygen = false,
    this.consciousnessLevel = ConsciousnessLevel.alert,
    this.recordedBy,
    this.notes,
    this.isReviewed = false,
    this.newsScore,
  });

  /// Create a copy with updated fields
  VitalSigns copyWith({
    String? id,
    String? patientId,
    int? heartRate,
    int? systolicBP,
    int? diastolicBP,
    int? respiratoryRate,
    double? temperature,
    int? spO2,
    bool? isOnSupplementalOxygen,
    ConsciousnessLevel? consciousnessLevel,
    DateTime? timestamp,
    DateTime? createdAt,
    String? recordedBy,
    String? notes,
    bool? isReviewed,
    int? newsScore,
  }) {
    return VitalSigns(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      heartRate: heartRate ?? this.heartRate,
      systolicBP: systolicBP ?? this.systolicBP,
      diastolicBP: diastolicBP ?? this.diastolicBP,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      temperature: temperature ?? this.temperature,
      spO2: spO2 ?? this.spO2,
      isOnSupplementalOxygen:
          isOnSupplementalOxygen ?? this.isOnSupplementalOxygen,
      consciousnessLevel: consciousnessLevel ?? this.consciousnessLevel,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      recordedBy: recordedBy ?? this.recordedBy,
      notes: notes ?? this.notes,
      isReviewed: isReviewed ?? this.isReviewed,
      newsScore: newsScore ?? this.newsScore,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mean arterial pressure (MAP)
  /// MAP = DBP + 1/3(SBP - DBP)
  double get meanArterialPressure {
    return diastolicBP + (systolicBP - diastolicBP) / 3;
  }

  /// Pulse pressure (difference between systolic and diastolic)
  int get pulsePressure => systolicBP - diastolicBP;

  /// Blood pressure as formatted string
  String get bloodPressureDisplay => '$systolicBP/$diastolicBP';

  /// Heart rate display with unit
  String get heartRateDisplay => '$heartRate bpm';

  /// Respiratory rate display with unit
  String get respiratoryRateDisplay => '$respiratoryRate /min';

  /// Temperature display with unit
  String get temperatureDisplay => '${temperature.toStringAsFixed(1)}°C';

  /// SpO2 display with unit
  String get spO2Display => '$spO2%';

  /// Check if heart rate is abnormal
  bool get isHeartRateAbnormal => heartRate < 51 || heartRate > 90;

  /// Check if blood pressure is abnormal
  bool get isBloodPressureAbnormal => systolicBP < 111 || systolicBP > 219;

  /// Check if respiratory rate is abnormal
  bool get isRespiratoryRateAbnormal =>
      respiratoryRate < 12 || respiratoryRate > 20;

  /// Check if temperature is abnormal
  bool get isTemperatureAbnormal => temperature < 36.1 || temperature > 38.0;

  /// Check if SpO2 is abnormal
  bool get isSpO2Abnormal => spO2 < 96;

  /// Get count of abnormal vital signs
  int get abnormalVitalsCount {
    int count = 0;
    if (isHeartRateAbnormal) count++;
    if (isBloodPressureAbnormal) count++;
    if (isRespiratoryRateAbnormal) count++;
    if (isTemperatureAbnormal) count++;
    if (isSpO2Abnormal) count++;
    return count;
  }

  /// Check if consciousness is abnormal (not Alert)
  bool get isConsciousnessAbnormal =>
      consciousnessLevel != ConsciousnessLevel.alert;

  /// Consciousness level display
  String get consciousnessDisplay => consciousnessLevel.displayName;

  /// AVPU code display
  String get avpuCode => consciousnessLevel.code;

  @override
  List<Object?> get props => [
        id,
        patientId,
        heartRate,
        systolicBP,
        diastolicBP,
        respiratoryRate,
        temperature,
        spO2,
        isOnSupplementalOxygen,
        consciousnessLevel,
        timestamp,
        createdAt,
        recordedBy,
        notes,
        isReviewed,
        newsScore,
      ];
}
