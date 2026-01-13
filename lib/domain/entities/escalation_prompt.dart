/// Escalation Prompt entity
///
/// Context-aware escalation prompts that provide clinical reasoning-based
/// suggestions rather than generic alarms.
///
/// CORE PRINCIPLE:
/// "Reduce alert fatigue by providing calm, clinical-style prompts
/// that match real ward workflows."
///
/// These prompts are designed to:
/// 1. Feel like clinical reasoning, not automation
/// 2. Never claim diagnosis
/// 3. Suggest concrete next steps
/// 4. Respect the clinician's judgment

import 'package:equatable/equatable.dart';
import '../../core/constants/risk_level.dart';

/// Urgency level for escalation prompts
///
/// Determines the visual presentation and suggested timeframe
enum EscalationUrgency {
  /// Informational - no immediate action required
  informational,

  /// Routine - suggest checking within standard interval
  routine,

  /// Soon - suggest review within 30-60 minutes
  soon,

  /// Prompt - suggest review within 15-30 minutes
  prompt,

  /// Urgent - suggest immediate senior review
  urgent,
}

extension EscalationUrgencyExtension on EscalationUrgency {
  String get displayName {
    switch (this) {
      case EscalationUrgency.informational:
        return 'For Information';
      case EscalationUrgency.routine:
        return 'Routine Review';
      case EscalationUrgency.soon:
        return 'Review Soon';
      case EscalationUrgency.prompt:
        return 'Prompt Review';
      case EscalationUrgency.urgent:
        return 'Urgent Review';
    }
  }

  /// Suggested action timeframe in minutes
  int get suggestedTimeframeMinutes {
    switch (this) {
      case EscalationUrgency.informational:
        return 240; // 4 hours
      case EscalationUrgency.routine:
        return 120; // 2 hours
      case EscalationUrgency.soon:
        return 60; // 1 hour
      case EscalationUrgency.prompt:
        return 30;
      case EscalationUrgency.urgent:
        return 15;
    }
  }

  /// Human-readable timeframe
  String get timeframeDisplay {
    final mins = suggestedTimeframeMinutes;
    if (mins >= 60) {
      final hours = mins ~/ 60;
      return hours == 1 ? '1 hour' : '$hours hours';
    }
    return '$mins minutes';
  }
}

/// Type of escalation action suggested
enum EscalationActionType {
  /// Repeat vital signs measurement
  repeatVitals,

  /// Review at bedside
  bedsideReview,

  /// Inform nurse in charge
  informNurseInCharge,

  /// Inform duty doctor
  informDutyDoctor,

  /// Senior/registrar review
  seniorReview,

  /// Consider sepsis pathway
  considerSepsisPathway,

  /// Consider fluid resuscitation
  considerFluids,

  /// Close monitoring
  closeMonitoring,

  /// Document assessment
  documentAssessment,
}

extension EscalationActionTypeExtension on EscalationActionType {
  String get displayName {
    switch (this) {
      case EscalationActionType.repeatVitals:
        return 'Repeat vital signs';
      case EscalationActionType.bedsideReview:
        return 'Bedside review';
      case EscalationActionType.informNurseInCharge:
        return 'Inform nurse in charge';
      case EscalationActionType.informDutyDoctor:
        return 'Inform duty doctor';
      case EscalationActionType.seniorReview:
        return 'Request senior/registrar review';
      case EscalationActionType.considerSepsisPathway:
        return 'Consider sepsis pathway activation';
      case EscalationActionType.considerFluids:
        return 'Consider fluid status assessment';
      case EscalationActionType.closeMonitoring:
        return 'Increase monitoring frequency';
      case EscalationActionType.documentAssessment:
        return 'Document clinical assessment';
    }
  }

  /// Detailed description of the action
  String get description {
    switch (this) {
      case EscalationActionType.repeatVitals:
        return 'Measure and record all vital signs again to confirm the trend';
      case EscalationActionType.bedsideReview:
        return 'Perform a focused clinical assessment at the bedside';
      case EscalationActionType.informNurseInCharge:
        return 'Brief the nurse in charge about the patient\'s changing status';
      case EscalationActionType.informDutyDoctor:
        return 'Contact the duty doctor or covering physician';
      case EscalationActionType.seniorReview:
        return 'Request review by senior resident or registrar';
      case EscalationActionType.considerSepsisPathway:
        return 'Evaluate for sepsis pathway activation per hospital protocol';
      case EscalationActionType.considerFluids:
        return 'Assess hydration status, consider IV access and fluids';
      case EscalationActionType.closeMonitoring:
        return 'Reduce vital signs interval to every 30-60 minutes';
      case EscalationActionType.documentAssessment:
        return 'Document current findings and clinical impression in notes';
    }
  }
}

/// A suggested escalation action
class EscalationAction extends Equatable {
  /// Type of action
  final EscalationActionType type;

  /// Priority order (1 = highest priority)
  final int priority;

  /// Whether this action is already completed
  final bool isCompleted;

  /// Timestamp when completed
  final DateTime? completedAt;

  /// Who completed the action
  final String? completedBy;

  /// Additional context-specific notes
  final String? contextNotes;

  const EscalationAction({
    required this.type,
    required this.priority,
    this.isCompleted = false,
    this.completedAt,
    this.completedBy,
    this.contextNotes,
  });

  String get displayName => type.displayName;
  String get description => type.description;

  @override
  List<Object?> get props =>
      [type, priority, isCompleted, completedAt, completedBy];

  EscalationAction copyWith({
    EscalationActionType? type,
    int? priority,
    bool? isCompleted,
    DateTime? completedAt,
    String? completedBy,
    String? contextNotes,
  }) {
    return EscalationAction(
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      contextNotes: contextNotes ?? this.contextNotes,
    );
  }
}

