/// Vital Trend Velocity Service
///
/// Calculates the RATE OF CHANGE of vital signs over rolling time windows.
/// This is the core implementation for Feature 2.
///
/// CLINICAL RATIONALE:
/// Traditional threshold-based alerts only fire when values cross boundaries.
/// Velocity analysis detects DETERIORATION TRAJECTORIES even when absolute
/// values remain within normal range.
///
/// Example:
/// - Heart rate: 72 → 78 → 85 → 92 over 4 hours
/// - All values are "normal" (<100 bpm)
/// - BUT the trajectory suggests deterioration
///
/// This service uses simple, explainable mathematics:
/// - Linear slope calculation
/// - Absolute change measurement
/// - Rate per hour computation
/// NO black-box ML. Every calculation is transparent and auditable.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vital_signs.dart';
import '../../domain/entities/vital_velocity.dart';
import '../../domain/entities/alert.dart'; // For VitalType and TrendDirection
import '../../data/repositories/vital_signs_repository.dart';

/// Provider for the velocity analysis service
final velocityAnalysisServiceProvider = Provider<VelocityAnalysisService>((
  ref,
) {
  return VelocityAnalysisService(ref.read(vitalSignsRepositoryProvider));
});

/// Velocity Analysis Service
///
/// Provides velocity-based trend analysis for vital signs.
class VelocityAnalysisService {
  final VitalSignsRepository _vitalsRepository;

  VelocityAnalysisService(this._vitalsRepository);

  /// Analyze vital sign velocity for a patient over a specified window
  ///
  /// Returns a complete velocity analysis including individual vital
  /// velocities and overall deterioration assessment.
  VelocityAnalysisResult analyzeVelocity(
    String patientId, {
    VelocityWindow window = VelocityWindow.sixHours,
  }) {
    // Get vital signs within the time window
    final vitals = _vitalsRepository.getVitalSignsInWindow(
      patientId,
      window.hours,
    );

    // Need at least 2 readings for velocity calculation
    if (vitals.length < 2) {
      return VelocityAnalysisResult.insufficientData(patientId);
    }

    // Calculate velocity for each vital parameter
    final velocities = <VitalVelocity>[
      _calculateVelocity(
        vitals,
        VitalType.heartRate,
        (v) => v.heartRate.toDouble(),
        window,
        _classifyHeartRateVelocity,
        concernWhenRising: true,
      ),
      _calculateVelocity(
        vitals,
        VitalType.systolicBP,
        (v) => v.systolicBP.toDouble(),
        window,
        _classifySystolicBPVelocity,
        concernWhenRising: false, // Concerned about DROPS in BP
      ),
      _calculateVelocity(
        vitals,
        VitalType.respiratoryRate,
        (v) => v.respiratoryRate.toDouble(),
        window,
        _classifyRespiratoryRateVelocity,
        concernWhenRising: true,
      ),
    ];

    // Check for rapid deterioration
    final hasRapidDeterioration = velocities.any(
      (v) =>
          v.severity == VelocitySeverity.rapid ||
          v.severity == VelocitySeverity.critical,
    );

    // Check for sepsis velocity pattern
    // (HR rising + BP falling + RR rising)
    final hasSepsisPattern = _detectSepsisVelocityPattern(velocities);

    // Generate summary
    final summary = _generateSummary(velocities, hasRapidDeterioration);

    return VelocityAnalysisResult(
      patientId: patientId,
      window: window,
      velocities: velocities,
      hasRapidDeterioration: hasRapidDeterioration,
      hasSepsisVelocityPattern: hasSepsisPattern,
      summary: summary,
      analysisTime: DateTime.now(),
      windowStartTime: vitals.first.timestamp,
      windowEndTime: vitals.last.timestamp,
    );
  }

