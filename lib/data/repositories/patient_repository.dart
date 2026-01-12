/// Patient repository for data access
///
/// Provides access to patient data with offline-first architecture.
/// Uses Hive for local persistence.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/risk_level.dart';
import '../../domain/entities/patient.dart';
import '../models/patient_model.dart';

/// Provider for patient repository
final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository();
});

/// Repository for patient data operations
class PatientRepository {
  Box get _box => Hive.box(AppConstants.patientsBox);

  /// Get all active patients
  List<Patient> getAllPatients() {
    return _box.values
        .cast<PatientModel>()
        .where((p) => p.isActive)
        .map((p) => p.toEntity())
        .toList();
  }

  /// Get all patients sorted by risk level (highest first)
  List<Patient> getPatientsSortedByRisk() {
    final patients = getAllPatients();
    patients.sort(
      (a, b) =>
          b.currentRiskLevel.priority.compareTo(a.currentRiskLevel.priority),
    );
    return patients;
  }

  /// Get patients filtered by risk level
  List<Patient> getPatientsByRiskLevel(RiskLevel level) {
    return getAllPatients().where((p) => p.currentRiskLevel == level).toList();
  }

  /// Get a patient by ID
  Patient? getPatientById(String id) {
    final model = _box.get(id) as PatientModel?;
    return model?.toEntity();
  }

  /// Get a patient by bed ID
  Patient? getPatientByBedId(String bedId) {
    try {
      final model = _box.values.cast<PatientModel>().firstWhere(
        (p) => p.bedId == bedId && p.isActive,
      );
      return model.toEntity();
    } catch (_) {
      return null;
    }
  }

  /// Add a new patient
  Future<void> addPatient(Patient patient) async {
    final model = PatientModel.fromEntity(patient);
    await _box.put(patient.id, model);
  }

  /// Update an existing patient
  Future<void> updatePatient(Patient patient) async {
    final model = PatientModel.fromEntity(patient);
    await _box.put(patient.id, model);
  }

  /// Update patient's risk level and last vitals time
  Future<void> updatePatientRiskLevel(
    String patientId,
    RiskLevel riskLevel,
    DateTime? lastVitalsTime,
  ) async {
    final model = _box.get(patientId) as PatientModel?;
    if (model != null) {
      final updated = model.copyWithRiskLevel(riskLevel, lastVitalsTime);
      await _box.put(patientId, updated);
    }
  }

  /// Mark patient as discharged (soft delete)
  Future<void> dischargePatient(String patientId) async {
    final model = _box.get(patientId) as PatientModel?;
    if (model != null) {
      final updated = PatientModel(
        id: model.id,
        bedId: model.bedId,
        name: model.name,
        age: model.age,
        gender: model.gender,
        medicalRecordNumber: model.medicalRecordNumber,
        admissionDate: model.admissionDate,
        wardName: model.wardName,
        currentRiskLevelIndex: model.currentRiskLevelIndex,
        lastVitalsTime: model.lastVitalsTime,
        isMonitored: model.isMonitored,
        notes: model.notes,
        isActive: false,
      );
      await _box.put(patientId, updated);
    }
  }

  /// Get count of patients by risk level
  Map<RiskLevel, int> getRiskLevelCounts() {
    final patients = getAllPatients();
    final counts = <RiskLevel, int>{};

    for (final level in RiskLevel.values) {
      counts[level] = patients.where((p) => p.currentRiskLevel == level).length;
    }

    return counts;
  }

  /// Get patients with overdue vitals
  List<Patient> getPatientsWithOverdueVitals() {
    return getAllPatients().where((p) => p.isVitalsOverdue).toList();
  }

  /// Search patients by name or bed ID
  List<Patient> searchPatients(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllPatients().where((p) {
      return p.name.toLowerCase().contains(lowerQuery) ||
          p.bedId.toLowerCase().contains(lowerQuery) ||
          (p.medicalRecordNumber?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}
