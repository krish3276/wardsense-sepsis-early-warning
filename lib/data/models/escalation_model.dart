/// Hive data model for Escalation
///
/// Hive-compatible model with type adapters for local persistence.

import 'package:hive/hive.dart';
import '../../../domain/entities/escalation.dart';
import '../../../core/constants/risk_level.dart';

part 'escalation_model.g.dart';

@HiveType(typeId: 4)
class EscalationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String patientId;

  @HiveField(2)
  final String alertId;

  @HiveField(3)
  final int escalationTypeIndex;

  @HiveField(4)
  final int riskLevelIndex;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final String initiatedBy;

  @HiveField(7)
  final String? notes;

  @HiveField(8)
  final bool isCompleted;

  @HiveField(9)
  final DateTime? completedAt;

  @HiveField(10)
  final String? outcome;

  EscalationModel({
    required this.id,
    required this.patientId,
    required this.alertId,
    required this.escalationTypeIndex,
    required this.riskLevelIndex,
    required this.timestamp,
    required this.initiatedBy,
    this.notes,
    this.isCompleted = false,
    this.completedAt,
    this.outcome,
  });

  /// Convert from domain entity
  factory EscalationModel.fromEntity(Escalation escalation) {
    return EscalationModel(
      id: escalation.id,
      patientId: escalation.patientId,
      alertId: escalation.alertId,
      escalationTypeIndex: escalation.type.index,
      riskLevelIndex: escalation.riskLevelAtEscalation.index,
      timestamp: escalation.timestamp,
      initiatedBy: escalation.initiatedBy,
      notes: escalation.notes,
      isCompleted: escalation.isCompleted,
      completedAt: escalation.completedAt,
      outcome: escalation.outcome,
    );
  }

  /// Convert to domain entity
  Escalation toEntity() {
    return Escalation(
      id: id,
      patientId: patientId,
      alertId: alertId,
      type: EscalationType.values[escalationTypeIndex],
      riskLevelAtEscalation: RiskLevel.values[riskLevelIndex],
      timestamp: timestamp,
      initiatedBy: initiatedBy,
      notes: notes,
      isCompleted: isCompleted,
      completedAt: completedAt,
      outcome: outcome,
    );
  }
}
