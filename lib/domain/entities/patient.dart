/// Patient entity representing a patient in the ward
///
/// Core domain entity that holds patient identification and metadata.
/// This is the central entity around which vital signs and alerts are organized.

import 'package:equatable/equatable.dart';
import '../../core/constants/risk_level.dart';
import 'comorbidity.dart';
import 'patient_risk_profile.dart';

/// Patient entity
///
/// Represents a patient currently admitted in the ward.
/// Used for patient identification and as a reference for vital signs.
class Patient extends Equatable {
  /// Unique identifier for the patient
  final String id;

  /// Hospital/ward bed identifier (e.g., "5A", "ICU-3")
  final String bedId;

  /// Patient's full name
  final String name;

  /// Patient's age in years
  final int age;

  /// Patient's gender (M/F/O)
  final String gender;

  /// Medical record number or hospital ID
  final String? medicalRecordNumber;

  /// Admission date and time
  final DateTime admissionDate;

  /// Ward or unit name
  final String wardName;

  /// Current risk level (computed from latest vital signs)
  final RiskLevel currentRiskLevel;

  /// Timestamp of last vital signs entry
  final DateTime? lastVitalsTime;

  /// Whether the patient is currently flagged for close monitoring
  final bool isMonitored;

  /// Optional notes about the patient
  final String? notes;

  /// Whether the patient is active (not discharged)
  final bool isActive;

  /// Patient's comorbidities for risk adjustment
  final List<Comorbidity> comorbidities;

  const Patient({
    required this.id,
    required this.bedId,
    required this.name,
    required this.age,
    required this.gender,
    required this.admissionDate,
    required this.wardName,
    this.medicalRecordNumber,
    this.currentRiskLevel = RiskLevel.green,
    this.lastVitalsTime,
    this.isMonitored = false,
    this.notes,
    this.isActive = true,
    this.comorbidities = const [],
  });

  /// Create a copy with updated fields
  Patient copyWith({
    String? id,
    String? bedId,
    String? name,
    int? age,
    String? gender,
    String? medicalRecordNumber,
    DateTime? admissionDate,
    String? wardName,
    RiskLevel? currentRiskLevel,
    DateTime? lastVitalsTime,
    bool? isMonitored,
    String? notes,
    bool? isActive,
    List<Comorbidity>? comorbidities,
  }) {
    return Patient(
      id: id ?? this.id,
      bedId: bedId ?? this.bedId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      medicalRecordNumber: medicalRecordNumber ?? this.medicalRecordNumber,
      admissionDate: admissionDate ?? this.admissionDate,
      wardName: wardName ?? this.wardName,
      currentRiskLevel: currentRiskLevel ?? this.currentRiskLevel,
      lastVitalsTime: lastVitalsTime ?? this.lastVitalsTime,
      isMonitored: isMonitored ?? this.isMonitored,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      comorbidities: comorbidities ?? this.comorbidities,
    );
  }

  /// Get the patient's age-based risk category
  AgeRiskCategory get ageRiskCategory {
    if (age >= 75) return AgeRiskCategory.veryElderly;
    if (age >= 65) return AgeRiskCategory.elderly;
    if (age >= 45) return AgeRiskCategory.middleAged;
    return AgeRiskCategory.youngAdult;
  }

  /// Generate a risk profile for this patient
  PatientRiskProfile get riskProfile => PatientRiskProfile(
        patientId: id,
        age: age,
        comorbidities: comorbidities,
        lastUpdated: DateTime.now(),
      );

  /// Check if patient has any high-risk comorbidities
  bool get hasHighRiskComorbidities => comorbidities.any((c) =>
      c.type == ComorbidityType.immunosuppression ||
      c.type == ComorbidityType.chronicKidneyDisease ||
      c.type == ComorbidityType.liverCirrhosis);

  /// Get display string for comorbidities
  String get comorbiditiesDisplay {
    if (comorbidities.isEmpty) return 'None documented';
    return comorbidities.map((c) => c.type.shortCode).join(', ');
  }

  /// Get formatted display name (Last, First)
  String get displayName => name;

  /// Get short display for bed (e.g., "Bed 5A")
  String get bedDisplay {
    if (bedId.toLowerCase().startsWith('bed')) {
      return bedId;
    }
    return 'Bed $bedId';
  }

  /// Get age display (e.g., "45 years")
  String get ageDisplay => '$age years';

  /// Get gender display (e.g., "Male")
  String get genderDisplay {
    switch (gender.toUpperCase()) {
      case 'M':
        return 'Male';
      case 'F':
        return 'Female';
      default:
        return 'Other';
    }
  }

  /// Check if vitals are overdue based on current risk level
  bool get isVitalsOverdue {
    if (lastVitalsTime == null) return true;

    final now = DateTime.now();
    final overdueDuration = Duration(
      minutes: currentRiskLevel.monitoringIntervalMinutes,
    );

    return now.difference(lastVitalsTime!) > overdueDuration;
  }

  /// Get time since last vitals reading
  Duration? get timeSinceLastVitals {
    if (lastVitalsTime == null) return null;
    return DateTime.now().difference(lastVitalsTime!);
  }

  @override
  List<Object?> get props => [
        id,
        bedId,
        name,
        age,
        gender,
        medicalRecordNumber,
        admissionDate,
        wardName,
        currentRiskLevel,
        lastVitalsTime,
        isMonitored,
        notes,
        isActive,
        comorbidities,
      ];
}
