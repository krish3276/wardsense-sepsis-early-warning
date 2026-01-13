/// Demo Data Generator for WardSense Advanced Features
///
/// Generates realistic demo data showcasing all 4 advanced clinical features:
/// 1. Comorbidity-Aware Risk Adjustment
/// 2. Vital Trend Velocity (Rate of Deterioration)
/// 3. Context-Aware Escalation Prompts
/// 4. Missed-Escalation Safety Net
///
/// Use this for hackathon demonstrations and testing.

import 'dart:math';
import '../../domain/entities/patient.dart';
import '../../domain/entities/vital_signs.dart';
import '../../domain/entities/comorbidity.dart';
import '../../core/constants/risk_level.dart';

/// Generator for demonstration data
class DemoDataGenerator {
  static final _random = Random(42); // Seeded for reproducibility

  /// Generate a set of demo patients showcasing different risk profiles
  static List<Patient> generateDemoPatients() {
    return [
      // High-risk elderly patient with multiple comorbidities
      _createPatient(
        id: 'demo-001',
        bedId: 'ICU-1',
        name: 'Margaret Thompson',
        age: 78,
        gender: 'F',
        wardName: 'ICU',
        riskLevel: RiskLevel.red,
        comorbidities: [
          Comorbidity(
            type: ComorbidityType.chronicKidneyDisease,
            severity: 'severe',
            diagnosedDate: DateTime.now().subtract(const Duration(days: 365)),
            notes: 'CKD Stage 4, on dialysis',
          ),
          Comorbidity(
            type: ComorbidityType.diabetesMellitus,
            severity: 'moderate',
            diagnosedDate: DateTime.now().subtract(const Duration(days: 1825)),
            notes: 'Type 2 DM, insulin-dependent',
          ),
          Comorbidity(
            type: ComorbidityType.heartFailure,
            severity: 'moderate',
            diagnosedDate: DateTime.now().subtract(const Duration(days: 730)),
            notes: 'CHF with preserved EF',
          ),
        ],
      ),

      // Middle-aged immunocompromised patient
      _createPatient(
        id: 'demo-002',
        bedId: 'ONC-3',
        name: 'James Rodriguez',
        age: 52,
        gender: 'M',
        wardName: 'Oncology',
        riskLevel: RiskLevel.orange,
        comorbidities: [
          Comorbidity(
            type: ComorbidityType.immunosuppression,
            severity: 'severe',
            diagnosedDate: DateTime.now().subtract(const Duration(days: 90)),
            notes: 'Post-chemo neutropenia, ANC < 500',
          ),
          Comorbidity(
            type: ComorbidityType.malignancy,
            severity: 'moderate',
            diagnosedDate: DateTime.now().subtract(const Duration(days: 180)),
            notes: 'AML, on consolidation chemotherapy',
          ),
        ],
      ),

      // Young adult with COPD exacerbation
      _createPatient(
        id: 'demo-003',
        bedId: 'MED-5',
        name: 'Sarah Chen',
        age: 34,
        gender: 'F',
        wardName: 'Medical',
        riskLevel: RiskLevel.yellow,
        comorbidities: [
          Comorbidity(
            type: ComorbidityType.copd,
            severity: 'moderate',
            diagnosedDate: DateTime.now().subtract(const Duration(days: 730)),
            notes: 'COPD GOLD Stage 2, current exacerbation',
          ),
        ],
      ),

      // Elderly patient with liver disease
      _createPatient(
        id: 'demo-004',
        bedId: 'MED-8',
        name: 'Robert Williams',
        age: 67,
        gender: 'M',
        wardName: 'Medical',
        riskLevel: RiskLevel.orange,
        comorbidities: [
          Comorbidity(
            type: ComorbidityType.liverCirrhosis,
            severity: 'severe',
            diagnosedDate: DateTime.now().subtract(const Duration(days: 548)),
            notes: 'Cirrhosis, Child-Pugh C',
          ),
          Comorbidity(
            type: ComorbidityType.diabetesMellitus,
            severity: 'mild',
            diagnosedDate: DateTime.now().subtract(const Duration(days: 365)),
            notes: 'Type 2 DM, diet-controlled',
          ),
        ],
      ),

      // Healthy young adult - baseline comparison
      _createPatient(
        id: 'demo-005',
        bedId: 'SURG-2',
        name: 'Emily Davis',
        age: 28,
        gender: 'F',
        wardName: 'Surgical',
        riskLevel: RiskLevel.green,
        comorbidities: [], // No comorbidities
      ),
    ];
  }

