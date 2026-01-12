/// Hive data model for Patient
///
/// Hive-compatible model with type adapters for local persistence.
/// Maps to/from the domain Patient entity.

import 'package:hive/hive.dart';
import '../../../domain/entities/patient.dart';
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
  });

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
    );
  }
}
