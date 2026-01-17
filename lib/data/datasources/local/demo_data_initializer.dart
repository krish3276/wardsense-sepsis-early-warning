/// Demo data initializer for hackathon demonstration
///
/// Creates realistic patient data with vital sign history for
/// demonstrating the app's trend analysis and alert capabilities.

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/risk_level.dart';
import '../../../domain/entities/comorbidity.dart';
import '../../../domain/services/trend_analysis_engine.dart';
import '../../../domain/entities/vital_signs.dart';
import '../../models/patient_model.dart';
import '../../models/vital_signs_model.dart';
import '../../models/alert_model.dart';

/// Helper function to calculate NEWS score for VitalSignsModel
int _calculateNewsScoreForModel(VitalSignsModel model) {
  // Create a temporary VitalSigns entity to use the static method
  final tempVitals = VitalSigns(
    id: model.id,
    patientId: model.patientId,
    heartRate: model.heartRate,
    systolicBP: model.systolicBP,
    diastolicBP: model.diastolicBP,
    respiratoryRate: model.respiratoryRate,
    temperature: model.temperature,
    spO2: model.spO2,
    isOnSupplementalOxygen: model.isOnSupplementalOxygen,
    consciousnessLevel:
        ConsciousnessLevel.values[model.consciousnessLevelIndex],
    timestamp: model.timestamp,
    createdAt: model.createdAt,
  );
  return TrendAnalysisEngine.calculateNewsScore(tempVitals);
}

/// Initializes demo data for the application
///
/// Creates a set of patients with realistic vital sign histories
/// that demonstrate various clinical scenarios including:
/// - Stable patients (green)
/// - Patients requiring monitoring (yellow)
/// - Patients needing doctor notification (orange)
/// - High-risk patients requiring escalation (red)
class DemoDataInitializer {
  static const _uuid = Uuid();

  /// Initialize demo data if the database is empty
  static Future<void> initializeIfEmpty() async {
    final patientsBox = Hive.box(AppConstants.patientsBox);

    // Only initialize if no patients exist
    if (patientsBox.isEmpty) {
      await _createDemoData();
    }
  }

  /// Force reinitialize demo data (for reset functionality)
  static Future<void> reinitialize() async {
    final patientsBox = Hive.box(AppConstants.patientsBox);
    final vitalsBox = Hive.box(AppConstants.vitalsBox);
    final alertsBox = Hive.box(AppConstants.alertsBox);

    await patientsBox.clear();
    await vitalsBox.clear();
    await alertsBox.clear();

    await _createDemoData();
  }