  /// Calculate velocity for a single vital parameter
  VitalVelocity _calculateVelocity(
    List<VitalSigns> vitals,
    VitalType type,
    double Function(VitalSigns) getValue,
    VelocityWindow window,
    VelocitySeverity Function(double, double, bool) classifySeverity, {
    required bool concernWhenRising,
  }) {
    final startValue = getValue(vitals.first);
    final endValue = getValue(vitals.last);

    // Calculate actual time span
    final actualSpan = vitals.last.timestamp.difference(vitals.first.timestamp);
    final hours = actualSpan.inMinutes / 60.0;

    // Absolute change
    final absoluteChange = endValue - startValue;

    // Percentage change (avoid division by zero)
    final percentageChange =
        startValue != 0 ? (absoluteChange / startValue) * 100 : 0.0;

    // Rate per hour
    final ratePerHour = hours > 0 ? absoluteChange / hours : 0.0;

    // Determine direction
    final direction = _determineDirection(absoluteChange, type);

    // Classify severity
    final severity = classifySeverity(
      ratePerHour.abs(),
      absoluteChange.abs(),
      concernWhenRising,
    );

    // Determine if concerning based on direction and severity
    final isConcerning = _isConcerningVelocity(
      direction,
      severity,
      concernWhenRising,
    );

    // Generate explanation
    final explanation = _generateVelocityExplanation(
      type,
      startValue,
      endValue,
      absoluteChange,
      hours,
      direction,
    );

    // Generate clinical interpretation
    final interpretation = _generateInterpretation(
      type,
      direction,
      severity,
      isConcerning,
    );

    return VitalVelocity(
      vitalType: type,
      window: window,
      startValue: startValue,
      endValue: endValue,
      absoluteChange: absoluteChange,
      percentageChange: percentageChange,
      ratePerHour: ratePerHour,
      severity: severity,
      direction: direction,
      isConcerning: isConcerning,
      explanation: explanation,
      interpretation: interpretation,
      actualTimeSpan: actualSpan,
      dataPointCount: vitals.length,
    );
  }

  /// Determine trend direction from absolute change
  TrendDirection _determineDirection(double change, VitalType type) {
    // Use type-specific thresholds for "stable"
    final threshold = _getStabilityThreshold(type);

    if (change.abs() < threshold) {
      return TrendDirection.stable;
    }
    return change > 0 ? TrendDirection.rising : TrendDirection.falling;
  }

