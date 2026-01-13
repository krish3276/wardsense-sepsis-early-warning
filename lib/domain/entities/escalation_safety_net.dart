/// Escalation Safety Net entity
///
/// Implements the "Missed-Escalation Safety Net" - a critical patient safety
/// feature that detects when alerts have not been acknowledged or actioned
/// within appropriate timeframes.
///
/// CORE PRINCIPLE:
/// "Sepsis mortality is not due to lack of data — it's due to delayed action."
///
/// This safety net ensures that flagged patients don't "fall through the cracks"
/// during busy ward shifts.

import 'package:equatable/equatable.dart';
import '../../core/constants/risk_level.dart';

/// Status of escalation tracking
enum EscalationTrackingStatus {
  /// Newly flagged, timer started
  pending,

  /// Alert has been acknowledged
  acknowledged,

  /// Action has been documented
  actionTaken,

  /// Timer exceeded without acknowledgment
  overdue,

  /// Patient condition resolved
  resolved,

  /// Manually dismissed (with reason)
  dismissed,
}

extension EscalationTrackingStatusExtension on EscalationTrackingStatus {
  String get displayName {
    switch (this) {
      case EscalationTrackingStatus.pending:
        return 'Awaiting Review';
      case EscalationTrackingStatus.acknowledged:
        return 'Acknowledged';
      case EscalationTrackingStatus.actionTaken:
        return 'Action Taken';
      case EscalationTrackingStatus.overdue:
        return 'Overdue';
      case EscalationTrackingStatus.resolved:
        return 'Resolved';
      case EscalationTrackingStatus.dismissed:
        return 'Dismissed';
    }
  }

  bool get requiresAttention =>
      this == EscalationTrackingStatus.pending ||
      this == EscalationTrackingStatus.overdue;

  bool get isOverdue => this == EscalationTrackingStatus.overdue;

  bool get isActive =>
      this == EscalationTrackingStatus.pending ||
      this == EscalationTrackingStatus.overdue;
}

/// Configuration for escalation timing
///
/// Different risk levels have different expected response times.
class EscalationTimeConfig {
  /// Risk level this config applies to
  final RiskLevel riskLevel;

  /// Maximum time allowed before first acknowledgment (minutes)
  final int maxAcknowledgmentMinutes;

  /// Maximum time allowed for documented action (minutes)
  final int maxActionMinutes;

  /// Reminder interval after first deadline (minutes)
  final int reminderIntervalMinutes;

  const EscalationTimeConfig({
    required this.riskLevel,
    required this.maxAcknowledgmentMinutes,
    required this.maxActionMinutes,
    required this.reminderIntervalMinutes,
  });

  Duration get acknowledgmentDeadline =>
      Duration(minutes: maxAcknowledgmentMinutes);

  Duration get actionDeadline => Duration(minutes: maxActionMinutes);

  Duration get reminderInterval => Duration(minutes: reminderIntervalMinutes);
}

/// Default escalation time configurations by risk level
class DefaultEscalationTimings {
  DefaultEscalationTimings._();

  /// Red (Critical): 15 min acknowledgment, 30 min action
  static const EscalationTimeConfig red = EscalationTimeConfig(
    riskLevel: RiskLevel.red,
    maxAcknowledgmentMinutes: 15,
    maxActionMinutes: 30,
    reminderIntervalMinutes: 10,
  );

  /// Orange (Alert): 30 min acknowledgment, 60 min action
  static const EscalationTimeConfig orange = EscalationTimeConfig(
    riskLevel: RiskLevel.orange,
    maxAcknowledgmentMinutes: 30,
    maxActionMinutes: 60,
    reminderIntervalMinutes: 15,
  );

  /// Yellow (Watch): 60 min acknowledgment, 120 min action
  static const EscalationTimeConfig yellow = EscalationTimeConfig(
    riskLevel: RiskLevel.yellow,
    maxAcknowledgmentMinutes: 60,
    maxActionMinutes: 120,
    reminderIntervalMinutes: 30,
  );

  /// Get config for a specific risk level
  static EscalationTimeConfig getConfig(RiskLevel level) {
    switch (level) {
      case RiskLevel.red:
        return red;
      case RiskLevel.orange:
        return orange;
      case RiskLevel.yellow:
        return yellow;
      case RiskLevel.green:
        // Green doesn't require escalation tracking
        return yellow; // Fallback
    }
  }
}

/// Escalation tracking record for a patient alert
class EscalationTracker extends Equatable {
  /// Unique identifier
  final String id;

  /// Patient ID reference
  final String patientId;

  /// Alert ID that triggered this tracker
  final String alertId;