  static Future<void> _createDemoData() async {
    final now = DateTime.now();

    // ═══════════════════════════════════════════════════════════════════════
    // PATIENT 1: Stable patient (GREEN)
    // Normal vital signs with minor variations
    // ═══════════════════════════════════════════════════════════════════════
    final patient1Id = _uuid.v4();
    final patient1 = PatientModel(
      id: patient1Id,
      bedId: '1A',
      name: 'John Smith',
      age: 45,
      gender: 'M',
      medicalRecordNumber: 'MRN001234',
      admissionDate: now.subtract(const Duration(days: 2)),
      wardName: 'General Medicine',
      currentRiskLevelIndex: RiskLevel.green.index,
      lastVitalsTime: now.subtract(const Duration(hours: 1)),
      isActive: true,
    );

    final vitals1 = _generateStableVitals(patient1Id, now);

    // ═══════════════════════════════════════════════════════════════════════
    // PATIENT 2: Needs monitoring (YELLOW)
    // Slightly elevated heart rate and temperature - has diabetes
    // ═══════════════════════════════════════════════════════════════════════
    final patient2Id = _uuid.v4();
    final patient2 = PatientModel(
      id: patient2Id,
      bedId: '2B',
      name: 'Mary Johnson',
      age: 67,
      gender: 'F',
      medicalRecordNumber: 'MRN001235',
      admissionDate: now.subtract(const Duration(days: 3)),
      wardName: 'General Medicine',
      currentRiskLevelIndex: RiskLevel.yellow.index,
      lastVitalsTime: now.subtract(const Duration(minutes: 45)),
      isActive: true,
      // Comorbidities for risk adjustment
      comorbidityTypeIndices: [ComorbidityType.diabetesMellitus.index],
      comorbiditySeverityIndices: [1], // moderate
    );

    final vitals2 = _generateYellowPatientVitals(patient2Id, now);

    // ═══════════════════════════════════════════════════════════════════════
    // PATIENT 3: Notify doctor (ORANGE)
    // Rising heart rate, falling BP - has CKD and heart failure (HIGH RISK)
    // ═══════════════════════════════════════════════════════════════════════
    final patient3Id = _uuid.v4();
    final patient3 = PatientModel(
      id: patient3Id,
      bedId: '3C',
      name: 'Robert Williams',
      age: 72,
      gender: 'M',
      medicalRecordNumber: 'MRN001236',
      admissionDate: now.subtract(const Duration(days: 1)),
      wardName: 'General Medicine',
      currentRiskLevelIndex: RiskLevel.orange.index,
      lastVitalsTime: now.subtract(const Duration(minutes: 20)),
      isMonitored: true,
      isActive: true,
      // Multiple comorbidities - HIGH RISK patient
      comorbidityTypeIndices: [
        ComorbidityType.chronicKidneyDisease.index,
        ComorbidityType.heartFailure.index,
      ],
      comorbiditySeverityIndices: [2, 1], // severe CKD, moderate HF
    );

    final vitals3 = _generateOrangePatientVitals(patient3Id, now);

    // ═══════════════════════════════════════════════════════════════════════
    // PATIENT 4: High risk (RED)
    // Classic sepsis pattern: HR↑, BP↓, RR↑, Temp↑ - CRITICAL RISK PATIENT
    // ═══════════════════════════════════════════════════════════════════════
    final patient4Id = _uuid.v4();
    final patient4 = PatientModel(
      id: patient4Id,
      bedId: '4D',
      name: 'Patricia Davis',
      age: 58,
      gender: 'F',
      medicalRecordNumber: 'MRN001237',
      admissionDate: now.subtract(const Duration(hours: 18)),
      wardName: 'General Medicine',
      currentRiskLevelIndex: RiskLevel.red.index,
      lastVitalsTime: now.subtract(const Duration(minutes: 10)),
      isMonitored: true,
      isActive: true,
      // Critical risk - Diabetes + Immunosuppression
      comorbidityTypeIndices: [
        ComorbidityType.diabetesMellitus.index,
        ComorbidityType.immunosuppression.index,
      ],
      comorbiditySeverityIndices: [2, 2], // both severe
    );

    final vitals4 = _generateRedPatientVitals(patient4Id, now);

    // ═══════════════════════════════════════════════════════════════════════
    // PATIENT 5: Stable elderly patient with COPD
    // ═══════════════════════════════════════════════════════════════════════
    final patient5Id = _uuid.v4();
    final patient5 = PatientModel(
      id: patient5Id,
      bedId: '5E',
      name: 'James Wilson',
      age: 81,
      gender: 'M',
      medicalRecordNumber: 'MRN001238',
      admissionDate: now.subtract(const Duration(days: 4)),
      wardName: 'General Medicine',
      currentRiskLevelIndex: RiskLevel.green.index,
      lastVitalsTime: now.subtract(const Duration(hours: 3)),
      isActive: true,
      // Elderly with COPD - elevated risk but stable
      comorbidityTypeIndices: [ComorbidityType.copd.index],
      comorbiditySeverityIndices: [1], // moderate
    );

    final vitals5 = _generateStableVitals(patient5Id, now);

    // ═══════════════════════════════════════════════════════════════════════
    // PATIENT 6: Post-surgery monitoring (YELLOW) - Liver cirrhosis
    // ═══════════════════════════════════════════════════════════════════════
    final patient6Id = _uuid.v4();
    final patient6 = PatientModel(
      id: patient6Id,
      bedId: '6F',
      name: 'Linda Martinez',
      age: 54,
      gender: 'F',
      medicalRecordNumber: 'MRN001239',
      admissionDate: now.subtract(const Duration(hours: 12)),
      wardName: 'Surgical Ward',
      currentRiskLevelIndex: RiskLevel.yellow.index,
      lastVitalsTime: now.subtract(const Duration(minutes: 30)),
      isMonitored: true,
      notes: 'Post appendectomy - day 0',
      isActive: true,
    );

    final vitals6 = _generateYellowPatientVitals(patient6Id, now);

    // Save all patients
    final patientsBox = Hive.box(AppConstants.patientsBox);
    await patientsBox.put(patient1.id, patient1);
    await patientsBox.put(patient2.id, patient2);
    await patientsBox.put(patient3.id, patient3);
    await patientsBox.put(patient4.id, patient4);
    await patientsBox.put(patient5.id, patient5);
    await patientsBox.put(patient6.id, patient6);

    // Save all vitals
    final vitalsBox = Hive.box(AppConstants.vitalsBox);
    for (final vital in [
      ...vitals1,
      ...vitals2,
      ...vitals3,
      ...vitals4,
      ...vitals5,
      ...vitals6,
    ]) {
      await vitalsBox.put(vital.id, vital);
    }

    // Create sample alerts for orange and red patients
    await _createDemoAlerts(patient3Id, patient4Id, now);
  }

