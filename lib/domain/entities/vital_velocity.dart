/// Vital Trend Velocity entity
///
/// Captures the RATE OF CHANGE of vital signs over time windows.
/// This is the core innovation for Feature 2: detecting deterioration
/// even when absolute values are still within normal range.
///
/// CLINICAL RATIONALE:
/// "A heart rate rising from 70 to 95 in 4 hours is more concerning
/// than a stable heart rate of 100."
///
/// Traditional monitoring only alerts on threshold breaches.
/// Velocity-based analysis detects TRAJECTORIES of deterioration.

import 'package:equatable/equatable.dart';
import '../../domain/entities/alert.dart'; // For VitalType and TrendDirection

/// Time window for velocity calculation
enum VelocityWindow {
  /// 2-hour window - early detection
  twoHours,

  /// 4-hour window - standard analysis
  fourHours,

  /// 6-hour window - trend confirmation
  sixHours,

  /// 8-hour window - extended trend
  eightHours,
}

extension VelocityWindowExtension on VelocityWindow {
  int get hours {
    switch (this) {
      case VelocityWindow.twoHours:
        return 2;
      case VelocityWindow.fourHours:
        return 4;
      case VelocityWindow.sixHours:
        return 6;
      case VelocityWindow.eightHours:
        return 8;
    }
  }

  Duration get duration => Duration(hours: hours);

  String get displayName => '$hours hours';
}

/// Classification of velocity severity
enum VelocitySeverity {
  /// Normal rate of change or stable
  stable,

  /// Mild concerning trend
  mild,

  /// Moderate concerning trend - warrants attention
  moderate,

  /// Rapid change - requires prompt review
  rapid,

  /// Critical rate of deterioration
  critical,
}

extension VelocitySeverityExtension on VelocitySeverity {
  String get displayName {
    switch (this) {
      case VelocitySeverity.stable:
        return 'Stable';
      case VelocitySeverity.mild:
        return 'Mild Change';
      case VelocitySeverity.moderate:
        return 'Moderate Change';
      case VelocitySeverity.rapid:
        return 'Rapid Change';
      case VelocitySeverity.critical:
        return 'Critical Change';
    }
  }

  bool get isConcerning => this != VelocitySeverity.stable;

  bool get requiresAttention =>
      this == VelocitySeverity.moderate ||
      this == VelocitySeverity.rapid ||
      this == VelocitySeverity.critical;
}

/// Velocity result for a single vital parameter
class VitalVelocity extends Equatable {
  /// Type of vital sign being analyzed
  final VitalType vitalType;

  /// Time window used for calculation
  final VelocityWindow window;

  /// Starting value at window start
  final double startValue;

  /// Current/ending value
  final double endValue;

  /// Absolute change (can be negative)
  final double absoluteChange;

  /// Percentage change
  final double percentageChange;

  /// Rate of change per hour
  final double ratePerHour;

  /// Severity classification
  final VelocitySeverity severity;

  /// Direction of change
  final TrendDirection direction;

  /// Whether this velocity pattern is concerning
  final bool isConcerning;

  /// Human-readable explanation
  final String explanation;

  /// Clinical interpretation
  final String interpretation;

  /// Actual time span covered (may differ from window)
  final Duration actualTimeSpan;

  /// Number of data points used
  final int dataPointCount;

  const VitalVelocity({
    required this.vitalType,
    required this.window,
    required this.startValue,
    required this.endValue,
    required this.absoluteChange,
    required this.percentageChange,
    required this.ratePerHour,
    required this.severity,
    required this.direction,
    required this.isConcerning,
    required this.explanation,
    required this.interpretation,
    required this.actualTimeSpan,
    required this.dataPointCount,
  });

  @override
  List<Object?> get props => [
        vitalType,
        window,
        startValue,
        endValue,
        absoluteChange,
        severity,
        direction,
      ];
}

/// Combined velocity analysis result for all vitals
class VelocityAnalysisResult extends Equatable {
  /// Patient ID
  final String patientId;

  /// Time window used for analysis
  final VelocityWindow window;

  /// Velocity results for each vital parameter
  final List<VitalVelocity> velocities;

  /// Overall concerning velocity detected
  final bool hasRapidDeterioration;

  /// Whether pattern suggests developing sepsis
  final bool hasSepsisVelocityPattern;

  /// Combined summary explanation
  final String summary;

  /// Timestamp of analysis
  final DateTime analysisTime;

