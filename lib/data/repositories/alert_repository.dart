/// Alert repository for data access
///
/// Provides access to clinical alerts with offline-first architecture.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/risk_level.dart';
import '../../domain/entities/alert.dart';
import '../models/alert_model.dart';

/// Provider for alert repository
final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository();
});

/// Repository for alert data operations
class AlertRepository {
  Box get _box => Hive.box(AppConstants.alertsBox);

  /// Get all active alerts
  List<Alert> getActiveAlerts() {
    return _box.values
        .cast<AlertModel>()
        .where((a) => a.isActive && !a.isAcknowledged)
        .map((a) => a.toEntity())
        .toList()
      ..sort((a, b) => b.riskLevel.priority.compareTo(a.riskLevel.priority));
  }

  /// Get all alerts for a patient
  List<Alert> getAlertsForPatient(String patientId) {
    return _box.values
        .cast<AlertModel>()
        .where((a) => a.patientId == patientId)
        .map((a) => a.toEntity())
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get active alerts for a patient
  List<Alert> getActiveAlertsForPatient(String patientId) {
    return _box.values
        .cast<AlertModel>()
        .where(
          (a) => a.patientId == patientId && a.isActive && !a.isAcknowledged,
        )
        .map((a) => a.toEntity())
        .toList();
  }

  /// Get the most critical active alert for a patient
  Alert? getMostCriticalAlert(String patientId) {
    final alerts = getActiveAlertsForPatient(patientId);
    if (alerts.isEmpty) return null;

    return alerts.reduce(
      (a, b) => a.riskLevel.priority > b.riskLevel.priority ? a : b,
    );
  }

  /// Get an alert by ID
  Alert? getAlertById(String id) {
    final model = _box.get(id) as AlertModel?;
    return model?.toEntity();
  }

  /// Add a new alert
  Future<void> addAlert(Alert alert) async {
    final model = AlertModel.fromEntity(alert);
    await _box.put(alert.id, model);
  }

  /// Acknowledge an alert
  Future<void> acknowledgeAlert(
    String alertId,
    String acknowledgedBy, {
    String? notes,
  }) async {
    final model = _box.get(alertId) as AlertModel?;
    if (model != null) {
      final updated = AlertModel(
        id: model.id,
        patientId: model.patientId,
        riskLevelIndex: model.riskLevelIndex,
        title: model.title,
        description: model.description,
        factors: model.factors,
        recommendedActions: model.recommendedActions,
        timestamp: model.timestamp,
        isAcknowledged: true,
        acknowledgedAt: DateTime.now(),
        acknowledgedBy: acknowledgedBy,
        acknowledgementNotes: notes,
        isEscalated: model.isEscalated,
        triggeringVitalSignsId: model.triggeringVitalSignsId,
        analysisWindowHours: model.analysisWindowHours,
        isActive: model.isActive,
      );
      await _box.put(alertId, updated);
    }
  }

  /// Mark alert as escalated
  Future<void> markAlertEscalated(String alertId) async {
    final model = _box.get(alertId) as AlertModel?;
    if (model != null) {
      final updated = AlertModel(
        id: model.id,
        patientId: model.patientId,
        riskLevelIndex: model.riskLevelIndex,
        title: model.title,
        description: model.description,
        factors: model.factors,
        recommendedActions: model.recommendedActions,
        timestamp: model.timestamp,
        isAcknowledged: model.isAcknowledged,
        acknowledgedAt: model.acknowledgedAt,
        acknowledgedBy: model.acknowledgedBy,
        acknowledgementNotes: model.acknowledgementNotes,
        isEscalated: true,
        triggeringVitalSignsId: model.triggeringVitalSignsId,
        analysisWindowHours: model.analysisWindowHours,
        isActive: model.isActive,
      );
      await _box.put(alertId, updated);
    }
  }

  /// Deactivate an alert
  Future<void> deactivateAlert(String alertId) async {
    final model = _box.get(alertId) as AlertModel?;
    if (model != null) {
      final updated = AlertModel(
        id: model.id,
        patientId: model.patientId,
        riskLevelIndex: model.riskLevelIndex,
        title: model.title,
        description: model.description,
        factors: model.factors,
        recommendedActions: model.recommendedActions,
        timestamp: model.timestamp,
        isAcknowledged: model.isAcknowledged,
        acknowledgedAt: model.acknowledgedAt,
        acknowledgedBy: model.acknowledgedBy,
        acknowledgementNotes: model.acknowledgementNotes,
        isEscalated: model.isEscalated,
        triggeringVitalSignsId: model.triggeringVitalSignsId,
        analysisWindowHours: model.analysisWindowHours,
        isActive: false,
      );
      await _box.put(alertId, updated);
    }
  }

  /// Get count of active alerts by risk level
  Map<RiskLevel, int> getAlertCountsByRiskLevel() {
    final alerts = getActiveAlerts();
    final counts = <RiskLevel, int>{};

    for (final level in RiskLevel.values) {
      counts[level] = alerts.where((a) => a.riskLevel == level).length;
    }

    return counts;
  }

  /// Get unacknowledged alert count
  int getUnacknowledgedCount() {
    return _box.values
        .cast<AlertModel>()
        .where((a) => a.isActive && !a.isAcknowledged)
        .length;
  }
}