  /// Generate stable vital signs for a green patient
  static List<VitalSignsModel> _generateStableVitals(
    String patientId,
    DateTime now,
  ) {
    final vitals = <VitalSignsModel>[];

    // Generate vitals for the last 12 hours (every 4 hours)
    for (int i = 0; i < 4; i++) {
      final timestamp = now.subtract(Duration(hours: i * 4 + 1));
      final vitalWithoutScore = VitalSignsModel(
        id: _uuid.v4(),
        patientId: patientId,
        heartRate: 72 + (i % 2 == 0 ? 2 : -2), // Minor variation
        systolicBP: 120 + (i % 2 == 0 ? 3 : -3),
        diastolicBP: 78 + (i % 2 == 0 ? 2 : -2),
        respiratoryRate: 16,
        temperature: 36.6 + (i * 0.1),
        spO2: 98,
        timestamp: timestamp,
        createdAt: timestamp.add(const Duration(minutes: 2)),
      );
      // Add with calculated NEWS score
      vitals.add(
        VitalSignsModel(
          id: vitalWithoutScore.id,
          patientId: vitalWithoutScore.patientId,
          heartRate: vitalWithoutScore.heartRate,
          systolicBP: vitalWithoutScore.systolicBP,
          diastolicBP: vitalWithoutScore.diastolicBP,
          respiratoryRate: vitalWithoutScore.respiratoryRate,
          temperature: vitalWithoutScore.temperature,
          spO2: vitalWithoutScore.spO2,
          timestamp: vitalWithoutScore.timestamp,
          createdAt: vitalWithoutScore.createdAt,
          newsScore: _calculateNewsScoreForModel(vitalWithoutScore),
        ),
      );
    }

    return vitals;
  }

  /// Generate vital signs for a yellow patient (mild concern)
  static List<VitalSignsModel> _generateYellowPatientVitals(
    String patientId,
    DateTime now,
  ) {
    final vitals = <VitalSignsModel>[];

    // Slightly elevated values with upward trend
    final baseHR = 88;
    final baseTemp = 37.4;

    for (int i = 0; i < 5; i++) {
      final timestamp = now.subtract(Duration(hours: i * 2 + 1));
      final vitalWithoutScore = VitalSignsModel(
        id: _uuid.v4(),
        patientId: patientId,
        heartRate: baseHR + (4 - i) * 3, // Rising trend (88 -> 100)
        systolicBP: 118 - i * 2,
        diastolicBP: 75 - i,
        respiratoryRate: 18 + (4 - i), // Slightly elevated
        temperature: baseTemp + (4 - i) * 0.15,
        spO2: 96,
        timestamp: timestamp,
        createdAt: timestamp.add(const Duration(minutes: 2)),
      );
      // Add with calculated NEWS score
      vitals.add(
        VitalSignsModel(
          id: vitalWithoutScore.id,
          patientId: vitalWithoutScore.patientId,
          heartRate: vitalWithoutScore.heartRate,
          systolicBP: vitalWithoutScore.systolicBP,
          diastolicBP: vitalWithoutScore.diastolicBP,
          respiratoryRate: vitalWithoutScore.respiratoryRate,
          temperature: vitalWithoutScore.temperature,
          spO2: vitalWithoutScore.spO2,
          timestamp: vitalWithoutScore.timestamp,
          createdAt: vitalWithoutScore.createdAt,
          newsScore: _calculateNewsScoreForModel(vitalWithoutScore),
        ),
      );
    }

    return vitals;
  }

