/// Hive data model for Alert
///
/// Hive-compatible model with type adapters for local persistence.

import 'package:hive/hive.dart';
import '../../../domain/entities/alert.dart';
import '../../../core/constants/risk_level.dart';

part 'alert_model.g.dart';

@HiveType(typeId: 2)
class AlertModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String patientId;

  @HiveField(2)
  final int riskLevelIndex;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final List<AlertFactorModel> factors;

  @HiveField(6)
  final List<String> recommendedActions;

  @HiveField(7)
  final DateTime timestamp;

  @HiveField(8)
  final bool isAcknowledged;

  @HiveField(9)
  final DateTime? acknowledgedAt;

  @HiveField(10)
  final String? acknowledgedBy;

  @HiveField(11)
  final String? acknowledgementNotes;

  @HiveField(12)
  final bool isEscalated;

  @HiveField(13)
  final String? triggeringVitalSignsId;

  @HiveField(14)
  final int analysisWindowHours;

  @HiveField(15)
  final bool isActive;

  AlertModel({
    required this.id,
    required this.patientId,
    required this.riskLevelIndex,
    required this.title,
    required this.description,
    required this.factors,
    required this.recommendedActions,
    required this.timestamp,
    required this.analysisWindowHours,
    this.isAcknowledged = false,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.acknowledgementNotes,
    this.isEscalated = false,
    this.triggeringVitalSignsId,
    this.isActive = true,
  });

  /// Convert from domain entity
  factory AlertModel.fromEntity(Alert alert) {
    return AlertModel(
      id: alert.id,
      patientId: alert.patientId,
      riskLevelIndex: alert.riskLevel.index,
      title: alert.title,
      description: alert.description,
      factors: alert.factors
          .map((f) => AlertFactorModel.fromEntity(f))
          .toList(),
      recommendedActions: alert.recommendedActions,
      timestamp: alert.timestamp,
      isAcknowledged: alert.isAcknowledged,
      acknowledgedAt: alert.acknowledgedAt,
      acknowledgedBy: alert.acknowledgedBy,
      acknowledgementNotes: alert.acknowledgementNotes,
      isEscalated: alert.isEscalated,
      triggeringVitalSignsId: alert.triggeringVitalSignsId,
      analysisWindowHours: alert.analysisWindowHours,
      isActive: alert.isActive,
    );
  }

  /// Convert to domain entity
  Alert toEntity() {
    return Alert(
      id: id,
      patientId: patientId,
      riskLevel: RiskLevel.values[riskLevelIndex],
      title: title,
      description: description,
      factors: factors.map((f) => f.toEntity()).toList(),
      recommendedActions: recommendedActions,
      timestamp: timestamp,
      isAcknowledged: isAcknowledged,
      acknowledgedAt: acknowledgedAt,
      acknowledgedBy: acknowledgedBy,
      acknowledgementNotes: acknowledgementNotes,
      isEscalated: isEscalated,
      triggeringVitalSignsId: triggeringVitalSignsId,
      analysisWindowHours: analysisWindowHours,
      isActive: isActive,
    );
  }
}

@HiveType(typeId: 3)
class AlertFactorModel extends HiveObject {
  @HiveField(0)
  final int vitalTypeIndex;

  @HiveField(1)
  final int directionIndex;

  @HiveField(2)
  final double currentValue;

  @HiveField(3)
  final double? previousValue;

  @HiveField(4)
  final double? percentageChange;

  @HiveField(5)
  final double? rateOfChangePerHour;

  @HiveField(6)
  final String shortDescription;

  @HiveField(7)
  final String explanation;

  @HiveField(8)
  final bool isCritical;

  AlertFactorModel({
    required this.vitalTypeIndex,
    required this.directionIndex,
    required this.currentValue,
    required this.shortDescription,
    required this.explanation,
    this.previousValue,
    this.percentageChange,
    this.rateOfChangePerHour,
    this.isCritical = false,
  });

  factory AlertFactorModel.fromEntity(AlertFactor factor) {
    return AlertFactorModel(
      vitalTypeIndex: factor.vitalType.index,
      directionIndex: factor.direction.index,
      currentValue: factor.currentValue,
      previousValue: factor.previousValue,
      percentageChange: factor.percentageChange,
      rateOfChangePerHour: factor.rateOfChangePerHour,
      shortDescription: factor.shortDescription,
      explanation: factor.explanation,
      isCritical: factor.isCritical,
    );
  }

  AlertFactor toEntity() {
    return AlertFactor(
      vitalType: VitalType.values[vitalTypeIndex],
      direction: TrendDirection.values[directionIndex],
      currentValue: currentValue,
      previousValue: previousValue,
      percentageChange: percentageChange,
      rateOfChangePerHour: rateOfChangePerHour,
      shortDescription: shortDescription,
      explanation: explanation,
      isCritical: isCritical,
    );
  }
}
