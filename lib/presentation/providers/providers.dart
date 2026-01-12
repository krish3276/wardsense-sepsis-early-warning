/// Riverpod providers for WardSense
///
/// Central state management using Riverpod.
/// Provides reactive access to data and computed states.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/risk_level.dart';
import '../../data/repositories/patient_repository.dart';
import '../../data/repositories/vital_signs_repository.dart';
import '../../data/repositories/alert_repository.dart';
import '../../domain/entities/patient.dart';
import '../../domain/entities/vital_signs.dart';
import '../../domain/entities/alert.dart';
import '../../domain/services/trend_analysis_engine.dart';

// ═══════════════════════════════════════════════════════════════════════════
// USER ROLE PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// User role enumeration
enum UserRole { nurse, doctor }

/// Provider for current user role
final userRoleProvider = StateProvider<UserRole>((ref) => UserRole.nurse);

// ═══════════════════════════════════════════════════════════════════════════
// PATIENT PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for all patients sorted by risk
final patientsProvider = Provider<List<Patient>>((ref) {
  final repository = ref.watch(patientRepositoryProvider);
  return repository.getPatientsSortedByRisk();
});

/// Provider for patients filtered by risk level
final patientsByRiskProvider = Provider.family<List<Patient>, RiskLevel>((
  ref,
  level,
) {
  final repository = ref.watch(patientRepositoryProvider);
  return repository.getPatientsByRiskLevel(level);
});

/// Provider for risk level counts
final riskLevelCountsProvider = Provider<Map<RiskLevel, int>>((ref) {
  final repository = ref.watch(patientRepositoryProvider);
  return repository.getRiskLevelCounts();
});

/// Provider for a single patient
final patientProvider = Provider.family<Patient?, String>((ref, patientId) {
  final repository = ref.watch(patientRepositoryProvider);
  return repository.getPatientById(patientId);
});

/// Provider for currently selected patient ID
final selectedPatientIdProvider = StateProvider<String?>((ref) => null);

/// Provider for currently selected patient
final selectedPatientProvider = Provider<Patient?>((ref) {
  final patientId = ref.watch(selectedPatientIdProvider);
  if (patientId == null) return null;
  return ref.watch(patientProvider(patientId));
});

/// Provider for search query
final patientSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for filtered patients based on search
final filteredPatientsProvider = Provider<List<Patient>>((ref) {
  final query = ref.watch(patientSearchQueryProvider);
  final repository = ref.watch(patientRepositoryProvider);

  if (query.isEmpty) {
    return repository.getPatientsSortedByRisk();
  }

  return repository.searchPatients(query);
});

// ═══════════════════════════════════════════════════════════════════════════
// VITAL SIGNS PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for vital signs of a patient
final vitalSignsProvider = Provider.family<List<VitalSigns>, String>((
  ref,
  patientId,
) {
  final repository = ref.watch(vitalSignsRepositoryProvider);
  return repository.getVitalSignsForPatient(patientId);
});

/// Provider for latest vital signs of a patient
final latestVitalSignsProvider = Provider.family<VitalSigns?, String>((
  ref,
  patientId,
) {
  final repository = ref.watch(vitalSignsRepositoryProvider);
  return repository.getLatestVitalSigns(patientId);
});

/// Provider for vital signs in trend window
final vitalSignsInWindowProvider = Provider.family<List<VitalSigns>, String>((
  ref,
  patientId,
) {
  final repository = ref.watch(vitalSignsRepositoryProvider);
  return repository.getVitalSignsInWindow(patientId, 12);
});

// ═══════════════════════════════════════════════════════════════════════════
// ALERT PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for all active alerts
final activeAlertsProvider = Provider<List<Alert>>((ref) {
  final repository = ref.watch(alertRepositoryProvider);
  return repository.getActiveAlerts();
});

/// Provider for alerts of a patient
final patientAlertsProvider = Provider.family<List<Alert>, String>((
  ref,
  patientId,
) {
  final repository = ref.watch(alertRepositoryProvider);
  return repository.getAlertsForPatient(patientId);
});

/// Provider for active alerts of a patient
final activePatientAlertsProvider = Provider.family<List<Alert>, String>((
  ref,
  patientId,
) {
  final repository = ref.watch(alertRepositoryProvider);
  return repository.getActiveAlertsForPatient(patientId);
});

/// Provider for unacknowledged alert count
final unacknowledgedAlertCountProvider = Provider<int>((ref) {
  final repository = ref.watch(alertRepositoryProvider);
  return repository.getUnacknowledgedCount();
});

// ═══════════════════════════════════════════════════════════════════════════
// TREND ANALYSIS PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for patient analysis result
final patientAnalysisProvider = Provider.family<PatientAnalysisResult, String>((
  ref,
  patientId,
) {
  final engine = ref.watch(trendAnalysisEngineProvider);
  return engine.analyzePatient(patientId);
});

// ═══════════════════════════════════════════════════════════════════════════
// DASHBOARD STATISTICS PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Dashboard statistics
class DashboardStats {
  final int totalPatients;
  final int redPatients;
  final int orangePatients;
  final int yellowPatients;
  final int greenPatients;
  final int activeAlerts;
  final int overdueVitals;

  DashboardStats({
    required this.totalPatients,
    required this.redPatients,
    required this.orangePatients,
    required this.yellowPatients,
    required this.greenPatients,
    required this.activeAlerts,
    required this.overdueVitals,
  });
}

/// Provider for dashboard statistics
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final patientRepo = ref.watch(patientRepositoryProvider);
  final alertRepo = ref.watch(alertRepositoryProvider);

  final patients = patientRepo.getAllPatients();
  final riskCounts = patientRepo.getRiskLevelCounts();
  final overduePatients = patientRepo.getPatientsWithOverdueVitals();
  final activeAlerts = alertRepo.getActiveAlerts();

  return DashboardStats(
    totalPatients: patients.length,
    redPatients: riskCounts[RiskLevel.red] ?? 0,
    orangePatients: riskCounts[RiskLevel.orange] ?? 0,
    yellowPatients: riskCounts[RiskLevel.yellow] ?? 0,
    greenPatients: riskCounts[RiskLevel.green] ?? 0,
    activeAlerts: activeAlerts.length,
    overdueVitals: overduePatients.length,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// REFRESH NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

/// Notifier to trigger data refresh
final refreshNotifierProvider = StateProvider<int>((ref) => 0);

/// Helper to refresh all data
void refreshAllData(WidgetRef ref) {
  ref.read(refreshNotifierProvider.notifier).state++;
}
