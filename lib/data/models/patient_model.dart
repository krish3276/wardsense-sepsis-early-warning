/// Hive data model for Patient
///
/// Hive-compatible model with type adapters for local persistence.
/// Maps to/from the domain Patient entity.

import 'package:hive/hive.dart';
import '../../../domain/entities/patient.dart';
import '../../../domain/entities/comorbidity.dart';
import '../../../core/constants/risk_level.dart';

part 'patient_model.g.dart';

@HiveType(typeId: 0)
class PatientModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String bedId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final int age;

  @HiveField(4)
  final String gender;

  @HiveField(5)
  final String? medicalRecordNumber;

  @HiveField(6)
  final DateTime admissionDate;

  @HiveField(7)
  final String wardName;

  @HiveField(8)
  final int currentRiskLevelIndex;

  @HiveField(9)
  final DateTime? lastVitalsTime;

  @HiveField(10)
  final bool isMonitored;

  @HiveField(11)
  final String? notes;

  @HiveField(12)
  final bool isActive;

  /// Stores comorbidity type indices for persistence
  @HiveField(13)
  final List<int> comorbidityTypeIndices;

  /// Stores comorbidity severity values (0=mild, 1=moderate, 2=severe)
  @HiveField(14)
  final List<int> comorbiditySeverityIndices;

  PatientModel({
    required this.id,
    required this.bedId,
    required this.name,
    required this.age,
    required this.gender,
    this.medicalRecordNumber,
    required this.admissionDate,
    required this.wardName,
    this.currentRiskLevelIndex = 0,
    this.lastVitalsTime,
    this.isMonitored = false,
    this.notes,
    this.isActive = true,
    this.comorbidityTypeIndices = const [],
    this.comorbiditySeverityIndices = const [],
  });

  /// Map severity index to string
  static const _severityLabels = ['mild', 'moderate', 'severe'];

  /// Convert comorbidity indices to domain entities
  List<Comorbidity> _parseComorbidities() {
    if (comorbidityTypeIndices.isEmpty) return [];

    final result = <Comorbidity>[];
    for (int i = 0; i < comorbidityTypeIndices.length; i++) {
      final typeIndex = comorbidityTypeIndices[i];
      final severityIndex = i < comorbiditySeverityIndices.length
          ? comorbiditySeverityIndices[i].clamp(0, 2)
          : 1; // default to moderate

      if (typeIndex >= 0 && typeIndex < ComorbidityType.values.length) {
        result.add(Comorbidity(
          type: ComorbidityType.values[typeIndex],
          severity: _severityLabels[severityIndex],
        ));
      }
    }
    return result;
  }

  /// Map severity string to index
  static int _severityToIndex(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'mild':
        return 0;
      case 'moderate':
        return 1;
      case 'severe':
        return 2;
      default:
        return 1; // default to moderate
    }
  }

  /// Convert from domain entity
  factory PatientModel.fromEntity(Patient patient) {
    return PatientModel(
      id: patient.id,
      bedId: patient.bedId,
      name: patient.name,
      age: patient.age,
      gender: patient.gender,
      medicalRecordNumber: patient.medicalRecordNumber,
      admissionDate: patient.admissionDate,
      wardName: patient.wardName,
      currentRiskLevelIndex: patient.currentRiskLevel.index,
      lastVitalsTime: patient.lastVitalsTime,
      isMonitored: patient.isMonitored,
      notes: patient.notes,
      isActive: patient.isActive,
      comorbidityTypeIndices:
          patient.comorbidities.map((c) => c.type.index).toList(),
      comorbiditySeverityIndices: patient.comorbidities
          .map((c) => _severityToIndex(c.severity))
          .toList(),
    );
  }

  /// Convert to domain entity
  Patient toEntity() {
    return Patient(
      id: id,
      bedId: bedId,
      name: name,
      age: age,
      gender: gender,
      medicalRecordNumber: medicalRecordNumber,
      admissionDate: admissionDate,
      wardName: wardName,
      currentRiskLevel: RiskLevel.values[currentRiskLevelIndex],
      lastVitalsTime: lastVitalsTime,
      isMonitored: isMonitored,
      notes: notes,
      isActive: isActive,
      comorbidities: _parseComorbidities(),
    );
  }

  /// Create updated model with new risk level
  PatientModel copyWithRiskLevel(RiskLevel level, DateTime? vitalsTime) {
    return PatientModel(
      id: id,
      bedId: bedId,
      name: name,
      age: age,
      gender: gender,
      medicalRecordNumber: medicalRecordNumber,
      admissionDate: admissionDate,
      wardName: wardName,
      currentRiskLevelIndex: level.index,
      lastVitalsTime: vitalsTime ?? lastVitalsTime,
      isMonitored: isMonitored,
      notes: notes,
      isActive: isActive,
      comorbidityTypeIndices: comorbidityTypeIndices,
      comorbiditySeverityIndices: comorbiditySeverityIndices,
    );
  }
}