  /// Earliest vital sign timestamp used
  final DateTime? windowStartTime;

  /// Latest vital sign timestamp used
  final DateTime? windowEndTime;

  const VelocityAnalysisResult({
    required this.patientId,
    required this.window,
    required this.velocities,
    required this.hasRapidDeterioration,
    required this.hasSepsisVelocityPattern,
    required this.summary,
    required this.analysisTime,
    this.windowStartTime,
    this.windowEndTime,
  });

  /// Get velocity for a specific vital type
  VitalVelocity? getVelocity(VitalType type) {
    try {
      return velocities.firstWhere((v) => v.vitalType == type);
    } catch (_) {
      return null;
    }
  }

  /// Get all concerning velocities
  List<VitalVelocity> get concerningVelocities =>
      velocities.where((v) => v.isConcerning).toList();

  /// Get velocities requiring attention
  List<VitalVelocity> get attentionRequiredVelocities =>
      velocities.where((v) => v.severity.requiresAttention).toList();

  /// Heart rate velocity
  VitalVelocity? get heartRateVelocity => getVelocity(VitalType.heartRate);

  /// Blood pressure velocity
  VitalVelocity? get systolicBPVelocity => getVelocity(VitalType.systolicBP);

  /// Respiratory rate velocity
  VitalVelocity? get respiratoryRateVelocity =>
      getVelocity(VitalType.respiratoryRate);

  @override
  List<Object?> get props => [
        patientId,
        window,
        velocities,
        hasRapidDeterioration,
        hasSepsisVelocityPattern,
        analysisTime,
      ];

  /// Create an empty result when insufficient data
  factory VelocityAnalysisResult.insufficientData(String patientId) {
    return VelocityAnalysisResult(
      patientId: patientId,
      window: VelocityWindow.sixHours,
      velocities: const [],
      hasRapidDeterioration: false,
      hasSepsisVelocityPattern: false,
      summary: 'Insufficient data for velocity analysis. '
          'At least 2 vital sign readings within the analysis window are required.',
      analysisTime: DateTime.now(),
    );
  }
}

/// Thresholds for velocity analysis
///
/// These are the rate-of-change thresholds that indicate concerning trends.
/// Based on clinical judgment for what constitutes rapid deterioration.
class VelocityThresholds {
  VelocityThresholds._();

  // ═══════════════════════════════════════════════════════════════════════════
  // HEART RATE VELOCITY THRESHOLDS (bpm per hour)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mild HR increase: 3-5 bpm/hour
  static const double hrMildRatePerHour = 3.0;

  /// Moderate HR increase: 5-8 bpm/hour
  static const double hrModerateRatePerHour = 5.0;

  /// Rapid HR increase: 8-12 bpm/hour
  static const double hrRapidRatePerHour = 8.0;

  /// Critical HR increase: >12 bpm/hour
  static const double hrCriticalRatePerHour = 12.0;

  /// Absolute HR change threshold (over window): 20 bpm
  static const double hrConcerningAbsoluteChange = 20.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // SYSTOLIC BP VELOCITY THRESHOLDS (mmHg per hour)
  // Note: We're concerned about DROPS in BP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mild SBP drop: 3-5 mmHg/hour
  static const double sbpMildRatePerHour = 3.0;

  /// Moderate SBP drop: 5-8 mmHg/hour
  static const double sbpModerateRatePerHour = 5.0;

  /// Rapid SBP drop: 8-12 mmHg/hour
  static const double sbpRapidRatePerHour = 8.0;

  /// Critical SBP drop: >12 mmHg/hour
  static const double sbpCriticalRatePerHour = 12.0;

  /// Absolute SBP change threshold (over window): 20 mmHg
  static const double sbpConcerningAbsoluteChange = 20.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // RESPIRATORY RATE VELOCITY THRESHOLDS (breaths/min per hour)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mild RR increase: 1-2 breaths/hour
  static const double rrMildRatePerHour = 1.0;

  /// Moderate RR increase: 2-3 breaths/hour
  static const double rrModerateRatePerHour = 2.0;

  /// Rapid RR increase: 3-5 breaths/hour
  static const double rrRapidRatePerHour = 3.0;

  /// Critical RR increase: >5 breaths/hour
  static const double rrCriticalRatePerHour = 5.0;

  /// Absolute RR change threshold (over window): 6 breaths
  static const double rrConcerningAbsoluteChange = 6.0;
}
