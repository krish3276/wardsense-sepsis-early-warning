/// Trend Analysis Engine - Core Innovation of WardSense
///
/// This module analyzes vital sign trends over time to detect early
/// signs of deterioration. Unlike simple threshold alerts, this engine
/// identifies PATTERNS of change that may indicate developing sepsis.
///
/// KEY PRINCIPLES:
/// 1. Explainability: Every alert includes clear reasoning
/// 2. Trend over threshold: A rising HR from 70→95 is more concerning
///    than a stable HR of 100
/// 3. Pattern recognition: Sepsis has characteristic patterns
///    (HR↑, BP↓, RR↑, Temp↑)
/// 4. Works with intermittent data: Designed for 2-4 hour vital intervals

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/risk_level.dart';
import '../../domain/entities/vital_signs.dart';
import '../../domain/entities/alert.dart';
import '../../data/repositories/vital_signs_repository.dart';

/// Provider for the trend analysis engine
final trendAnalysisEngineProvider = Provider<TrendAnalysisEngine>((ref) {
  return TrendAnalysisEngine(ref.read(vitalSignsRepositoryProvider));
});

/// Result of trend analysis for a single vital parameter
class TrendResult {
  final VitalType vitalType;
  final TrendDirection direction;
  final double currentValue;
  final double? previousValue;
  final double? percentageChange;
  final double? rateOfChangePerHour;
  final bool isConcerning;
  final String explanation;

  TrendResult({
    required this.vitalType,
    required this.direction,
    required this.currentValue,
    this.previousValue,
    this.percentageChange,
    this.rateOfChangePerHour,
    required this.isConcerning,
    required this.explanation,
  });
}

/// Complete analysis result for a patient
class PatientAnalysisResult {
  final String patientId;
  final RiskLevel riskLevel;
  final List<TrendResult> trends;
  final int newsScore;
  final bool hasSepsisPattern;
  final String summary;
  final List<String> recommendedActions;
  final DateTime analysisTime;
  final int analysisWindowHours;

  PatientAnalysisResult({
    required this.patientId,
    required this.riskLevel,
    required this.trends,
    required this.newsScore,
    required this.hasSepsisPattern,
    required this.summary,
    required this.recommendedActions,
    required this.analysisTime,
    required this.analysisWindowHours,
  });
}

/// Trend Analysis Engine
///
/// Core algorithm for detecting deterioration patterns in vital signs.
/// Uses a combination of:
/// - Linear regression for trend direction
/// - Rate of change analysis
/// - Pattern matching for sepsis indicators
/// - NEWS score calculation
class TrendAnalysisEngine {
  final VitalSignsRepository _vitalsRepository;
  static const _uuid = Uuid();

  TrendAnalysisEngine(this._vitalsRepository);

  /// Analyze a patient's vital signs and generate risk assessment
  ///
  /// This is the main entry point for trend analysis. It:
  /// 1. Retrieves recent vital signs
  /// 2. Calculates trends for each parameter
  /// 3. Identifies concerning patterns
  /// 4. Generates a risk level and recommendations
  PatientAnalysisResult analyzePatient(String patientId) {
    final vitals = _vitalsRepository.getVitalSignsInWindow(
      patientId,
      AppConstants.trendAnalysisWindowHours,
    );

    if (vitals.isEmpty) {
      return _createNoDataResult(patientId);
    }

    if (vitals.length < AppConstants.minDataPointsForTrend) {
      return _createInsufficientDataResult(patientId, vitals.last);
    }

    // Calculate trends for each vital parameter
    final trends = _calculateAllTrends(vitals);

    // Calculate NEWS score from latest vitals
    final newsScore = _calculateNewsScore(vitals.last);

    // Check for sepsis pattern
    final hasSepsisPattern = _detectSepsisPattern(trends);

    // Determine overall risk level
    final riskLevel = _determineRiskLevel(
      trends: trends,
      newsScore: newsScore,
      hasSepsisPattern: hasSepsisPattern,
    );

    // Generate summary and recommendations
    final summary = _generateSummary(trends, hasSepsisPattern);
    final recommendations = _generateRecommendations(
      riskLevel,
      trends,
      hasSepsisPattern,
    );

    return PatientAnalysisResult(
      patientId: patientId,
      riskLevel: riskLevel,
      trends: trends,
      newsScore: newsScore,
      hasSepsisPattern: hasSepsisPattern,
      summary: summary,
      recommendedActions: recommendations,
      analysisTime: DateTime.now(),
      analysisWindowHours: AppConstants.trendAnalysisWindowHours,
    );
  }

