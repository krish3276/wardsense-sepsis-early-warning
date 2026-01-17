/// AI Prediction Entities
///
/// Data classes for AI/ML sepsis predictions including:
/// - Sepsis risk predictions with confidence scores
/// - qSOFA and SOFA clinical scores
/// - Anomaly detection results
/// - Feature importance rankings

import 'package:flutter/material.dart';

/// Sepsis risk level from AI prediction
enum SepsisRiskLevel {
  low,
  moderate,
  high,
  critical;

  String get displayName {
    switch (this) {
      case SepsisRiskLevel.low:
        return 'Low Risk';
      case SepsisRiskLevel.moderate:
        return 'Moderate Risk';
      case SepsisRiskLevel.high:
        return 'High Risk';
      case SepsisRiskLevel.critical:
        return 'Critical Risk';
    }
  }

  Color get color {
    switch (this) {
      case SepsisRiskLevel.low:
        return const Color(0xFF4CAF50);
      case SepsisRiskLevel.moderate:
        return const Color(0xFFFF9800);
      case SepsisRiskLevel.high:
        return const Color(0xFFF44336);
      case SepsisRiskLevel.critical:
        return const Color(0xFF9C27B0);
    }
  }

  IconData get icon {
    switch (this) {
      case SepsisRiskLevel.low:
        return Icons.check_circle;
      case SepsisRiskLevel.moderate:
        return Icons.warning_amber;
      case SepsisRiskLevel.high:
        return Icons.error;
      case SepsisRiskLevel.critical:
        return Icons.emergency;
    }
  }
}

/// Main AI prediction result
class SepsisPrediction {
  final double probability; // 0.0 to 1.0
  final SepsisRiskLevel riskLevel;
  final double confidence; // Model confidence 0.0 to 1.0
  final int qsofaScore; // Quick SOFA score (0-3)
  final int sofaScore; // Full SOFA score (0-24)
  final List<RiskFactor> topRiskFactors;
  final List<VitalAnomaly> anomalies;
  final String recommendation;
  final DateTime predictedAt;
  final int hoursToDeterioration; // Predicted hours until critical if untreated

  const SepsisPrediction({
    required this.probability,
    required this.riskLevel,
    required this.confidence,
    required this.qsofaScore,
    required this.sofaScore,
    required this.topRiskFactors,
    required this.anomalies,
    required this.recommendation,
    required this.predictedAt,
    required this.hoursToDeterioration,
  });

  /// Probability as percentage string
  String get probabilityPercent => '${(probability * 100).toStringAsFixed(1)}%';

  /// Confidence as percentage string
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';

  /// Whether the prediction indicates concern
  bool get requiresAttention =>
      riskLevel == SepsisRiskLevel.high ||
      riskLevel == SepsisRiskLevel.critical;

  /// Whether any anomalies were detected
  bool get hasAnomalies => anomalies.isNotEmpty;

  /// Get urgency description
  String get urgencyDescription {
    if (hoursToDeterioration <= 2) {
      return 'Immediate attention required';
    } else if (hoursToDeterioration <= 6) {
      return 'Close monitoring needed';
    } else if (hoursToDeterioration <= 12) {
      return 'Regular monitoring advised';
    } else {
      return 'Standard care protocol';
    }
  }
}

/// Individual risk factor with importance score
class RiskFactor {
  final String name;
  final String description;
  final double importance; // 0.0 to 1.0
  final String currentValue;
  final String normalRange;
  final bool isAbnormal;

  const RiskFactor({
    required this.name,
    required this.description,
    required this.importance,
    required this.currentValue,
    required this.normalRange,
    required this.isAbnormal,
  });

  /// Importance as percentage
  String get importancePercent => '${(importance * 100).toStringAsFixed(0)}%';
}

/// Vital sign anomaly detected by AI
class VitalAnomaly {
  final String vitalName;
  final String description;
  final AnomalyType type;
  final double severity; // 0.0 to 1.0
  final double deviation; // Standard deviations from normal
  final String trend;

  const VitalAnomaly({
    required this.vitalName,
    required this.description,
    required this.type,
    required this.severity,
    required this.deviation,
    required this.trend,
  });

