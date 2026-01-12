/// Escalation entity representing a clinical escalation action
///
/// Tracks when and how clinical escalation occurred in response to alerts.
/// Provides audit trail for clinical governance and quality improvement.

import 'package:equatable/equatable.dart';
import '../../core/constants/risk_level.dart';

/// Escalation entity
///
/// Records clinical escalation actions taken in response to alerts.
class Escalation extends Equatable {
  /// Unique identifier for this escalation
  final String id;

  /// Reference to the patient
  final String patientId;

  /// Reference to the alert that triggered this escalation
  final String alertId;

  /// Type of escalation action taken
  final EscalationType type;

  /// Risk level at time of escalation
  final RiskLevel riskLevelAtEscalation;

  /// Timestamp when escalation was initiated
  final DateTime timestamp;

  /// ID of user who initiated the escalation
  final String initiatedBy;

  /// Notes about the escalation
  final String? notes;

  /// Whether the escalation has been completed/resolved
  final bool isCompleted;

  /// Timestamp when escalation was completed
  final DateTime? completedAt;

  /// Outcome of the escalation
  final String? outcome;

  const Escalation({
    required this.id,
    required this.patientId,
    required this.alertId,
    required this.type,
    required this.riskLevelAtEscalation,
    required this.timestamp,
    required this.initiatedBy,
    this.notes,
    this.isCompleted = false,
    this.completedAt,
    this.outcome,
  });

  /// Create a copy with updated fields
  Escalation copyWith({
    String? id,
    String? patientId,
    String? alertId,
    EscalationType? type,
    RiskLevel? riskLevelAtEscalation,
    DateTime? timestamp,
    String? initiatedBy,
    String? notes,
    bool? isCompleted,
    DateTime? completedAt,
    String? outcome,
  }) {
    return Escalation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      alertId: alertId ?? this.alertId,
      type: type ?? this.type,
      riskLevelAtEscalation:
          riskLevelAtEscalation ?? this.riskLevelAtEscalation,
      timestamp: timestamp ?? this.timestamp,
      initiatedBy: initiatedBy ?? this.initiatedBy,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      outcome: outcome ?? this.outcome,
    );
  }

  /// Get duration since escalation
  Duration get timeSinceEscalation => DateTime.now().difference(timestamp);

  @override
  List<Object?> get props => [
    id,
    patientId,
    alertId,
    type,
    riskLevelAtEscalation,
    timestamp,
    initiatedBy,
    notes,
    isCompleted,
    completedAt,
    outcome,
  ];
}

/// Types of clinical escalation
enum EscalationType {
  /// Repeat vital signs measurement
  repeatVitals,

  /// Inform nurse in charge
  informNurseInCharge,

  /// Notify duty doctor
  notifyDutyDoctor,

  /// Request urgent medical review
  urgentMedicalReview,

  /// Activate sepsis protocol
  sepsisProtocol,

  /// Call rapid response team
  rapidResponseTeam,

  /// Call medical emergency team
  medicalEmergencyTeam,
}

/// Extension for EscalationType
extension EscalationTypeExtension on EscalationType {
  String get displayName {
    switch (this) {
      case EscalationType.repeatVitals:
        return 'Repeat Vitals';
      case EscalationType.informNurseInCharge:
        return 'Inform Nurse In Charge';
      case EscalationType.notifyDutyDoctor:
        return 'Notify Duty Doctor';
      case EscalationType.urgentMedicalReview:
        return 'Urgent Medical Review';
      case EscalationType.sepsisProtocol:
        return 'Sepsis Protocol';
      case EscalationType.rapidResponseTeam:
        return 'Rapid Response Team';
      case EscalationType.medicalEmergencyTeam:
        return 'Medical Emergency Team';
    }
  }

  String get description {
    switch (this) {
      case EscalationType.repeatVitals:
        return 'Measure vital signs again to confirm readings';
      case EscalationType.informNurseInCharge:
        return 'Alert the nurse in charge about patient status';
      case EscalationType.notifyDutyDoctor:
        return 'Contact the on-call doctor for assessment';
      case EscalationType.urgentMedicalReview:
        return 'Request immediate medical team review';
      case EscalationType.sepsisProtocol:
        return 'Initiate hospital sepsis management protocol';
      case EscalationType.rapidResponseTeam:
        return 'Activate rapid response team for urgent intervention';
      case EscalationType.medicalEmergencyTeam:
        return 'Call medical emergency team for critical intervention';
    }
  }

  /// Priority level (higher = more urgent)
  int get priority {
    switch (this) {
      case EscalationType.repeatVitals:
        return 1;
      case EscalationType.informNurseInCharge:
        return 2;
      case EscalationType.notifyDutyDoctor:
        return 3;
      case EscalationType.urgentMedicalReview:
        return 4;
      case EscalationType.sepsisProtocol:
        return 5;
      case EscalationType.rapidResponseTeam:
        return 6;
      case EscalationType.medicalEmergencyTeam:
        return 7;
    }
  }

  /// Get recommended escalations for a risk level
  static List<EscalationType> forRiskLevel(RiskLevel level) {
    switch (level) {
      case RiskLevel.green:
        return [];
      case RiskLevel.yellow:
        return [
          EscalationType.repeatVitals,
          EscalationType.informNurseInCharge,
        ];
      case RiskLevel.orange:
        return [
          EscalationType.repeatVitals,
          EscalationType.notifyDutyDoctor,
          EscalationType.urgentMedicalReview,
        ];
      case RiskLevel.red:
        return [
          EscalationType.notifyDutyDoctor,
          EscalationType.sepsisProtocol,
          EscalationType.rapidResponseTeam,
        ];
    }
  }
}