  /// Create an Alert entity from analysis result
  Alert? createAlertFromAnalysis(PatientAnalysisResult result) {
    // Only create alerts for yellow and above
    if (result.riskLevel == RiskLevel.green) {
      return null;
    }

    final factors = result.trends
        .where((t) => t.isConcerning)
        .map(
          (t) => AlertFactor(
            vitalType: t.vitalType,
            direction: t.direction,
            currentValue: t.currentValue,
            previousValue: t.previousValue,
            percentageChange: t.percentageChange,
            rateOfChangePerHour: t.rateOfChangePerHour,
            shortDescription: _createShortDescription(t),
            explanation: t.explanation,
            isCritical: _isCriticalTrend(t),
          ),
        )
        .toList();

    if (factors.isEmpty) {
      return null;
    }

    return Alert(
      id: _uuid.v4(),
      patientId: result.patientId,
      riskLevel: result.riskLevel,
      title: _generateAlertTitle(result),
      description: result.summary,
      factors: factors,
      recommendedActions: result.recommendedActions,
      timestamp: result.analysisTime,
      analysisWindowHours: result.analysisWindowHours,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TREND CALCULATION METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate trends for all vital parameters
  List<TrendResult> _calculateAllTrends(List<VitalSigns> vitals) {
    return [
      _calculateTrend(
        vitals,
        VitalType.heartRate,
        (v) => v.heartRate.toDouble(),
        _isHeartRateConcerning,
      ),
      _calculateTrend(
        vitals,
        VitalType.systolicBP,
        (v) => v.systolicBP.toDouble(),
        _isBPConcerning,
      ),
      _calculateTrend(
        vitals,
        VitalType.respiratoryRate,
        (v) => v.respiratoryRate.toDouble(),
        _isRespRateConcerning,
      ),
      _calculateTrend(
        vitals,
        VitalType.temperature,
        (v) => v.temperature,
        _isTemperatureConcerning,
      ),
      _calculateTrend(
        vitals,
        VitalType.spO2,
        (v) => v.spO2.toDouble(),
        _isSpO2Concerning,
      ),
    ];
  }

  /// Calculate trend for a single vital parameter using linear regression
  TrendResult _calculateTrend(
    List<VitalSigns> vitals,
    VitalType type,
    double Function(VitalSigns) getValue,
    bool Function(double current, double? previous, TrendDirection direction)
        isConcerning,
  ) {
    final values = vitals.map(getValue).toList();
    final first = values.first;
    final last = values.last;

    // Calculate linear regression slope
    final slope = _calculateSlope(vitals, getValue);

    // Determine trend direction
    final direction = _determineDirection(slope, first, last, type);

    // Calculate percentage change
    final percentChange = first != 0 ? ((last - first) / first) * 100 : 0.0;

    // Calculate hours between first and last reading
    final hours =
        vitals.last.timestamp.difference(vitals.first.timestamp).inMinutes / 60;
    final ratePerHour = hours > 0 ? (last - first) / hours : 0.0;

    // Check if concerning
    final concerning = isConcerning(last, first, direction);

    // Generate explanation
    final explanation = _generateExplanation(
      type,
      direction,
      first,
      last,
      hours,
    );

    return TrendResult(
      vitalType: type,
      direction: direction,
      currentValue: last,
      previousValue: first,
      percentageChange: percentChange,
      rateOfChangePerHour: ratePerHour,
      isConcerning: concerning,
      explanation: explanation,
    );
  }

  /// Calculate slope using simple linear regression
  double _calculateSlope(
    List<VitalSigns> vitals,
    double Function(VitalSigns) getValue,
  ) {
    if (vitals.length < 2) return 0;

    final n = vitals.length;
    final startTime = vitals.first.timestamp.millisecondsSinceEpoch.toDouble();

    // Convert timestamps to hours from start
    final times = vitals
        .map(
          (v) =>
              (v.timestamp.millisecondsSinceEpoch - startTime) /
              (1000 * 60 * 60),
        )
        .toList();

    final values = vitals.map(getValue).toList();

    // Calculate means
    final meanX = times.reduce((a, b) => a + b) / n;
    final meanY = values.reduce((a, b) => a + b) / n;

    // Calculate slope: Σ(xi - x̄)(yi - ȳ) / Σ(xi - x̄)²
    double numerator = 0;
    double denominator = 0;

    for (int i = 0; i < n; i++) {
      final xDiff = times[i] - meanX;
      final yDiff = values[i] - meanY;
      numerator += xDiff * yDiff;
      denominator += xDiff * xDiff;
    }

    return denominator != 0 ? numerator / denominator : 0;
  }

  /// Determine trend direction from slope and values
  TrendDirection _determineDirection(
    double slope,
    double first,
    double last,
    VitalType type,
  ) {
    // Use type-specific thresholds
    final threshold = _getSignificanceThreshold(type);
    final percentChange =
        first != 0 ? ((last - first) / first).abs() * 100 : 0.0;

    if (percentChange < threshold) {
      return TrendDirection.stable;
    }

    if (slope > 0) {
      return TrendDirection.rising;
    } else if (slope < 0) {
      return TrendDirection.falling;
    }

    return TrendDirection.stable;
  }

  /// Get significance threshold for each vital type
  double _getSignificanceThreshold(VitalType type) {
    switch (type) {
      case VitalType.heartRate:
        return 10.0; // 10% change is significant
      case VitalType.systolicBP:
      case VitalType.diastolicBP:
        return 10.0;
      case VitalType.respiratoryRate:
        return 15.0;
      case VitalType.temperature:
        return 2.0; // 2% of 37°C ≈ 0.7°C
      case VitalType.spO2:
        return 3.0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONCERNING PATTERN DETECTION
  // ═══════════════════════════════════════════════════════════════════════════

  bool _isHeartRateConcerning(
    double current,
    double? previous,
    TrendDirection direction,
  ) {
    // Tachycardia or rapid increase
    if (current > AppConstants.hrMildHigh) return true;
    if (direction == TrendDirection.rising && previous != null) {
      final change = current - previous;
      if (change > 20) return true;
    }
    return false;
  }

  bool _isBPConcerning(
    double current,
    double? previous,
    TrendDirection direction,
  ) {
    // Hypotension or rapid decrease
    if (current < AppConstants.sbpModerateLow) return true;
    if (direction == TrendDirection.falling && previous != null) {
      final change = previous - current;
      if (change > 20) return true;
    }
    return false;
  }

  bool _isRespRateConcerning(
    double current,
    double? previous,
    TrendDirection direction,
  ) {
    // Tachypnea
    if (current > AppConstants.rrSevereHigh) return true;
    if (direction == TrendDirection.rising &&
        current > AppConstants.rrNormalHigh) {
      return true;
    }
    return false;
  }

  bool _isTemperatureConcerning(
    double current,
    double? previous,
    TrendDirection direction,
  ) {
    // Fever or hypothermia
    if (current >= AppConstants.tempFever) return true;
    if (current <= AppConstants.tempHypothermia) return true;
    if (direction == TrendDirection.rising &&
        current > AppConstants.tempNormalHigh) {
      return true;
    }
    return false;
  }

  bool _isSpO2Concerning(
    double current,
    double? previous,
    TrendDirection direction,
  ) {
    // Hypoxia
    if (current < AppConstants.spo2ModerateLow) return true;
    if (direction == TrendDirection.falling &&
        current < AppConstants.spo2Normal) {
      return true;
    }
    return false;
  }

  /// Detect classic sepsis deterioration pattern
  ///
  /// Sepsis typically shows:
  /// - Rising heart rate (tachycardia)
  /// - Falling blood pressure (hypotension)
  /// - Rising respiratory rate (tachypnea)
  /// - Elevated temperature (fever) or hypothermia
  bool _detectSepsisPattern(List<TrendResult> trends) {
    bool hrRising = false;
    bool bpFalling = false;
    bool rrRising = false;
    bool tempAbnormal = false;

    for (final trend in trends) {
      switch (trend.vitalType) {
        case VitalType.heartRate:
          hrRising =
              trend.direction == TrendDirection.rising && trend.isConcerning;
          break;
        case VitalType.systolicBP:
          bpFalling =
              trend.direction == TrendDirection.falling && trend.isConcerning;
          break;
        case VitalType.respiratoryRate:
          rrRising =
              trend.direction == TrendDirection.rising && trend.isConcerning;
          break;
        case VitalType.temperature:
          tempAbnormal = trend.isConcerning;
          break;
        default:
          break;
      }
    }

    // Sepsis pattern requires at least 3 of the 4 indicators
    int indicators = 0;
    if (hrRising) indicators++;
    if (bpFalling) indicators++;
    if (rrRising) indicators++;
    if (tempAbnormal) indicators++;

    return indicators >= 3;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEWS SCORE CALCULATION
  // Based on Royal College of Physicians NEWS2 guidelines
  // ═══════════════════════════════════════════════════════════════════════════

  /// Public static method to calculate NEWS score for a VitalSigns entry.
  /// This can be used when saving new vital signs to include the NEWS score.
  ///
  /// Returns an integer score from 0-20 based on NEWS2 guidelines:
  /// - 0-4: Low risk
  /// - 5-6: Medium risk (or 3 in any single parameter)
  /// - 7+: High risk
  static int calculateNewsScore(VitalSigns vitals) {
    int score = 0;

    // Respiratory rate scoring
    if (vitals.respiratoryRate <= 8) {
      score += 3;
    } else if (vitals.respiratoryRate <= 11) {
      score += 1;
    } else if (vitals.respiratoryRate <= 20) {
      score += 0;
    } else if (vitals.respiratoryRate <= 24) {
      score += 2;
    } else {
      score += 3;
    }

    // SpO2 scoring (Scale 1 - assuming no supplemental O2)
    if (vitals.spO2 <= 91) {
      score += 3;
    } else if (vitals.spO2 <= 93) {
      score += 2;
    } else if (vitals.spO2 <= 95) {
      score += 1;
    } else {
      score += 0;
    }

    // Systolic BP scoring
    if (vitals.systolicBP <= 90) {
      score += 3;
    } else if (vitals.systolicBP <= 100) {
      score += 2;
    } else if (vitals.systolicBP <= 110) {
      score += 1;
    } else if (vitals.systolicBP <= 219) {
      score += 0;
    } else {
      score += 3;
    }

    // Heart rate scoring
    if (vitals.heartRate <= 40) {
      score += 3;
    } else if (vitals.heartRate <= 50) {
      score += 1;
    } else if (vitals.heartRate <= 90) {
      score += 0;
    } else if (vitals.heartRate <= 110) {
      score += 1;
    } else if (vitals.heartRate <= 130) {
      score += 2;
    } else {
      score += 3;
    }

    // Temperature scoring
    if (vitals.temperature <= 35.0) {
      score += 3;
    } else if (vitals.temperature <= 36.0) {
      score += 1;
    } else if (vitals.temperature <= 38.0) {
      score += 0;
    } else if (vitals.temperature <= 39.0) {
      score += 1;
    } else {
      score += 2;
    }

    return score;
  }

  /// Private instance method that delegates to the static method
  int _calculateNewsScore(VitalSigns vitals) {
    return TrendAnalysisEngine.calculateNewsScore(vitals);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RISK LEVEL DETERMINATION
  // ═══════════════════════════════════════════════════════════════════════════

  RiskLevel _determineRiskLevel({
    required List<TrendResult> trends,
    required int newsScore,
    required bool hasSepsisPattern,
  }) {
    // RED: Sepsis pattern or NEWS >= 7 or any single score of 3
    if (hasSepsisPattern) return RiskLevel.red;
    if (newsScore >= AppConstants.newsHighRiskMin) return RiskLevel.red;

    // Check for critical individual trends
    final criticalTrends = trends.where((t) => _isCriticalTrend(t)).toList();
    if (criticalTrends.isNotEmpty) return RiskLevel.red;

    // ORANGE: NEWS 5-6 or multiple concerning trends
    if (newsScore > AppConstants.newsLowRiskMax) return RiskLevel.orange;

    final concerningTrends = trends.where((t) => t.isConcerning).toList();
    if (concerningTrends.length >= 2) return RiskLevel.orange;

    // YELLOW: NEWS 1-4 or single concerning trend
    if (newsScore > 0 || concerningTrends.isNotEmpty) return RiskLevel.yellow;

    // GREEN: All stable
    return RiskLevel.green;
  }

  bool _isCriticalTrend(TrendResult trend) {
    switch (trend.vitalType) {
      case VitalType.heartRate:
        return trend.currentValue > 130 || trend.currentValue < 40;
      case VitalType.systolicBP:
        return trend.currentValue < 90;
      case VitalType.respiratoryRate:
        return trend.currentValue > 25 || trend.currentValue < 8;
      case VitalType.temperature:
        return trend.currentValue > 39.5 || trend.currentValue < 35.0;
      case VitalType.spO2:
        return trend.currentValue < 92;
      default:
        return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  String _generateExplanation(
    VitalType type,
    TrendDirection direction,
    double first,
    double last,
    double hours,
  ) {
    final name = type.displayName;
    final unit = type.unit;
    final arrow = direction.arrow;
    final hoursStr = hours.toStringAsFixed(1);

    if (direction == TrendDirection.stable) {
      return '$name stable at ${last.toStringAsFixed(type == VitalType.temperature ? 1 : 0)} $unit';
    }

    return '$name $arrow from ${first.toStringAsFixed(type == VitalType.temperature ? 1 : 0)} to ${last.toStringAsFixed(type == VitalType.temperature ? 1 : 0)} $unit over $hoursStr hours';
  }

  String _createShortDescription(TrendResult trend) {
    final name = trend.vitalType.shortName;
    final arrow = trend.direction.arrow;

    if (trend.percentageChange != null && trend.percentageChange!.abs() > 5) {
      return '$name $arrow ${trend.percentageChange!.abs().toStringAsFixed(0)}%';
    }

    return '$name $arrow ${trend.currentValue.toStringAsFixed(trend.vitalType == VitalType.temperature ? 1 : 0)}';
  }

  String _generateSummary(List<TrendResult> trends, bool hasSepsisPattern) {
    final concerning = trends.where((t) => t.isConcerning).toList();

    if (hasSepsisPattern) {
      return 'Patient shows classic sepsis deterioration pattern with multiple vital sign abnormalities. Immediate attention required.';
    }

    if (concerning.isEmpty) {
      return 'All vital signs within normal ranges and stable trends.';
    }

    if (concerning.length == 1) {
      return '${concerning.first.explanation}. Continue monitoring.';
    }

    final descriptions =
        concerning.map((t) => t.vitalType.displayName).join(', ');
    return 'Multiple vital signs showing concerning trends: $descriptions. Close monitoring advised.';
  }

  List<String> _generateRecommendations(
    RiskLevel level,
    List<TrendResult> trends,
    bool hasSepsisPattern,
  ) {
    final recommendations = <String>[];

    switch (level) {
      case RiskLevel.green:
        recommendations.add('Continue routine monitoring every 4-6 hours');
        break;

      case RiskLevel.yellow:
        recommendations.add('Increase monitoring frequency to every 1-2 hours');
        recommendations.add('Inform nurse in charge of trend changes');
        recommendations.add('Review fluid balance and recent interventions');
        break;

      case RiskLevel.orange:
        recommendations.add('Repeat vital signs in 15-30 minutes to confirm');
        recommendations.add('Notify duty doctor for clinical assessment');
        recommendations.add('Prepare for potential escalation');
        recommendations.add('Review recent medications and interventions');
        break;

      case RiskLevel.red:
        if (hasSepsisPattern) {
          recommendations.add('Activate sepsis protocol immediately');
          recommendations.add('Obtain IV access if not already present');
          recommendations.add('Prepare for blood cultures and lactate');
        }
        recommendations.add('Call rapid response / medical emergency team');
        recommendations.add('Ensure senior medical review within 30 minutes');
        recommendations.add('Continue close monitoring every 15 minutes');
        break;
    }

    return recommendations;
  }

  String _generateAlertTitle(PatientAnalysisResult result) {
    if (result.hasSepsisPattern) {
      return 'High Risk: Possible Sepsis Pattern Detected';
    }

    final concerningTrends =
        result.trends.where((t) => t.isConcerning).toList();

    if (concerningTrends.isEmpty) {
      return 'Vital Signs Alert';
    }

    if (concerningTrends.length == 1) {
      final trend = concerningTrends.first;
      final action =
          trend.direction == TrendDirection.rising ? 'Rising' : 'Falling';
      return '$action ${trend.vitalType.displayName} Detected';
    }

    return 'Multiple Vital Sign Trends Detected';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER RESULTS FOR EDGE CASES
  // ═══════════════════════════════════════════════════════════════════════════

  PatientAnalysisResult _createNoDataResult(String patientId) {
    return PatientAnalysisResult(
      patientId: patientId,
      riskLevel: RiskLevel.yellow, // Unknown is concerning
      trends: [],
      newsScore: 0,
      hasSepsisPattern: false,
      summary:
          'No vital signs recorded. Please enter vital signs for this patient.',
      recommendedActions: ['Record vital signs immediately'],
      analysisTime: DateTime.now(),
      analysisWindowHours: AppConstants.trendAnalysisWindowHours,
    );
  }

  PatientAnalysisResult _createInsufficientDataResult(
    String patientId,
    VitalSigns latest,
  ) {
    return PatientAnalysisResult(
      patientId: patientId,
      riskLevel: _determineRiskLevelFromSingleReading(latest),
      trends: [],
      newsScore: _calculateNewsScore(latest),
      hasSepsisPattern: false,
      summary:
          'Insufficient data for trend analysis. Need at least ${AppConstants.minDataPointsForTrend} readings.',
      recommendedActions: [
        'Continue recording vital signs',
        'Trend analysis will be available after more readings',
      ],
      analysisTime: DateTime.now(),
      analysisWindowHours: AppConstants.trendAnalysisWindowHours,
    );
  }

  RiskLevel _determineRiskLevelFromSingleReading(VitalSigns vitals) {
    final newsScore = _calculateNewsScore(vitals);

    if (newsScore >= AppConstants.newsHighRiskMin) return RiskLevel.red;
    if (newsScore > AppConstants.newsLowRiskMax) return RiskLevel.orange;
    if (newsScore > 0) return RiskLevel.yellow;

    return RiskLevel.green;
  }
}