  /// Get the threshold below which a vital is considered "stable"
  double _getStabilityThreshold(VitalType type) {
    switch (type) {
      case VitalType.heartRate:
        return 5.0; // ±5 bpm is stable
      case VitalType.systolicBP:
      case VitalType.diastolicBP:
        return 5.0; // ±5 mmHg is stable
      case VitalType.respiratoryRate:
        return 2.0; // ±2 breaths/min is stable
      case VitalType.temperature:
        return 0.3; // ±0.3°C is stable
      case VitalType.spO2:
        return 2.0; // ±2% is stable
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEART RATE VELOCITY CLASSIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  VelocitySeverity _classifyHeartRateVelocity(
    double ratePerHour,
    double absoluteChange,
    bool concernWhenRising,
  ) {
    // Check absolute change first (over the whole window)
    if (absoluteChange >= VelocityThresholds.hrConcerningAbsoluteChange) {
      if (ratePerHour >= VelocityThresholds.hrCriticalRatePerHour) {
        return VelocitySeverity.critical;
      }
      return VelocitySeverity.rapid;
    }

    // Classify by rate of change
    if (ratePerHour >= VelocityThresholds.hrCriticalRatePerHour) {
      return VelocitySeverity.critical;
    }
    if (ratePerHour >= VelocityThresholds.hrRapidRatePerHour) {
      return VelocitySeverity.rapid;
    }
    if (ratePerHour >= VelocityThresholds.hrModerateRatePerHour) {
      return VelocitySeverity.moderate;
    }
    if (ratePerHour >= VelocityThresholds.hrMildRatePerHour) {
      return VelocitySeverity.mild;
    }

    return VelocitySeverity.stable;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BLOOD PRESSURE VELOCITY CLASSIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  VelocitySeverity _classifySystolicBPVelocity(
    double ratePerHour,
    double absoluteChange,
    bool concernWhenRising,
  ) {
    // For BP, we're primarily concerned about DROPS
    // But we use absolute values for classification

    if (absoluteChange >= VelocityThresholds.sbpConcerningAbsoluteChange) {
      if (ratePerHour >= VelocityThresholds.sbpCriticalRatePerHour) {
        return VelocitySeverity.critical;
      }
      return VelocitySeverity.rapid;
    }

    if (ratePerHour >= VelocityThresholds.sbpCriticalRatePerHour) {
      return VelocitySeverity.critical;
    }
    if (ratePerHour >= VelocityThresholds.sbpRapidRatePerHour) {
      return VelocitySeverity.rapid;
    }
    if (ratePerHour >= VelocityThresholds.sbpModerateRatePerHour) {
      return VelocitySeverity.moderate;
    }
    if (ratePerHour >= VelocityThresholds.sbpMildRatePerHour) {
      return VelocitySeverity.mild;
    }

    return VelocitySeverity.stable;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESPIRATORY RATE VELOCITY CLASSIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  VelocitySeverity _classifyRespiratoryRateVelocity(
    double ratePerHour,
    double absoluteChange,
    bool concernWhenRising,
  ) {
    if (absoluteChange >= VelocityThresholds.rrConcerningAbsoluteChange) {
      if (ratePerHour >= VelocityThresholds.rrCriticalRatePerHour) {
        return VelocitySeverity.critical;
      }
      return VelocitySeverity.rapid;
    }

    if (ratePerHour >= VelocityThresholds.rrCriticalRatePerHour) {
      return VelocitySeverity.critical;
    }
    if (ratePerHour >= VelocityThresholds.rrRapidRatePerHour) {
      return VelocitySeverity.rapid;
    }
    if (ratePerHour >= VelocityThresholds.rrModerateRatePerHour) {
      return VelocitySeverity.moderate;
    }
    if (ratePerHour >= VelocityThresholds.rrMildRatePerHour) {
      return VelocitySeverity.mild;
    }

    return VelocitySeverity.stable;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PATTERN DETECTION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Detect sepsis velocity pattern
  ///
  /// Classic sepsis pattern based on velocity:
  /// - Heart rate RISING
  /// - Blood pressure FALLING
  /// - Respiratory rate RISING
  bool _detectSepsisVelocityPattern(List<VitalVelocity> velocities) {
    bool hrRising = false;
    bool bpFalling = false;
    bool rrRising = false;

    for (final velocity in velocities) {
      switch (velocity.vitalType) {
        case VitalType.heartRate:
          hrRising = velocity.direction == TrendDirection.rising &&
              velocity.isConcerning;
          break;
        case VitalType.systolicBP:
          bpFalling = velocity.direction == TrendDirection.falling &&
              velocity.isConcerning;
          break;
        case VitalType.respiratoryRate:
          rrRising = velocity.direction == TrendDirection.rising &&
              velocity.isConcerning;
          break;
        default:
          break;
      }
    }

    // Need at least 2 of 3 indicators
    int indicators = 0;
    if (hrRising) indicators++;
    if (bpFalling) indicators++;
    if (rrRising) indicators++;

    return indicators >= 2;
  }

  /// Determine if velocity is concerning based on direction
  bool _isConcerningVelocity(
    TrendDirection direction,
    VelocitySeverity severity,
    bool concernWhenRising,
  ) {
    if (severity == VelocitySeverity.stable) return false;

    // For HR and RR: rising is concerning
    // For BP: falling is concerning
    if (concernWhenRising) {
      return direction == TrendDirection.rising &&
          severity != VelocitySeverity.stable;
    } else {
      return direction == TrendDirection.falling &&
          severity != VelocitySeverity.stable;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPLANATION GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate human-readable explanation for a velocity result
  String _generateVelocityExplanation(
    VitalType type,
    double startValue,
    double endValue,
    double absoluteChange,
    double hours,
    TrendDirection direction,
  ) {
    final typeName = _getVitalTypeName(type);
    final unit = _getVitalUnit(type);
    final changeWord = direction == TrendDirection.rising
        ? 'increased'
        : direction == TrendDirection.falling
            ? 'decreased'
            : 'remained stable';

    final hoursText = hours < 1
        ? '${(hours * 60).round()} minutes'
        : hours == 1
            ? '1 hour'
            : '${hours.toStringAsFixed(1)} hours';

    if (direction == TrendDirection.stable) {
      return '$typeName $changeWord at ${endValue.toStringAsFixed(0)}$unit over $hoursText.';
    }

    return '$typeName $changeWord from ${startValue.toStringAsFixed(0)} to '
        '${endValue.toStringAsFixed(0)}$unit (${absoluteChange > 0 ? '+' : ''}${absoluteChange.toStringAsFixed(0)}) '
        'over $hoursText.';
  }

  /// Generate clinical interpretation
  String _generateInterpretation(
    VitalType type,
    TrendDirection direction,
    VelocitySeverity severity,
    bool isConcerning,
  ) {
    if (!isConcerning || severity == VelocitySeverity.stable) {
      return 'Rate of change within expected limits.';
    }

    final typeName = _getVitalTypeName(type);
    final severityText = severity == VelocitySeverity.critical
        ? 'critically rapid'
        : severity == VelocitySeverity.rapid
            ? 'rapid'
            : severity == VelocitySeverity.moderate
                ? 'moderate'
                : 'mild';

    final directionText = direction == TrendDirection.rising
        ? 'increase'
        : direction == TrendDirection.falling
            ? 'decrease'
            : 'change';

    return 'A $severityText $typeName $directionText detected. '
        'Consider repeat measurement to confirm trend.';
  }

  /// Generate overall summary
  String _generateSummary(
    List<VitalVelocity> velocities,
    bool hasRapidDeterioration,
  ) {
    final concerningVelocities =
        velocities.where((v) => v.isConcerning).toList();

    if (concerningVelocities.isEmpty) {
      return 'All vital sign velocities within normal limits. No rapid changes detected.';
    }

    final descriptions = concerningVelocities.map((v) {
      final typeName = _getVitalTypeName(v.vitalType);
      final direction =
          v.direction == TrendDirection.rising ? 'rising' : 'falling';
      return '$typeName $direction (${v.absoluteChange > 0 ? '+' : ''}${v.absoluteChange.toStringAsFixed(0)} ${_getVitalUnit(v.vitalType)})';
    }).toList();

    final prefix = hasRapidDeterioration
        ? 'Rapid deterioration detected: '
        : 'Concerning velocity trends: ';

    return '$prefix${descriptions.join(', ')}.';
  }

  String _getVitalTypeName(VitalType type) {
    switch (type) {
      case VitalType.heartRate:
        return 'Heart rate';
      case VitalType.systolicBP:
        return 'Systolic BP';
      case VitalType.diastolicBP:
        return 'Diastolic BP';
      case VitalType.respiratoryRate:
        return 'Respiratory rate';
      case VitalType.temperature:
        return 'Temperature';
      case VitalType.spO2:
        return 'SpO₂';
    }
  }

  String _getVitalUnit(VitalType type) {
    switch (type) {
      case VitalType.heartRate:
        return ' bpm';
      case VitalType.systolicBP:
      case VitalType.diastolicBP:
        return ' mmHg';
      case VitalType.respiratoryRate:
        return '/min';
      case VitalType.temperature:
        return '°C';
      case VitalType.spO2:
        return '%';
    }
  }
}