  /// Risk level when tracker was created
  final RiskLevel initialRiskLevel;

  /// Current tracking status
  final EscalationTrackingStatus status;

  /// When the tracker was started
  final DateTime startedAt;

  /// Deadline for acknowledgment
  final DateTime acknowledgmentDeadline;

  /// Deadline for action
  final DateTime actionDeadline;

  /// When acknowledged (if applicable)
  final DateTime? acknowledgedAt;

  /// Who acknowledged
  final String? acknowledgedBy;

  /// When action was taken (if applicable)
  final DateTime? actionTakenAt;

  /// Who took action
  final String? actionTakenBy;

  /// Description of action taken
  final String? actionDescription;

  /// When the tracker became overdue
  final DateTime? overdueAt;

  /// Number of reminders sent
  final int reminderCount;

  /// Last reminder timestamp
  final DateTime? lastReminderAt;

  /// Resolution notes
  final String? resolutionNotes;

  /// Whether tracker is active
  final bool isActive;

  const EscalationTracker({
    required this.id,
    required this.patientId,
    required this.alertId,
    required this.initialRiskLevel,
    required this.status,
    required this.startedAt,
    required this.acknowledgmentDeadline,
    required this.actionDeadline,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.actionTakenAt,
    this.actionTakenBy,
    this.actionDescription,
    this.overdueAt,
    this.reminderCount = 0,
    this.lastReminderAt,
    this.resolutionNotes,
    this.isActive = true,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Time since tracker started
  Duration get timeSinceStart => DateTime.now().difference(startedAt);

  /// Time until acknowledgment deadline
  Duration get timeUntilAcknowledgmentDeadline =>
      acknowledgmentDeadline.difference(DateTime.now());

  /// Time until action deadline
  Duration get timeUntilActionDeadline =>
      actionDeadline.difference(DateTime.now());

  /// Whether acknowledgment deadline has passed
  bool get isAcknowledgmentOverdue =>
      acknowledgedAt == null && DateTime.now().isAfter(acknowledgmentDeadline);

  /// Whether action deadline has passed
  bool get isActionOverdue =>
      actionTakenAt == null && DateTime.now().isAfter(actionDeadline);

  /// Whether any deadline has been exceeded
  bool get isOverdue => isAcknowledgmentOverdue || isActionOverdue;

  /// Minutes since alert started (for display)
  int get minutesSinceStart => timeSinceStart.inMinutes;

  /// How many minutes overdue (0 if not overdue)
  int get minutesOverdue {
    if (!isOverdue) return 0;
    if (acknowledgedAt == null) {
      return DateTime.now().difference(acknowledgmentDeadline).inMinutes;
    }
    return DateTime.now().difference(actionDeadline).inMinutes;
  }

  /// Human-readable time since start
  String get timeSinceStartDisplay {
    final mins = minutesSinceStart;
    if (mins < 60) {
      return '$mins min';
    } else if (mins < 1440) {
      final hours = mins ~/ 60;
      final remainingMins = mins % 60;
      return '${hours}h ${remainingMins}m';
    }
    return '${mins ~/ 1440}d';
  }

  /// Human-readable overdue message
  String get overdueMessage {
    if (!isOverdue) return '';

    final mins = minutesOverdue;
    if (acknowledgedAt == null) {
      return 'Unacknowledged for $mins minutes beyond deadline';
    }
    return 'No documented action for $mins minutes beyond deadline';
  }

  /// Recommended next step based on current status
  String get recommendedNextStep {
    switch (status) {
      case EscalationTrackingStatus.pending:
        return isAcknowledgmentOverdue
            ? 'Acknowledge alert and document review immediately'
            : 'Review patient and acknowledge alert';
      case EscalationTrackingStatus.acknowledged:
        return isActionOverdue
            ? 'Document clinical action taken immediately'
            : 'Complete clinical assessment and document action';
      case EscalationTrackingStatus.overdue:
        return 'This patient requires immediate attention — '
            'deterioration flagged without documented response';
      case EscalationTrackingStatus.actionTaken:
        return 'Continue monitoring as per documented plan';
      case EscalationTrackingStatus.resolved:
        return 'Patient condition resolved — routine monitoring';
      case EscalationTrackingStatus.dismissed:
        return 'Tracker dismissed — see notes for rationale';
    }
  }

  /// Severity message for safety net display
  String get safetyNetMessage {
    if (status == EscalationTrackingStatus.overdue) {
      return 'UNACKNOWLEDGED DETERIORATION\n'
          'Patient flagged ${timeSinceStartDisplay} ago as ${initialRiskLevel.displayName}.\n'
          'No documented response recorded.';
    }
    if (isAcknowledgmentOverdue) {
      return 'Alert pending acknowledgment for ${timeSinceStartDisplay}. '
          'Recommended deadline was ${DefaultEscalationTimings.getConfig(initialRiskLevel).maxAcknowledgmentMinutes} minutes.';
    }
    if (isActionOverdue) {
      return 'Alert acknowledged but no action documented for '
          '${DateTime.now().difference(acknowledgedAt!).inMinutes} minutes.';
    }
    return '';
  }

  @override
  List<Object?> get props => [
        id,
        patientId,
        alertId,
        status,
        startedAt,
        acknowledgedAt,
        actionTakenAt,
        isActive,
      ];

  EscalationTracker copyWith({
    String? id,
    String? patientId,
    String? alertId,
    RiskLevel? initialRiskLevel,
    EscalationTrackingStatus? status,
    DateTime? startedAt,
    DateTime? acknowledgmentDeadline,
    DateTime? actionDeadline,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    DateTime? actionTakenAt,
    String? actionTakenBy,
    String? actionDescription,
    DateTime? overdueAt,
    int? reminderCount,
    DateTime? lastReminderAt,
    String? resolutionNotes,
    bool? isActive,
  }) {
    return EscalationTracker(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      alertId: alertId ?? this.alertId,
      initialRiskLevel: initialRiskLevel ?? this.initialRiskLevel,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      acknowledgmentDeadline:
          acknowledgmentDeadline ?? this.acknowledgmentDeadline,
      actionDeadline: actionDeadline ?? this.actionDeadline,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      actionTakenAt: actionTakenAt ?? this.actionTakenAt,
      actionTakenBy: actionTakenBy ?? this.actionTakenBy,
      actionDescription: actionDescription ?? this.actionDescription,
      overdueAt: overdueAt ?? this.overdueAt,
      reminderCount: reminderCount ?? this.reminderCount,
      lastReminderAt: lastReminderAt ?? this.lastReminderAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Create a new tracker for an alert
  factory EscalationTracker.create({
    required String id,
    required String patientId,
    required String alertId,
    required RiskLevel riskLevel,
  }) {
    final config = DefaultEscalationTimings.getConfig(riskLevel);
    final now = DateTime.now();

    return EscalationTracker(
      id: id,
      patientId: patientId,
      alertId: alertId,
      initialRiskLevel: riskLevel,
      status: EscalationTrackingStatus.pending,
      startedAt: now,
      acknowledgmentDeadline: now.add(config.acknowledgmentDeadline),
      actionDeadline: now.add(config.actionDeadline),
    );
  }
}

/// Summary of safety net status across all patients
class SafetyNetSummary extends Equatable {
  /// Total active trackers
  final int totalActiveTrackers;

  /// Trackers awaiting acknowledgment
  final int pendingCount;

  /// Trackers that are overdue
  final int overdueCount;

  /// Trackers acknowledged but awaiting action
  final int awaitingActionCount;

  /// List of patient IDs with overdue escalations
  final List<String> overduePatientIds;

  /// Most urgent overdue tracker (if any)
  final EscalationTracker? mostUrgent;

  /// Timestamp of summary generation
  final DateTime generatedAt;

  const SafetyNetSummary({
    required this.totalActiveTrackers,
    required this.pendingCount,
    required this.overdueCount,
    required this.awaitingActionCount,
    required this.overduePatientIds,
    this.mostUrgent,
    required this.generatedAt,
  });

  /// Whether there are any urgent issues
  bool get hasUrgentIssues => overdueCount > 0;

  /// Whether there are any active trackers
  bool get hasActiveTrackers => totalActiveTrackers > 0;

  /// Summary message for dashboard display
  String get summaryMessage {
    if (overdueCount > 0) {
      return '$overdueCount patient(s) with unacknowledged deterioration';
    }
    if (pendingCount > 0) {
      return '$pendingCount patient(s) awaiting review';
    }
    if (awaitingActionCount > 0) {
      return '$awaitingActionCount patient(s) awaiting documented action';
    }
    return 'No pending escalations';
  }

  @override
  List<Object?> get props => [
        totalActiveTrackers,
        pendingCount,
        overdueCount,
        awaitingActionCount,
        overduePatientIds,
        generatedAt,
      ];

  factory SafetyNetSummary.empty() {
    return SafetyNetSummary(
      totalActiveTrackers: 0,
      pendingCount: 0,
      overdueCount: 0,
      awaitingActionCount: 0,
      overduePatientIds: const [],
      generatedAt: DateTime.now(),
    );
  }
}
