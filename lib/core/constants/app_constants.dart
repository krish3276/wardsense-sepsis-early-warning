/// Application-wide constants for WardSense
///
/// Centralized configuration values for easy maintenance and consistency.
/// All clinical thresholds are based on NEWS (National Early Warning Score)
/// and qSOFA (Quick Sequential Organ Failure Assessment) guidelines.

class AppConstants {
  AppConstants._();

  // ═══════════════════════════════════════════════════════════════════════════
  // APP METADATA
  // ═══════════════════════════════════════════════════════════════════════════

  static const String appName = 'WardSense';
  static const String appTagline = 'Early Sepsis Deterioration Assistant';
  static const String appVersion = '1.0.0';

  // ═══════════════════════════════════════════════════════════════════════════
  // HIVE BOX NAMES (Local Storage)
  // ═══════════════════════════════════════════════════════════════════════════

  static const String patientsBox = 'patients_box';
  static const String vitalsBox = 'vitals_box';
  static const String alertsBox = 'alerts_box';
  static const String escalationsBox = 'escalations_box';
  static const String settingsBox = 'settings_box';

  // ═══════════════════════════════════════════════════════════════════════════
  // CLINICAL THRESHOLDS
  // Based on NEWS (National Early Warning Score) parameters
  // These are validated clinical values - DO NOT modify without clinical review
  // ═══════════════════════════════════════════════════════════════════════════

  // Heart Rate (bpm) - Normal: 51-90
  static const int hrMin = 30;
  static const int hrMax = 250;
  static const int hrNormalLow = 51;
  static const int hrNormalHigh = 90;
  static const int hrMildLow = 41;
  static const int hrMildHigh = 110;
  static const int hrModerateLow = 40;
  static const int hrModerateHigh = 130;

  // Systolic Blood Pressure (mmHg) - Normal: 111-219
  static const int sbpMin = 50;
  static const int sbpMax = 300;
  static const int sbpNormalLow = 111;
  static const int sbpNormalHigh = 219;
  static const int sbpMildLow = 101;
  static const int sbpModerateLow = 91;
  static const int sbpSevereLow = 90; // qSOFA threshold

  // Diastolic Blood Pressure (mmHg)
  static const int dbpMin = 30;
  static const int dbpMax = 200;
  static const int dbpNormalLow = 60;
  static const int dbpNormalHigh = 90;

  // Respiratory Rate (breaths/min) - Normal: 12-20
  static const int rrMin = 4;
  static const int rrMax = 60;
  static const int rrNormalLow = 12;
  static const int rrNormalHigh = 20;
  static const int rrMildHigh = 24;
  static const int rrSevereHigh = 22; // qSOFA threshold

  // Temperature (°C) - Normal: 36.1-38.0
  static const double tempMin = 32.0;
  static const double tempMax = 43.0;
  static const double tempNormalLow = 36.1;
  static const double tempNormalHigh = 38.0;
  static const double tempMildLow = 35.1;
  static const double tempMildHigh = 39.0;
  static const double tempHypothermia = 35.0;
  static const double tempFever = 38.3; // Sepsis indicator

  // SpO2 (%) - Normal: 96-100
  static const int spo2Min = 50;
  static const int spo2Max = 100;
  static const int spo2Normal = 96;
  static const int spo2MildLow = 94;
  static const int spo2ModerateLow = 92;
  static const int spo2SevereLow = 88;

  // ═══════════════════════════════════════════════════════════════════════════
  // TREND ANALYSIS CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Minimum number of data points required for trend analysis
  static const int minDataPointsForTrend = 3;

  /// Maximum time window for trend analysis (hours)
  static const int trendAnalysisWindowHours = 12;

  /// Optimal time window for trend analysis (hours)
  static const int optimalTrendWindowHours = 6;

  /// Minimum change percentage to consider as significant trend
  static const double significantTrendThreshold = 10.0;

  /// Rate of change thresholds (per hour)
  static const double rapidHrChangePerHour = 15.0;
  static const double rapidBpChangePerHour = 20.0;
  static const double rapidRrChangePerHour = 5.0;
  static const double rapidTempChangePerHour = 0.5;
  static const double rapidSpo2ChangePerHour = 3.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // NEWS SCORE THRESHOLDS
  // ═══════════════════════════════════════════════════════════════════════════

  /// NEWS score thresholds for risk levels
  static const int newsLowRiskMax = 4;
  static const int newsMediumRiskMax = 6;
  static const int newsHighRiskMin = 7;

  // ═══════════════════════════════════════════════════════════════════════════
  // UI CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  /// Refresh intervals
  static const Duration dashboardRefreshInterval = Duration(minutes: 1);
  static const Duration alertCheckInterval = Duration(seconds: 30);

  // ═══════════════════════════════════════════════════════════════════════════
  // ESCALATION TIMING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Time thresholds for escalation reminders (minutes)
  static const int yellowAlertReminderMinutes = 30;
  static const int orangeAlertReminderMinutes = 15;
  static const int redAlertReminderMinutes = 5;
}
