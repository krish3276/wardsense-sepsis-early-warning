/// Missed-Escalation Safety Net Service
///
/// Implements the safety net to detect delayed or missed action on alerts.
/// This is the implementation for Feature 4.
///
/// CORE PRINCIPLE:
/// "Sepsis mortality is not due to lack of data — it's due to delayed action."
///
/// This service tracks escalation timers for flagged patients and
/// highlights when alerts have not been acknowledged within appropriate
/// timeframes.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/risk_level.dart';
import '../../domain/entities/escalation_safety_net.dart';
import '../../domain/entities/alert.dart';

/// In-memory storage for escalation trackers
/// In production, this would be persisted to Hive or another storage
class _EscalationTrackerStore {
  final Map<String, EscalationTracker> _trackers = {};

  List<EscalationTracker> get all => _trackers.values.toList();

  EscalationTracker? getById(String id) => _trackers[id];

  EscalationTracker? getByAlertId(String alertId) {
    try {
      return _trackers.values.firstWhere((t) => t.alertId == alertId);
    } catch (_) {
      return null;
    }
  }

  List<EscalationTracker> getByPatientId(String patientId) {
    return _trackers.values.where((t) => t.patientId == patientId).toList();
  }

  List<EscalationTracker> getActive() {
    return _trackers.values.where((t) => t.isActive).toList();
  }

  void add(EscalationTracker tracker) {
    _trackers[tracker.id] = tracker;
  }

  void update(EscalationTracker tracker) {
    _trackers[tracker.id] = tracker;
  }

  void remove(String id) {
    _trackers.remove(id);
  }
}

/// Global store instance
final _store = _EscalationTrackerStore();

/// Safety net refresh notifier - increment to trigger provider rebuild
final safetyNetRefreshProvider = StateProvider<int>((ref) => 0);

/// Provider for the safety net service
final safetyNetServiceProvider = Provider<SafetyNetService>((ref) {
  return SafetyNetService(ref);
});

/// Provider for active escalation trackers
final activeTrackersProvider = Provider<List<EscalationTracker>>((ref) {
  ref.watch(safetyNetRefreshProvider); // Watch for refresh
  final service = ref.watch(safetyNetServiceProvider);
  return service.getActiveTrackers();
});

/// Provider for overdue escalation trackers
final overdueTrackersProvider = Provider<List<EscalationTracker>>((ref) {
  ref.watch(safetyNetRefreshProvider); // Watch for refresh
  final service = ref.watch(safetyNetServiceProvider);
  return service.getOverdueTrackers();
});

/// Provider for safety net summary
final safetyNetSummaryProvider = Provider<SafetyNetSummary>((ref) {
  ref.watch(safetyNetRefreshProvider); // Watch for refresh
  final service = ref.watch(safetyNetServiceProvider);
  return service.getSummary();
});

/// Provider for patient-specific tracker
final patientTrackerProvider =
    Provider.family<EscalationTracker?, String>((ref, patientId) {
  ref.watch(safetyNetRefreshProvider); // Watch for refresh
  final service = ref.watch(safetyNetServiceProvider);
  final trackers = service.getTrackersForPatient(patientId);
  // Return most recent active tracker
  if (trackers.isEmpty) return null;
  final activeTrackers = trackers.where((t) => t.isActive).toList();
  if (activeTrackers.isEmpty) return null;
  activeTrackers.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  return activeTrackers.first;
});

/// Safety Net Service
///
/// Manages escalation tracking to ensure timely response to alerts.
class SafetyNetService {
  static const _uuid = Uuid();
  final Ref _ref;

  SafetyNetService(this._ref);

  /// Notify providers that data has changed
  void _notifyChange() {
    // Use Future.microtask to avoid modifying state during build
    Future.microtask(() {
      try {
        _ref.read(safetyNetRefreshProvider.notifier).state++;
      } catch (_) {
        // Ignore if provider is not available
      }
    });
  }

