/// Risk level enumeration for patient deterioration status
///
/// Based on NEWS (National Early Warning Score) with clinical color coding.
/// Each level has associated actions that guide clinical response.

import 'package:flutter/material.dart';

/// Risk levels for patient deterioration assessment
///
/// The levels follow a traffic-light system extended with orange
/// for a more nuanced clinical response:
/// - Green: Patient stable, routine monitoring
/// - Yellow: Close monitoring required, increased vigilance
/// - Orange: Doctor notification needed, potential deterioration
/// - Red: Immediate escalation, high risk of sepsis/deterioration
enum RiskLevel {
  /// Stable patient - continue routine monitoring
  /// NEWS Score: 0-4 (Low risk)
  green,

  /// Monitor closely - increased observation frequency
  /// NEWS Score: 5-6 or single parameter score of 3
  yellow,

  /// Notify doctor - urgent response needed
  /// NEWS Score: 7+ or rapid deterioration trend
  orange,

  /// High risk - immediate escalation required
  /// Sepsis suspected or critical vital sign combination
  red,
}

/// Extension methods for RiskLevel to provide UI and clinical properties
extension RiskLevelExtension on RiskLevel {
  /// Display name for the risk level
  String get displayName {
    switch (this) {
      case RiskLevel.green:
        return 'Stable';
      case RiskLevel.yellow:
        return 'Monitor Closely';
      case RiskLevel.orange:
        return 'Notify Doctor';
      case RiskLevel.red:
        return 'Escalate Immediately';
    }
  }

  /// Short label for compact UI elements
  String get shortLabel {
    switch (this) {
      case RiskLevel.green:
        return 'Stable';
      case RiskLevel.yellow:
        return 'Watch';
      case RiskLevel.orange:
        return 'Alert';
      case RiskLevel.red:
        return 'Critical';
    }
  }

  /// Primary color for the risk level (light theme)
  Color get color {
    switch (this) {
      case RiskLevel.green:
        return const Color(0xFF2E7D32); // Green 800
      case RiskLevel.yellow:
        return const Color(0xFFF9A825); // Yellow 800
      case RiskLevel.orange:
        return const Color(0xFFEF6C00); // Orange 800
      case RiskLevel.red:
        return const Color(0xFFC62828); // Red 800
    }
  }

  /// Background color for cards and containers
  Color get backgroundColor {
    switch (this) {
      case RiskLevel.green:
        return const Color(0xFFE8F5E9); // Green 50
      case RiskLevel.yellow:
        return const Color(0xFFFFF8E1); // Amber 50
      case RiskLevel.orange:
        return const Color(0xFFFFF3E0); // Orange 50
      case RiskLevel.red:
        return const Color(0xFFFFEBEE); // Red 50
    }
  }

  /// Dark mode background color
  Color get darkBackgroundColor {
    switch (this) {
      case RiskLevel.green:
        return const Color(0xFF1B5E20).withOpacity(0.3);
      case RiskLevel.yellow:
        return const Color(0xFFF57F17).withOpacity(0.3);
      case RiskLevel.orange:
        return const Color(0xFFE65100).withOpacity(0.3);
      case RiskLevel.red:
        return const Color(0xFFB71C1C).withOpacity(0.3);
    }
  }

  /// Icon for the risk level
  IconData get icon {
    switch (this) {
      case RiskLevel.green:
        return Icons.check_circle_outline;
      case RiskLevel.yellow:
        return Icons.visibility_outlined;
      case RiskLevel.orange:
        return Icons.notification_important_outlined;
      case RiskLevel.red:
        return Icons.warning_amber_rounded;
    }
  }

  /// Numeric priority (higher = more urgent)
  int get priority {
    switch (this) {
      case RiskLevel.green:
        return 0;
      case RiskLevel.yellow:
        return 1;
      case RiskLevel.orange:
        return 2;
      case RiskLevel.red:
        return 3;
    }
  }

  /// Recommended monitoring frequency in minutes
  int get monitoringIntervalMinutes {
    switch (this) {
      case RiskLevel.green:
        return 240; // 4 hours
      case RiskLevel.yellow:
        return 60; // 1 hour
      case RiskLevel.orange:
        return 30; // 30 minutes
      case RiskLevel.red:
        return 15; // 15 minutes (continuous if possible)
    }
  }

  /// Clinical action required at this risk level
  String get clinicalAction {
    switch (this) {
      case RiskLevel.green:
        return 'Continue routine monitoring every 4-6 hours';
      case RiskLevel.yellow:
        return 'Increase monitoring frequency to hourly. Inform nurse-in-charge.';
      case RiskLevel.orange:
        return 'Notify duty doctor immediately. Prepare for potential escalation.';
      case RiskLevel.red:
        return 'Activate sepsis protocol. Immediate senior review required.';
    }
  }
}
