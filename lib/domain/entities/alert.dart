/// Alert entity representing a clinical alert triggered by the system
///
/// Alerts are generated when trend analysis detects deterioration patterns
/// or when vital signs exceed thresholds. Each alert includes explainability
/// information to support clinical decision-making.

import 'package:equatable/equatable.dart';
import '../../core/constants/risk_level.dart';

/// Alert entity
///
/// Represents a clinical alert with full explainability.
/// Designed to support (not replace) clinical judgment.
class Alert extends Equatable {
  /// Unique identifier for this alert
  final String id;

  /// Reference to the patient
  final String patientId;

  /// Risk level of this alert
  final RiskLevel riskLevel;

  /// Main alert title (e.g., "Rising Heart Rate with Falling BP")
  final String title;

  /// Detailed description of the alert
  final String description;

  /// List of contributing factors with explanations
  final List<AlertFactor> factors;

  /// Recommended actions for this alert
  final List<String> recommendedActions;

  /// Timestamp when alert was generated
  final DateTime timestamp;

  /// Whether the alert has been acknowledged
  final bool isAcknowledged;

  /// Timestamp when alert was acknowledged
  final DateTime? acknowledgedAt;

  /// ID of user who acknowledged the alert
  final String? acknowledgedBy;

  /// Notes added when acknowledging
  final String? acknowledgementNotes;

  /// Whether the alert has been escalated
  final bool isEscalated;

  /// Reference to the vital signs that triggered this alert
  final String? triggeringVitalSignsId;

  /// Time window analyzed for this alert (in hours)
  final int analysisWindowHours;

  /// Whether this alert is still active
  final bool isActive;

  const Alert({
    required this.id,
    required this.patientId,
    required this.riskLevel,
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

  /// Create a copy with updated fields
  Alert copyWith({
    String? id,
    String? patientId,
    RiskLevel? riskLevel,
    String? title,
    String? description,
    List<AlertFactor>? factors,
    List<String>? recommendedActions,
    DateTime? timestamp,
    bool? isAcknowledged,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    String? acknowledgementNotes,
    bool? isEscalated,
    String? triggeringVitalSignsId,
    int? analysisWindowHours,
    bool? isActive,
  }) {
    return Alert(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      riskLevel: riskLevel ?? this.riskLevel,
      title: title ?? this.title,
      description: description ?? this.description,
      factors: factors ?? this.factors,
      recommendedActions: recommendedActions ?? this.recommendedActions,
      timestamp: timestamp ?? this.timestamp,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgementNotes: acknowledgementNotes ?? this.acknowledgementNotes,
      isEscalated: isEscalated ?? this.isEscalated,
      triggeringVitalSignsId:
          triggeringVitalSignsId ?? this.triggeringVitalSignsId,
      analysisWindowHours: analysisWindowHours ?? this.analysisWindowHours,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get formatted time since alert
  String get timeSinceAlert {
    final duration = DateTime.now().difference(timestamp);
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hours ago';
    } else {
      return '${duration.inDays} days ago';
    }
  }

  /// Check if alert requires immediate attention
  bool get requiresImmediateAttention {
    return riskLevel == RiskLevel.red || riskLevel == RiskLevel.orange;
  }

  /// Get summary of factors for quick display
  String get factorsSummary {
    return factors.map((f) => f.shortDescription).join(' • ');
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    riskLevel,
    title,
    description,
    factors,
    recommendedActions,
    timestamp,
    isAcknowledged,
    acknowledgedAt,
    acknowledgedBy,
    acknowledgementNotes,
    isEscalated,
    triggeringVitalSignsId,
    analysisWindowHours,
    isActive,
  ];
}

/// A contributing factor to an alert with explainability
///
/// Each factor explains one aspect of why the alert was triggered,
/// providing transparency and supporting clinical decision-making.
class AlertFactor extends Equatable {
  /// Type of vital sign or parameter
  final VitalType vitalType;

  /// Direction of change (rising, falling, stable)
  final TrendDirection direction;

  /// Current value
  final double currentValue;

  /// Previous value (for comparison)
  final double? previousValue;

  /// Percentage change
  final double? percentageChange;

  /// Rate of change per hour
  final double? rateOfChangePerHour;

  /// Short description (e.g., "HR ↑ 25%")
  final String shortDescription;

  /// Detailed explanation
  final String explanation;

  /// Whether this factor alone would trigger an alert
  final bool isCritical;

  const AlertFactor({
    required this.vitalType,
    required this.direction,
    required this.currentValue,
    required this.shortDescription,
    required this.explanation,
    this.previousValue,
    this.percentageChange,
    this.rateOfChangePerHour,
    this.isCritical = false,
  });

  @override
  List<Object?> get props => [
    vitalType,
    direction,
    currentValue,
    previousValue,
    percentageChange,
    rateOfChangePerHour,
    shortDescription,
    explanation,
    isCritical,
  ];
}

/// Types of vital signs monitored
enum VitalType {
  heartRate,
  systolicBP,
  diastolicBP,
  respiratoryRate,
  temperature,
  spO2,
}

/// Extension for VitalType
extension VitalTypeExtension on VitalType {
  String get displayName {
    switch (this) {
      case VitalType.heartRate:
        return 'Heart Rate';
      case VitalType.systolicBP:
        return 'Systolic BP';
      case VitalType.diastolicBP:
        return 'Diastolic BP';
      case VitalType.respiratoryRate:
        return 'Respiratory Rate';
      case VitalType.temperature:
        return 'Temperature';
      case VitalType.spO2:
        return 'SpO₂';
    }
  }

  String get shortName {
    switch (this) {
      case VitalType.heartRate:
        return 'HR';
      case VitalType.systolicBP:
        return 'SBP';
      case VitalType.diastolicBP:
        return 'DBP';
      case VitalType.respiratoryRate:
        return 'RR';
      case VitalType.temperature:
        return 'Temp';
      case VitalType.spO2:
        return 'SpO₂';
    }
  }

  String get unit {
    switch (this) {
      case VitalType.heartRate:
        return 'bpm';
      case VitalType.systolicBP:
      case VitalType.diastolicBP:
        return 'mmHg';
      case VitalType.respiratoryRate:
        return '/min';
      case VitalType.temperature:
        return '°C';
      case VitalType.spO2:
        return '%';
    }
  }
}

/// Direction of trend
enum TrendDirection { rising, falling, stable, unknown }

/// Extension for TrendDirection
extension TrendDirectionExtension on TrendDirection {
  String get arrow {
    switch (this) {
      case TrendDirection.rising:
        return '↑';
      case TrendDirection.falling:
        return '↓';
      case TrendDirection.stable:
        return '→';
      case TrendDirection.unknown:
        return '−';
    }
  }

  String get displayName {
    switch (this) {
      case TrendDirection.rising:
        return 'Rising';
      case TrendDirection.falling:
        return 'Falling';
      case TrendDirection.stable:
        return 'Stable';
      case TrendDirection.unknown:
        return 'Unknown';
    }
  }
}
