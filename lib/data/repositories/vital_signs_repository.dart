/// Vital signs repository for data access
///
/// Provides access to vital signs data with offline-first architecture.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/vital_signs.dart';
import '../models/vital_signs_model.dart';

/// Provider for vital signs repository
final vitalSignsRepositoryProvider = Provider<VitalSignsRepository>((ref) {
  return VitalSignsRepository();
});

/// Repository for vital signs data operations
class VitalSignsRepository {
  Box get _box => Hive.box(AppConstants.vitalsBox);

  /// Get all vital signs for a patient
  List<VitalSigns> getVitalSignsForPatient(String patientId) {
    return _box.values
        .cast<VitalSignsModel>()
        .where((v) => v.patientId == patientId)
        .map((v) => v.toEntity())
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first
  }

  /// Get vital signs within a time window for trend analysis
  ///
  /// Returns vital signs from the last [hours] hours, sorted oldest to newest
  /// for proper trend calculation
  List<VitalSigns> getVitalSignsInWindow(String patientId, int hours) {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));

    return _box.values
        .cast<VitalSignsModel>()
        .where((v) => v.patientId == patientId && v.timestamp.isAfter(cutoff))
        .map((v) => v.toEntity())
        .toList()
      ..sort(
        (a, b) => a.timestamp.compareTo(b.timestamp),
      ); // Oldest first for trend
  }

  /// Get the most recent vital signs for a patient
  VitalSigns? getLatestVitalSigns(String patientId) {
    final vitals = getVitalSignsForPatient(patientId);
    return vitals.isNotEmpty ? vitals.first : null;
  }

  /// Get a specific vital signs entry by ID
  VitalSigns? getVitalSignsById(String id) {
    final model = _box.get(id) as VitalSignsModel?;
    return model?.toEntity();
  }

  /// Add a new vital signs entry
  Future<void> addVitalSigns(VitalSigns vitals) async {
    final model = VitalSignsModel.fromEntity(vitals);
    await _box.put(vitals.id, model);
  }

  /// Update an existing vital signs entry
  Future<void> updateVitalSigns(VitalSigns vitals) async {
    final model = VitalSignsModel.fromEntity(vitals);
    await _box.put(vitals.id, model);
  }

  /// Delete a vital signs entry
  Future<void> deleteVitalSigns(String id) async {
    await _box.delete(id);
  }

  /// Get vital signs count for a patient
  int getVitalSignsCount(String patientId) {
    return _box.values
        .cast<VitalSignsModel>()
        .where((v) => v.patientId == patientId)
        .length;
  }

  /// Get average values over a time window
  Map<String, double>? getAverageVitals(String patientId, int hours) {
    final vitals = getVitalSignsInWindow(patientId, hours);
    if (vitals.isEmpty) return null;

    return {
      'heartRate':
          vitals.map((v) => v.heartRate).reduce((a, b) => a + b) /
          vitals.length,
      'systolicBP':
          vitals.map((v) => v.systolicBP).reduce((a, b) => a + b) /
          vitals.length,
      'diastolicBP':
          vitals.map((v) => v.diastolicBP).reduce((a, b) => a + b) /
          vitals.length,
      'respiratoryRate':
          vitals.map((v) => v.respiratoryRate).reduce((a, b) => a + b) /
          vitals.length,
      'temperature':
          vitals.map((v) => v.temperature).reduce((a, b) => a + b) /
          vitals.length,
      'spO2': vitals.map((v) => v.spO2).reduce((a, b) => a + b) / vitals.length,
    };
  }
}