  /// Start tracking an alert for a patient
  ///
  /// Creates a new escalation tracker when a patient is flagged
  /// as moderate or high risk.
  EscalationTracker? startTracking({
    required String patientId,
    required Alert alert,
  }) {
    // Only track yellow, orange, and red alerts
    if (alert.riskLevel == RiskLevel.green) {
      return null;
    }

    // Check if already tracking this alert
    final existing = _store.getByAlertId(alert.id);
    if (existing != null) {
      return existing;
    }

    // Create new tracker
    final tracker = EscalationTracker.create(
      id: _uuid.v4(),
      patientId: patientId,
      alertId: alert.id,
      riskLevel: alert.riskLevel,
    );

    _store.add(tracker);
    _notifyChange();
    return tracker;
  }

  /// Acknowledge an escalation tracker
  ///
  /// Records that a clinician has reviewed the alert.
  EscalationTracker? acknowledge({
    required String trackerId,
    required String acknowledgedBy,
  }) {
    final tracker = _store.getById(trackerId);
    if (tracker == null) return null;

    final now = DateTime.now();
    final updated = tracker.copyWith(
      status: EscalationTrackingStatus.acknowledged,
      acknowledgedAt: now,
      acknowledgedBy: acknowledgedBy,
    );

    _store.update(updated);
    _notifyChange();
    return updated;
  }

  /// Record action taken for an escalation tracker
  ///
  /// Documents that clinical action has been taken.
  EscalationTracker? recordAction({
    required String trackerId,
    required String actionTakenBy,
    required String actionDescription,
  }) {
    final tracker = _store.getById(trackerId);
    if (tracker == null) return null;

    final now = DateTime.now();
    final updated = tracker.copyWith(
      status: EscalationTrackingStatus.actionTaken,
      actionTakenAt: now,
      actionTakenBy: actionTakenBy,
      actionDescription: actionDescription,
      // Also set acknowledged if not already
      acknowledgedAt: tracker.acknowledgedAt ?? now,
      acknowledgedBy: tracker.acknowledgedBy ?? actionTakenBy,
    );

    _store.update(updated);
    _notifyChange();
    return updated;
  }

  /// Resolve an escalation tracker
  ///
  /// Marks the escalation as resolved (patient condition improved).
  EscalationTracker? resolve({
    required String trackerId,
    String? resolutionNotes,
  }) {
    final tracker = _store.getById(trackerId);
    if (tracker == null) return null;

    final updated = tracker.copyWith(
      status: EscalationTrackingStatus.resolved,
      resolutionNotes: resolutionNotes,
      isActive: false,
    );

    _store.update(updated);
    _notifyChange();
    return updated;
  }

  /// Dismiss an escalation tracker
  ///
  /// Manually dismiss with a documented reason.
  EscalationTracker? dismiss({
    required String trackerId,
    required String reason,
  }) {
    final tracker = _store.getById(trackerId);
    if (tracker == null) return null;

    final updated = tracker.copyWith(
      status: EscalationTrackingStatus.dismissed,
      resolutionNotes: 'Dismissed: $reason',
      isActive: false,
    );

    _store.update(updated);
    _notifyChange();
    return updated;
  }

  /// Check and update overdue status for all trackers
  ///
  /// Should be called periodically (e.g., every minute) to update
  /// tracker statuses.
  void checkOverdueTrackers() {
    final activeTrackers = _store.getActive();

    for (final tracker in activeTrackers) {
      if (tracker.status == EscalationTrackingStatus.pending &&
          tracker.isAcknowledgmentOverdue) {
        final updated = tracker.copyWith(
          status: EscalationTrackingStatus.overdue,
          overdueAt: DateTime.now(),
        );
        _store.update(updated);
      }
    }
  }

  /// Get all active trackers
  List<EscalationTracker> getActiveTrackers() {
    checkOverdueTrackers(); // Update status first
    return _store.getActive();
  }

  /// Get overdue trackers
  List<EscalationTracker> getOverdueTrackers() {
    checkOverdueTrackers();
    return _store
        .getActive()
        .where((t) => t.status == EscalationTrackingStatus.overdue)
        .toList();
  }

