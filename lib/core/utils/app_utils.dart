/// Utility functions for formatting and display in WardSense
///
/// Provides consistent formatting for dates, times, vital signs,
/// and clinical values throughout the application.

import 'package:intl/intl.dart';

class AppUtils {
  AppUtils._();

  // ═══════════════════════════════════════════════════════════════════════════
  // DATE & TIME FORMATTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Format date as "Jan 12, 2026"
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Format time as "14:30" (24-hour format for clinical settings)
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Format datetime as "Jan 12, 14:30"
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, HH:mm').format(date);
  }

  /// Format datetime as "Jan 12, 2026 at 14:30"
  static String formatDateTimeFull(DateTime date) {
    return DateFormat('MMM d, yyyy \'at\' HH:mm').format(date);
  }

  /// Format relative time (e.g., "5 min ago", "2 hours ago")
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins min${mins == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else {
      return formatDate(date);
    }
  }

  /// Format duration (e.g., "2h 30m")
  static String formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    } else if (duration.inHours < 24) {
      final hours = duration.inHours;
      final mins = duration.inMinutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    } else {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VITAL SIGN FORMATTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Format heart rate with unit
  static String formatHeartRate(int hr) => '$hr bpm';

  /// Format blood pressure
  static String formatBloodPressure(int systolic, int diastolic) {
    return '$systolic/$diastolic mmHg';
  }

  /// Format respiratory rate with unit
  static String formatRespiratoryRate(int rr) => '$rr /min';

  /// Format temperature with unit
  static String formatTemperature(double temp) =>
      '${temp.toStringAsFixed(1)}°C';

  /// Format SpO2 with unit
  static String formatSpO2(int spo2) => '$spo2%';

  // ═══════════════════════════════════════════════════════════════════════════
  // TREND FORMATTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get trend arrow based on direction
  /// Returns appropriate arrow character for trend direction
  static String getTrendArrow(TrendDirection direction) {
    switch (direction) {
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

  /// Format percentage change with sign
  static String formatPercentageChange(double change) {
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}%';
  }

  /// Format rate of change per hour
  static String formatRateOfChange(double rate, String unit) {
    final sign = rate >= 0 ? '+' : '';
    return '$sign${rate.toStringAsFixed(1)} $unit/hr';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PATIENT ID FORMATTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Format bed ID for display (e.g., "Bed 5A")
  static String formatBedId(String bedId) {
    if (bedId.toLowerCase().startsWith('bed')) {
      return bedId;
    }
    return 'Bed $bedId';
  }

  /// Format patient ID for display
  static String formatPatientId(String patientId) {
    if (patientId.length > 8) {
      return '${patientId.substring(0, 8)}...';
    }
    return patientId;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDATION HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if a string is a valid integer within range
  static bool isValidIntInRange(String? value, int min, int max) {
    if (value == null || value.isEmpty) return false;
    final parsed = int.tryParse(value);
    if (parsed == null) return false;
    return parsed >= min && parsed <= max;
  }

  /// Check if a string is a valid double within range
  static bool isValidDoubleInRange(String? value, double min, double max) {
    if (value == null || value.isEmpty) return false;
    final parsed = double.tryParse(value);
    if (parsed == null) return false;
    return parsed >= min && parsed <= max;
  }
}

/// Direction of trend for a vital sign
enum TrendDirection { rising, falling, stable, unknown }

/// Extension for TrendDirection
extension TrendDirectionExtension on TrendDirection {
  bool get isConcerning {
    // For most vitals, rising or falling beyond normal is concerning
    return this != TrendDirection.stable && this != TrendDirection.unknown;
  }
}