/// Context-aware escalation prompt
///
/// Combines multiple data sources to generate a clinically meaningful
/// escalation suggestion with full explainability.
class EscalationPrompt extends Equatable {
  /// Unique identifier
  final String id;

  /// Patient ID reference
  final String patientId;

  /// Urgency level
  final EscalationUrgency urgency;

  /// Main prompt message (clinical reasoning style)
  final String mainPrompt;

  /// Supporting clinical context
  final String clinicalContext;

  /// The specific factors that triggered this prompt
  final List<String> triggeringFactors;

  /// Suggested actions in priority order
  final List<EscalationAction> suggestedActions;

  /// Risk level from current analysis
  final RiskLevel riskLevel;

  /// Whether patient has high-risk profile
  final bool isHighRiskPatient;

  /// Whether velocity-based deterioration detected
  final bool hasVelocityDeteriorationFlag;

  /// Timestamp when prompt was generated
  final DateTime generatedAt;

  /// Whether this prompt has been acknowledged
  final bool isAcknowledged;

  /// Timestamp when acknowledged
  final DateTime? acknowledgedAt;

  /// Who acknowledged the prompt
  final String? acknowledgedBy;

  /// Notes added during acknowledgment
  final String? acknowledgmentNotes;

  /// Whether this prompt is still active
  final bool isActive;

  const EscalationPrompt({
    required this.id,
    required this.patientId,
    required this.urgency,
    required this.mainPrompt,
    required this.clinicalContext,
    required this.triggeringFactors,
    required this.suggestedActions,
    required this.riskLevel,
    required this.isHighRiskPatient,
    required this.hasVelocityDeteriorationFlag,
    required this.generatedAt,
    this.isAcknowledged = false,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.acknowledgmentNotes,
    this.isActive = true,
  });

  /// Time since prompt was generated
  Duration get timeSinceGenerated => DateTime.now().difference(generatedAt);

  /// Whether prompt is overdue for acknowledgment
  bool get isOverdue =>
      !isAcknowledged &&
      timeSinceGenerated.inMinutes > urgency.suggestedTimeframeMinutes;

  /// Get primary action
  EscalationAction? get primaryAction =>
      suggestedActions.isNotEmpty ? suggestedActions.first : null;

  /// Get incomplete actions
  List<EscalationAction> get incompleteActions =>
      suggestedActions.where((a) => !a.isCompleted).toList();

  /// Formatted time since generation
  String get timeSinceDisplay {
    final mins = timeSinceGenerated.inMinutes;
    if (mins < 60) {
      return '$mins min ago';
    } else if (mins < 1440) {
      return '${mins ~/ 60} hr ago';
    }
    return '${mins ~/ 1440} days ago';
  }

  @override
  List<Object?> get props => [
        id,
        patientId,
        urgency,
        mainPrompt,
        riskLevel,
        generatedAt,
        isAcknowledged,
        isActive,
      ];

  EscalationPrompt copyWith({
    String? id,
    String? patientId,
    EscalationUrgency? urgency,
    String? mainPrompt,
    String? clinicalContext,
    List<String>? triggeringFactors,
    List<EscalationAction>? suggestedActions,
    RiskLevel? riskLevel,
    bool? isHighRiskPatient,
    bool? hasVelocityDeteriorationFlag,
    DateTime? generatedAt,
    bool? isAcknowledged,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    String? acknowledgmentNotes,
    bool? isActive,
  }) {
    return EscalationPrompt(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      urgency: urgency ?? this.urgency,
      mainPrompt: mainPrompt ?? this.mainPrompt,
      clinicalContext: clinicalContext ?? this.clinicalContext,
      triggeringFactors: triggeringFactors ?? this.triggeringFactors,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      riskLevel: riskLevel ?? this.riskLevel,
      isHighRiskPatient: isHighRiskPatient ?? this.isHighRiskPatient,
      hasVelocityDeteriorationFlag:
          hasVelocityDeteriorationFlag ?? this.hasVelocityDeteriorationFlag,
      generatedAt: generatedAt ?? this.generatedAt,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgmentNotes: acknowledgmentNotes ?? this.acknowledgmentNotes,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Sample escalation prompt templates
///
/// These are clinical reasoning-style prompts that feel natural to clinicians.
class EscalationPromptTemplates {
  EscalationPromptTemplates._();

  static String risingVitalsWithHighRisk(
    String velocityDescription,
    String riskProfileDescription,
  ) {
    return '$velocityDescription in a $riskProfileDescription — '
        'consider early sepsis pathway evaluation.';
  }

  static String rapidDeteriorationDetected(String trendDescription) {
    return 'Rapid vital sign changes detected: $trendDescription. '
        'Recommend bedside review and repeat vital signs in 30 minutes.';
  }

  static String sepsisPatternSuggested(String patternDescription) {
    return 'Vital sign pattern consistent with early sepsis: $patternDescription. '
        'Consider sepsis screening per hospital protocol.';
  }

  static String repeatVitalsNeeded(String reason) {
    return 'Repeat vital signs recommended: $reason. '
        'This will help confirm or exclude a developing trend.';
  }

  static String highRiskPatientMonitoring(
    String riskFactors,
    String currentStatus,
  ) {
    return 'Patient with $riskFactors showing $currentStatus. '
        'Enhanced monitoring advised due to reduced physiological reserve.';
  }

  static String unacknowledgedDeterioration(
    int minutesSinceAlert,
    String alertDescription,
  ) {
    return 'Alert "$alertDescription" unacknowledged for $minutesSinceAlert minutes. '
        'Please document review or escalate as appropriate.';
  }
}