  /// Generate vital signs for an orange patient (concerning trend)
  static List<VitalSignsModel> _generateOrangePatientVitals(
    String patientId,
    DateTime now,
  ) {
    final vitals = <VitalSignsModel>[];

    // Concerning pattern: HR rising, BP falling, RR rising
    for (int i = 0; i < 6; i++) {
      final timestamp = now.subtract(Duration(hours: i * 2));
      final trendFactor = 5 - i; // 5, 4, 3, 2, 1, 0

      final vitalWithoutScore = VitalSignsModel(
        id: _uuid.v4(),
        patientId: patientId,
        heartRate: 95 + trendFactor * 5, // 95 -> 120
        systolicBP: 115 - trendFactor * 5, // 115 -> 90
        diastolicBP: 70 - trendFactor * 3,
        respiratoryRate: 18 + trendFactor * 2, // 18 -> 28
        temperature: 37.8 + trendFactor * 0.2,
        spO2: 95 - trendFactor,
        timestamp: timestamp,
        createdAt: timestamp.add(const Duration(minutes: 3)),
      );
      // Add with calculated NEWS score
      vitals.add(
        VitalSignsModel(
          id: vitalWithoutScore.id,
          patientId: vitalWithoutScore.patientId,
          heartRate: vitalWithoutScore.heartRate,
          systolicBP: vitalWithoutScore.systolicBP,
          diastolicBP: vitalWithoutScore.diastolicBP,
          respiratoryRate: vitalWithoutScore.respiratoryRate,
          temperature: vitalWithoutScore.temperature,
          spO2: vitalWithoutScore.spO2,
          timestamp: vitalWithoutScore.timestamp,
          createdAt: vitalWithoutScore.createdAt,
          newsScore: _calculateNewsScoreForModel(vitalWithoutScore),
        ),
      );
    }

    return vitals;
  }

  /// Generate vital signs for a red patient (sepsis pattern)
  static List<VitalSignsModel> _generateRedPatientVitals(
    String patientId,
    DateTime now,
  ) {
    final vitals = <VitalSignsModel>[];

    // Classic sepsis pattern with rapid deterioration
    for (int i = 0; i < 8; i++) {
      final timestamp = now.subtract(Duration(hours: i * 1.5.toInt()));
      final trendFactor = 7 - i; // 7, 6, 5, 4, 3, 2, 1, 0

      final vitalWithoutScore = VitalSignsModel(
        id: _uuid.v4(),
        patientId: patientId,
        heartRate: 100 + trendFactor * 8, // 100 -> 156 (tachycardia)
        systolicBP: 110 - trendFactor * 6, // 110 -> 68 (hypotension)
        diastolicBP: 68 - trendFactor * 4,
        respiratoryRate: 20 + trendFactor * 3, // 20 -> 41 (tachypnea)
        temperature: 38.0 + trendFactor * 0.3, // 38 -> 40.1 (fever)
        spO2: 96 - trendFactor * 2, // 96 -> 82
        timestamp: timestamp,
        createdAt: timestamp.add(const Duration(minutes: 1)),
        notes: trendFactor >= 5 ? 'Concerning trend noted' : null,
      );
      // Add with calculated NEWS score
      vitals.add(
        VitalSignsModel(
          id: vitalWithoutScore.id,
          patientId: vitalWithoutScore.patientId,
          heartRate: vitalWithoutScore.heartRate,
          systolicBP: vitalWithoutScore.systolicBP,
          diastolicBP: vitalWithoutScore.diastolicBP,
          respiratoryRate: vitalWithoutScore.respiratoryRate,
          temperature: vitalWithoutScore.temperature,
          spO2: vitalWithoutScore.spO2,
          timestamp: vitalWithoutScore.timestamp,
          createdAt: vitalWithoutScore.createdAt,
          notes: vitalWithoutScore.notes,
          newsScore: _calculateNewsScoreForModel(vitalWithoutScore),
        ),
      );
    }

    return vitals;
  }