  /// Generate vital signs history showing velocity patterns
  static List<VitalSigns> generateVitalsWithVelocity(
    String patientId, {
    required VelocityPattern pattern,
    int hoursOfHistory = 6,
  }) {
    final vitals = <VitalSigns>[];
    final now = DateTime.now();

    // Generate readings every 30 minutes
    final readingsCount = hoursOfHistory * 2;

    for (int i = readingsCount; i >= 0; i--) {
      final timestamp = now.subtract(Duration(minutes: i * 30));
      final progress = 1.0 - (i / readingsCount); // 0.0 to 1.0

      vitals.add(_generateVitalsForPattern(
        patientId: patientId,
        timestamp: timestamp,
        pattern: pattern,
        progress: progress,
      ));
    }

    return vitals;
  }

  static Patient _createPatient({
    required String id,
    required String bedId,
    required String name,
    required int age,
    required String gender,
    required String wardName,
    required RiskLevel riskLevel,
    required List<Comorbidity> comorbidities,
  }) {
    return Patient(
      id: id,
      bedId: bedId,
      name: name,
      age: age,
      gender: gender,
      wardName: wardName,
      admissionDate: DateTime.now().subtract(
        Duration(days: _random.nextInt(7) + 1),
      ),
      currentRiskLevel: riskLevel,
      lastVitalsTime: DateTime.now().subtract(
        Duration(minutes: _random.nextInt(30) + 5),
      ),
      isMonitored: riskLevel == RiskLevel.red || riskLevel == RiskLevel.orange,
      comorbidities: comorbidities,
    );
  }

  static VitalSigns _generateVitalsForPattern({
    required String patientId,
    required DateTime timestamp,
    required VelocityPattern pattern,
    required double progress,
  }) {
    int heartRate;
    int systolicBp;
    int diastolicBp;
    int respiratoryRate;
    double temperature;
    double oxygenSaturation;

    switch (pattern) {
      case VelocityPattern.rapidDeteriorationSepsis:
        // Classic sepsis pattern: ↑HR, ↓BP, ↑RR
        heartRate = (85 + progress * 45).round(); // 85 → 130
        systolicBp = (125 - progress * 40).round(); // 125 → 85
        diastolicBp = (80 - progress * 25).round(); // 80 → 55
        respiratoryRate = (16 + progress * 14).round(); // 16 → 30
        temperature = 36.8 + progress * 2.2; // 36.8 → 39.0
        oxygenSaturation = 98 - progress * 6; // 98 → 92

      case VelocityPattern.moderateDecrease:
        // Gradual deterioration
        heartRate = (80 + progress * 25).round(); // 80 → 105
        systolicBp = (130 - progress * 20).round(); // 130 → 110
        diastolicBp = (85 - progress * 15).round(); // 85 → 70
        respiratoryRate = (14 + progress * 6).round(); // 14 → 20
        temperature = 37.0 + progress * 1.0; // 37.0 → 38.0
        oxygenSaturation = 97 - progress * 2; // 97 → 95

      case VelocityPattern.stable:
        // Normal variation
        final variance = _random.nextDouble() * 0.1 - 0.05;
        heartRate = (75 + variance * 10).round();
        systolicBp = (120 + variance * 8).round();
        diastolicBp = (80 + variance * 5).round();
        respiratoryRate = (14 + variance * 2).round();
        temperature = 36.8 + variance * 0.3;
        oxygenSaturation = 98 + variance * 1;

      case VelocityPattern.improving:
        // Recovery pattern
        heartRate = (110 - progress * 30).round(); // 110 → 80
        systolicBp = (95 + progress * 30).round(); // 95 → 125
        diastolicBp = (60 + progress * 20).round(); // 60 → 80
        respiratoryRate = (24 - progress * 10).round(); // 24 → 14
        temperature = 38.5 - progress * 1.5; // 38.5 → 37.0
        oxygenSaturation = 92 + progress * 6; // 92 → 98

      case VelocityPattern.respiratoryDistress:
        // Respiratory-focused deterioration
        heartRate = (88 + progress * 30).round(); // 88 → 118
        systolicBp = (122 - progress * 8).round(); // 122 → 114
        diastolicBp = (78 - progress * 5).round(); // 78 → 73
        respiratoryRate = (18 + progress * 18).round(); // 18 → 36
        temperature = 37.2 + progress * 0.8; // 37.2 → 38.0
        oxygenSaturation = 96 - progress * 10; // 96 → 86

      case VelocityPattern.cardiacInstability:
        // Cardiac-focused issues
        heartRate = (70 + progress * 60).round(); // 70 → 130 (tachycardia)
        systolicBp = (130 - progress * 50).round(); // 130 → 80
        diastolicBp = (85 - progress * 35).round(); // 85 → 50
        respiratoryRate = (16 + progress * 8).round(); // 16 → 24
        temperature = 36.5 + progress * 0.5; // 36.5 → 37.0
        oxygenSaturation = 97 - progress * 4; // 97 → 93
    }

    return VitalSigns(
      id: 'vs-$patientId-${timestamp.millisecondsSinceEpoch}',
      patientId: patientId,
      timestamp: timestamp,
      createdAt: timestamp,
      heartRate: heartRate.clamp(40, 180),
      systolicBP: systolicBp.clamp(60, 200),
      diastolicBP: diastolicBp.clamp(30, 120),
      respiratoryRate: respiratoryRate.clamp(8, 45),
      temperature: temperature.clamp(35.0, 42.0),
      spO2: oxygenSaturation.clamp(70, 100).round(),
      notes: _getConsciousnessForPattern(pattern, progress),
    );
  }

