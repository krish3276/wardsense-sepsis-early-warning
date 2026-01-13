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
import '../../domain/entities/patient_risk_profile.dart';
import '../../domain/entities/vital_velocity.dart';
import '../../domain/entities/escalation_prompt.dart';
import '../../domain/entities/escalation_safety_net.dart';
import '../../domain/services/trend_analysis_engine.dart';
import '../../domain/services/velocity_analysis_service.dart';
import '../../domain/services/risk_adjustment_service.dart';
import '../../domain/services/escalation_prompt_service.dart';
import '../../domain/services/safety_net_service.dart';

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
// ADVANCED CLINICAL FEATURE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

// Note: Service providers are defined in their respective service files:
// - velocityAnalysisServiceProvider in velocity_analysis_service.dart
// - riskAdjustmentServiceProvider in risk_adjustment_service.dart
// - escalationPromptServiceProvider in escalation_prompt_service.dart
// - safetyNetServiceProvider in safety_net_service.dart

/// Provider for velocity analysis for a specific patient
final patientVelocityProvider =
    Provider.family<VelocityAnalysisResult?, String>((ref, patientId) {
  final velocityService = ref.watch(velocityAnalysisServiceProvider);
  return velocityService.analyzeVelocity(patientId);
});

/// Provider for patient risk profile
final patientRiskProfileProvider =
    Provider.family<PatientRiskProfile, String>((ref, patientId) {
  final patient = ref.watch(patientProvider(patientId));

  if (patient == null) {
    return PatientRiskProfile(
      patientId: patientId,
      age: 50, // Default age
      comorbidities: const [],
      lastUpdated: DateTime.now(),
    );
  }

  // Return patient's risk profile (pre-computed)
  return patient.riskProfile;
});

/// Provider for adjusted risk assessment for a patient
final adjustedRiskAssessmentProvider =
    Provider.family<AdjustedRiskResult?, String>((ref, patientId) {
  final riskService = ref.watch(riskAdjustmentServiceProvider);
  final riskProfile = ref.watch(patientRiskProfileProvider(patientId));
  final vitals = ref.watch(vitalSignsProvider(patientId));

  if (vitals.isEmpty) return null;
  final latestVitals = vitals.first;

  // Use the analysis provider to get NEWS score
  final analysis = ref.watch(patientAnalysisProvider(patientId));

  return riskService.calculateAdjustedRisk(
    vitals: latestVitals,
    riskProfile: riskProfile,
    baseNewsScore: analysis.newsScore,
  );
});

/// Provider for escalation prompts for a patient
final patientEscalationPromptProvider =
    Provider.family<EscalationPrompt?, String>((ref, patientId) {
  final promptService = ref.watch(escalationPromptServiceProvider);
  final riskProfile = ref.watch(patientRiskProfileProvider(patientId));
  final vitals = ref.watch(vitalSignsProvider(patientId));

  if (vitals.isEmpty) return null;
  final latestVitals = vitals.first;
  final analysis = ref.watch(patientAnalysisProvider(patientId));

  return promptService.generatePrompt(
    patientId: patientId,
    currentVitals: latestVitals,
    riskProfile: riskProfile,
    newsScore: analysis.newsScore,
  );
});

/// Provider for safety net status for a patient
final patientSafetyNetProvider =
    Provider.family<EscalationTracker?, String>((ref, patientId) {
  final safetyNetService = ref.watch(safetyNetServiceProvider);
  final alerts = ref.watch(patientAlertsProvider(patientId));

  if (alerts.isEmpty) return null;
  final latestAlert = alerts.first;

  // Start tracking new high-priority alerts
  if (latestAlert.riskLevel == RiskLevel.red ||
      latestAlert.riskLevel == RiskLevel.orange) {
    return safetyNetService.startTracking(
      patientId: patientId,
      alert: latestAlert,
    );
  }
  return null;
});

/// Provider for overall safety net summary (uses provider defined in safety_net_service.dart)
// Note: safetyNetSummaryProvider is already defined in safety_net_service.dart

/// Provider for all overdue escalations (uses provider defined in safety_net_service.dart)
// Note: overdueTrackersProvider is already defined in safety_net_service.dart

/// Provider for pending escalations (not yet overdue)
final pendingEscalationsProvider = Provider<List<EscalationTracker>>((ref) {
  final safetyNetService = ref.watch(safetyNetServiceProvider);
  final activeTrackers = safetyNetService.getActiveTrackers();
  final overdueTrackers = safetyNetService.getOverdueTrackers();

  // Pending = Active but not overdue
  return activeTrackers.where((t) => !overdueTrackers.contains(t)).toList();
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