  Color get severityColor {
    if (severity >= 0.8) return Colors.red;
    if (severity >= 0.6) return Colors.orange;
    if (severity >= 0.4) return Colors.amber;
    return Colors.yellow;
  }
}

/// Type of anomaly detected
enum AnomalyType {
  suddenSpike,
  suddenDrop,
  abnormalTrend,
  persistentDeviation,
  erraticPattern,
  correlatedChange;

  String get displayName {
    switch (this) {
      case AnomalyType.suddenSpike:
        return 'Sudden Spike';
      case AnomalyType.suddenDrop:
        return 'Sudden Drop';
      case AnomalyType.abnormalTrend:
        return 'Abnormal Trend';
      case AnomalyType.persistentDeviation:
        return 'Persistent Deviation';
      case AnomalyType.erraticPattern:
        return 'Erratic Pattern';
      case AnomalyType.correlatedChange:
        return 'Correlated Changes';
    }
  }

  IconData get icon {
    switch (this) {
      case AnomalyType.suddenSpike:
        return Icons.trending_up;
      case AnomalyType.suddenDrop:
        return Icons.trending_down;
      case AnomalyType.abnormalTrend:
        return Icons.show_chart;
      case AnomalyType.persistentDeviation:
        return Icons.swap_vert;
      case AnomalyType.erraticPattern:
        return Icons.waves;
      case AnomalyType.correlatedChange:
        return Icons.compare_arrows;
    }
  }
}

/// qSOFA criteria breakdown
class QSofaResult {
  final bool alteredMentalStatus; // GCS < 15 or AVPU != A
  final bool lowBloodPressure; // Systolic BP <= 100 mmHg
  final bool highRespiratoryRate; // RR >= 22/min
  final int totalScore;

  const QSofaResult({
    required this.alteredMentalStatus,
    required this.lowBloodPressure,
    required this.highRespiratoryRate,
  }) : totalScore = (alteredMentalStatus ? 1 : 0) +
            (lowBloodPressure ? 1 : 0) +
            (highRespiratoryRate ? 1 : 0);

  bool get sepsisLikely => totalScore >= 2;

  String get interpretation {
    if (totalScore >= 2) {
      return 'High risk of sepsis - consider ICU transfer';
    } else if (totalScore == 1) {
      return 'Monitor closely for deterioration';
    } else {
      return 'Low qSOFA score - continue standard monitoring';
    }
  }

  List<String> get positiveCriteria {
    final criteria = <String>[];
    if (alteredMentalStatus) criteria.add('Altered mental status');
    if (lowBloodPressure) criteria.add('Systolic BP ≤100 mmHg');
    if (highRespiratoryRate) criteria.add('Respiratory rate ≥22/min');
    return criteria;
  }
}

/// SOFA score component
class SofaComponent {
  final String system;
  final int score; // 0-4
  final String value;
  final String criteria;

  const SofaComponent({
    required this.system,
    required this.score,
    required this.value,
    required this.criteria,
  });
}

/// Full SOFA score result
class SofaResult {
  final List<SofaComponent> components;
  final int totalScore;
  final double mortalityRisk;

  const SofaResult({
    required this.components,
    required this.totalScore,
    required this.mortalityRisk,
  });

  String get mortalityRiskPercent =>
      '${(mortalityRisk * 100).toStringAsFixed(0)}%';

  String get interpretation {
    if (totalScore >= 11) {
      return 'Very high mortality risk (>95%)';
    } else if (totalScore >= 9) {
      return 'High mortality risk (>50%)';
    } else if (totalScore >= 6) {
      return 'Moderate mortality risk (>20%)';
    } else if (totalScore >= 3) {
      return 'Low-moderate mortality risk';
    } else {
      return 'Low mortality risk';
    }
  }
}

/// AI model metadata
class AIModelInfo {
  final String name;
  final String version;
  final String type;
  final double accuracy;
  final double sensitivity;
  final double specificity;
  final DateTime trainedOn;
  final int trainingDataSize;

  const AIModelInfo({
    required this.name,
    required this.version,
    required this.type,
    required this.accuracy,
    required this.sensitivity,
    required this.specificity,
    required this.trainedOn,
    required this.trainingDataSize,
  });
}