  static String _getConsciousnessForPattern(
      VelocityPattern pattern, double progress) {
    if (pattern == VelocityPattern.rapidDeteriorationSepsis && progress > 0.7) {
      return 'Consciousness: Confused';
    }
    if (pattern == VelocityPattern.cardiacInstability && progress > 0.8) {
      return 'Consciousness: Drowsy';
    }
    if (pattern == VelocityPattern.improving) {
      return 'Consciousness: Alert';
    }
    return progress > 0.5 ? 'Consciousness: Drowsy' : 'Consciousness: Alert';
  }
}

/// Velocity pattern types for demo data generation
enum VelocityPattern {
  /// Classic sepsis: ↑HR, ↓BP, ↑RR, ↑Temp
  rapidDeteriorationSepsis,

  /// Gradual decline across all vitals
  moderateDecrease,

  /// Normal variation, no significant trend
  stable,

  /// Recovery pattern - improving vitals
  improving,

  /// Primarily respiratory deterioration
  respiratoryDistress,

  /// Cardiac instability pattern
  cardiacInstability,
}

/// Demo scenarios for showcasing features
class DemoScenarios {
  /// Scenario 1: High-risk patient with rapid sepsis deterioration
  /// Demonstrates: Comorbidity adjustment + Velocity detection + Escalation prompt
  static const scenario1Description = '''
SCENARIO: 78-year-old Margaret Thompson (ICU-1)
- Multiple comorbidities: CKD, DM, CHF
- Baseline risk multiplier: 2.1x
- Showing rapid sepsis pattern over 3 hours
- HR: 85→130, BP: 125/80→85/55, RR: 16→30

EXPECTED BEHAVIOR:
✓ Risk profile shows "High Risk" due to comorbidities
✓ Velocity indicator shows "Critical" with sepsis pattern
✓ Escalation prompt: "Consider immediate senior review"
✓ qSOFA score triggers additional warning
''';

  /// Scenario 2: Immunocompromised patient with subtle changes
  /// Demonstrates: Lower threshold sensitivity for immunosuppressed
  static const scenario2Description = '''
SCENARIO: 52-year-old James Rodriguez (ONC-3)
- Neutropenic post-chemotherapy
- Baseline risk multiplier: 1.6x
- Moderate vital changes that would be normal for healthy patient

EXPECTED BEHAVIOR:
✓ Lower thresholds for alerts due to immunosuppression
✓ Warning at HR 100 (vs standard 110)
✓ Escalation prompt emphasizes infection risk
✓ Recommendation: Blood cultures if any temperature rise
''';

  /// Scenario 3: Missed escalation safety net trigger
  /// Demonstrates: Safety net activating after no action on alert
  static const scenario3Description = '''
SCENARIO: Alert generated 45 minutes ago for Robert Williams (MED-8)
- Orange-level alert issued at 14:15
- No acknowledgment or action recorded
- Deadline passed (30 min for orange)

EXPECTED BEHAVIOR:
✓ Safety net shows "OVERDUE" status
✓ Time elapsed display: "45 min (15 min overdue)"
✓ Supervisor notification triggered
✓ Dashboard shows elevated overdue count
''';
}