  /// Get trackers for a specific patient
  List<EscalationTracker> getTrackersForPatient(String patientId) {
    checkOverdueTrackers();
    return _store.getByPatientId(patientId);
  }

  /// Get tracker for a specific alert
  EscalationTracker? getTrackerForAlert(String alertId) {
    checkOverdueTrackers();
    return _store.getByAlertId(alertId);
  }

  /// Get safety net summary for dashboard
  SafetyNetSummary getSummary() {
    checkOverdueTrackers();
    final active = _store.getActive();

    final pending = active
        .where((t) => t.status == EscalationTrackingStatus.pending)
        .length;
    final overdue = active
        .where((t) => t.status == EscalationTrackingStatus.overdue)
        .length;
    final awaitingAction = active
        .where((t) => t.status == EscalationTrackingStatus.acknowledged)
        .length;

    final overduePatientIds = active
        .where((t) => t.status == EscalationTrackingStatus.overdue)
        .map((t) => t.patientId)
        .toSet()
        .toList();

    // Find most urgent (longest overdue)
    EscalationTracker? mostUrgent;
    if (overdue > 0) {
      final overdueTrackers = active
          .where((t) => t.status == EscalationTrackingStatus.overdue)
          .toList();
      overdueTrackers.sort((a, b) => a.startedAt.compareTo(b.startedAt));
      mostUrgent = overdueTrackers.first;
    }

    return SafetyNetSummary(
      totalActiveTrackers: active.length,
      pendingCount: pending,
      overdueCount: overdue,
      awaitingActionCount: awaitingAction,
      overduePatientIds: overduePatientIds,
      mostUrgent: mostUrgent,
      generatedAt: DateTime.now(),
    );
  }

  /// Get formatted safety net status message for a patient
  String getPatientSafetyStatus(String patientId) {
    final trackers =
        getTrackersForPatient(patientId).where((t) => t.isActive).toList();

    if (trackers.isEmpty) {
      return 'No active escalation tracking';
    }

    final overdue = trackers
        .where((t) => t.status == EscalationTrackingStatus.overdue)
        .toList();
    if (overdue.isNotEmpty) {
      final oldest =
          overdue.reduce((a, b) => a.startedAt.isBefore(b.startedAt) ? a : b);
      return 'UNACKNOWLEDGED DETERIORATION - ${oldest.timeSinceStartDisplay}';
    }

    final pending = trackers
        .where((t) => t.status == EscalationTrackingStatus.pending)
        .toList();
    if (pending.isNotEmpty) {
      final oldest =
          pending.reduce((a, b) => a.startedAt.isBefore(b.startedAt) ? a : b);
      return 'Awaiting review - ${oldest.timeSinceStartDisplay}';
    }

    final acknowledged = trackers
        .where((t) => t.status == EscalationTrackingStatus.acknowledged)
        .toList();
    if (acknowledged.isNotEmpty) {
      return 'Reviewed - awaiting documented action';
    }

    return 'Escalation tracked';
  }

  /// Clear all trackers (for testing/demo reset)
  void clearAll() {
    final all = _store.all;
    for (final tracker in all) {
      _store.remove(tracker.id);
    }
  }

  /// Create demo escalation trackers for demonstration
  void createDemoTrackers(List<Alert> alerts) {
    for (final alert in alerts) {
      if (alert.riskLevel != RiskLevel.green) {
        startTracking(patientId: alert.patientId, alert: alert);
      }
    }
  }
}

/// Extension for checking if escalation action is needed
extension AlertEscalationExtension on Alert {
  /// Whether this alert should trigger escalation tracking
  bool get shouldTrackEscalation =>
      riskLevel == RiskLevel.yellow ||
      riskLevel == RiskLevel.orange ||
      riskLevel == RiskLevel.red;

  /// Expected response time based on risk level
  int get expectedResponseMinutes {
    return DefaultEscalationTimings.getConfig(riskLevel)
        .maxAcknowledgmentMinutes;
  }
}