  /// Create demo alerts for concerning patients
  static Future<void> _createDemoAlerts(
    String orangePatientId,
    String redPatientId,
    DateTime now,
  ) async {
    final alertsBox = Hive.box(AppConstants.alertsBox);

    // Orange patient alert
    final orangeAlert = AlertModel(
      id: _uuid.v4(),
      patientId: orangePatientId,
      riskLevelIndex: RiskLevel.orange.index,
      title: 'Deteriorating Trend Detected',
      description:
          'Patient shows concerning vital sign trends over the past 6 hours. Heart rate rising while blood pressure falling.',
      factors: [
        AlertFactorModel(
          vitalTypeIndex: 0, // Heart Rate
          directionIndex: 0, // Rising
          currentValue: 120,
          previousValue: 95,
          percentageChange: 26.3,
          rateOfChangePerHour: 4.2,
          shortDescription: 'HR ↑ 26%',
          explanation: 'Heart rate increased from 95 to 120 bpm over 6 hours',
          isCritical: false,
        ),
        AlertFactorModel(
          vitalTypeIndex: 1, // Systolic BP
          directionIndex: 1, // Falling
          currentValue: 90,
          previousValue: 115,
          percentageChange: -21.7,
          rateOfChangePerHour: -4.2,
          shortDescription: 'SBP ↓ 22%',
          explanation: 'Systolic BP decreased from 115 to 90 mmHg over 6 hours',
          isCritical: true,
        ),
      ],
      recommendedActions: [
        'Repeat vital signs in 15 minutes',
        'Notify duty doctor for assessment',
        'Consider fluid status evaluation',
      ],
      timestamp: now.subtract(const Duration(minutes: 20)),
      analysisWindowHours: 6,
      isActive: true,
    );

    // Red patient alert
    final redAlert = AlertModel(
      id: _uuid.v4(),
      patientId: redPatientId,
      riskLevelIndex: RiskLevel.red.index,
      title: 'High Risk: Possible Sepsis Pattern',
      description:
          'Patient shows classic sepsis deterioration pattern: rising heart rate, falling blood pressure, elevated respiratory rate, and fever. Immediate escalation recommended.',
      factors: [
        AlertFactorModel(
          vitalTypeIndex: 0, // Heart Rate
          directionIndex: 0, // Rising
          currentValue: 156,
          previousValue: 100,
          percentageChange: 56,
          rateOfChangePerHour: 7.5,
          shortDescription: 'HR ↑ 56%',
          explanation:
              'Rapid heart rate increase from 100 to 156 bpm (tachycardia)',
          isCritical: true,
        ),
        AlertFactorModel(
          vitalTypeIndex: 1, // Systolic BP
          directionIndex: 1, // Falling
          currentValue: 68,
          previousValue: 110,
          percentageChange: -38.2,
          rateOfChangePerHour: -5.6,
          shortDescription: 'SBP ↓ 38%',
          explanation:
              'Critical drop in systolic BP from 110 to 68 mmHg (hypotension)',
          isCritical: true,
        ),
        AlertFactorModel(
          vitalTypeIndex: 3, // Respiratory Rate
          directionIndex: 0, // Rising
          currentValue: 41,
          previousValue: 20,
          percentageChange: 105,
          rateOfChangePerHour: 2.8,
          shortDescription: 'RR ↑ 105%',
          explanation: 'Respiratory rate doubled from 20 to 41/min (tachypnea)',
          isCritical: true,
        ),
        AlertFactorModel(
          vitalTypeIndex: 4, // Temperature
          directionIndex: 0, // Rising
          currentValue: 40.1,
          previousValue: 38.0,
          percentageChange: 5.5,
          rateOfChangePerHour: 0.28,
          shortDescription: 'Temp ↑ 40.1°C',
          explanation: 'Fever progression from 38.0 to 40.1°C',
          isCritical: false,
        ),
      ],
      recommendedActions: [
        'Activate sepsis protocol immediately',
        'Call rapid response team',
        'Obtain IV access and prepare for fluid resuscitation',
        'Order blood cultures and lactate',
      ],
      timestamp: now.subtract(const Duration(minutes: 10)),
      analysisWindowHours: 8,
      isActive: true,
    );

    await alertsBox.put(orangeAlert.id, orangeAlert);
    await alertsBox.put(redAlert.id, redAlert);
  }
}
