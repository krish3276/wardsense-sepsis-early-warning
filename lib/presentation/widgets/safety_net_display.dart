/// Safety Net Display Widgets
///
/// Displays the missed-escalation safety net status.
/// Visual indicators for patients with unacknowledged deterioration.
///
/// CORE PRINCIPLE:
/// "Sepsis mortality is not due to lack of data — it's due to delayed action."
///
/// Design goals:
/// - Visually distinct but non-alarming
/// - Show time since alert
/// - Show recommended next step
/// - Support workflow without adding cognitive load

import 'package:flutter/material.dart';
import '../../domain/entities/escalation_safety_net.dart';
import '../../core/constants/risk_level.dart';

/// Dashboard summary card for safety net status
class SafetyNetSummaryCard extends StatelessWidget {
  final SafetyNetSummary summary;
  final VoidCallback? onTap;

  const SafetyNetSummaryCard({
    super.key,
    required this.summary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasIssues = summary.hasUrgentIssues;
    final color = hasIssues
        ? const Color(0xFFD32F2F)
        : summary.hasActiveTrackers
            ? const Color(0xFFF9A825)
            : const Color(0xFF4CAF50);

    return Card(
      elevation: hasIssues ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasIssues ? Colors.red : color.withOpacity(0.3),
          width: hasIssues ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      hasIssues
                          ? Icons.warning_amber_rounded
                          : summary.hasActiveTrackers
                              ? Icons.pending_actions
                              : Icons.check_circle_outline,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Escalation Safety Net',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          summary.summaryMessage,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: hasIssues ? Colors.red : null,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Counters (if any active)
              if (summary.hasActiveTrackers) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (summary.overdueCount > 0) ...[
                      _CounterChip(
                        label: 'Overdue',
                        count: summary.overdueCount,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (summary.pendingCount > 0) ...[
                      _CounterChip(
                        label: 'Pending',
                        count: summary.pendingCount,
                        color: const Color(0xFFF9A825),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (summary.awaitingActionCount > 0)
                      _CounterChip(
                        label: 'Awaiting Action',
                        count: summary.awaitingActionCount,
                        color: const Color(0xFF42A5F5),
                      ),
                  ],
                ),
              ],

              // Most urgent tracker
              if (summary.mostUrgent != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Most Urgent',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Unacknowledged for ${summary.mostUrgent!.timeSinceStartDisplay}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        summary.mostUrgent!.initialRiskLevel.shortLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: summary.mostUrgent!.initialRiskLevel.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Quote/principle
              if (!summary.hasActiveTrackers) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'All flagged patients have documented responses.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CounterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CounterChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Patient-level safety net indicator
class PatientSafetyNetBadge extends StatelessWidget {
  final EscalationTracker tracker;
  final VoidCallback? onTap;

  const PatientSafetyNetBadge({
    super.key,
    required this.tracker,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!tracker.isActive) return const SizedBox.shrink();

    final isOverdue = tracker.status == EscalationTrackingStatus.overdue;
    final color = isOverdue
        ? Colors.red
        : tracker.status == EscalationTrackingStatus.pending
            ? const Color(0xFFF9A825)
            : const Color(0xFF42A5F5);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(isOverdue ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOverdue ? Icons.warning_amber_rounded : Icons.pending_actions,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tracker.status.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  tracker.timeSinceStartDisplay,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 14,
              color: color.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full tracker detail card
class EscalationTrackerCard extends StatelessWidget {
  final EscalationTracker tracker;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onRecordAction;
  final VoidCallback? onResolve;

  const EscalationTrackerCard({
    super.key,
    required this.tracker,
    this.onAcknowledge,
    this.onRecordAction,
    this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = tracker.status == EscalationTrackingStatus.overdue;
    final color = _getColorForStatus(tracker.status);

    return Card(
      elevation: isOverdue ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue ? Colors.red : color.withOpacity(0.3),
          width: isOverdue ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getIconForStatus(tracker.status),
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tracker.status.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Alert time: ${tracker.timeSinceStartDisplay}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tracker.initialRiskLevel.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tracker.initialRiskLevel.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tracker.initialRiskLevel.color,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Safety message
                if (tracker.safetyNetMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? Colors.red.withOpacity(0.1)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: isOverdue
                          ? Border.all(color: Colors.red.withOpacity(0.3))
                          : null,
                    ),
                    child: Text(
                      tracker.safetyNetMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isOverdue ? Colors.red : null,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Timeline
                _TimelineItem(
                  icon: Icons.flag,
                  title: 'Alert Started',
                  time: _formatTime(tracker.startedAt),
                  isCompleted: true,
                ),
                _TimelineItem(
                  icon: Icons.visibility,
                  title: 'Acknowledged',
                  time: tracker.acknowledgedAt != null
                      ? '${_formatTime(tracker.acknowledgedAt!)} by ${tracker.acknowledgedBy}'
                      : 'Deadline: ${_formatTime(tracker.acknowledgmentDeadline)}',
                  isCompleted: tracker.acknowledgedAt != null,
                  isOverdue: tracker.isAcknowledgmentOverdue,
                ),
                _TimelineItem(
                  icon: Icons.medical_services,
                  title: 'Action Documented',
                  time: tracker.actionTakenAt != null
                      ? '${_formatTime(tracker.actionTakenAt!)} by ${tracker.actionTakenBy}'
                      : 'Deadline: ${_formatTime(tracker.actionDeadline)}',
                  isCompleted: tracker.actionTakenAt != null,
                  isOverdue: tracker.isActionOverdue,
                  isLast: true,
                ),

                // Action description if present
                if (tracker.actionDescription != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Action: ${tracker.actionDescription}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],

                // Recommended next step
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tracker.recommendedNextStep,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (tracker.status.requiresAttention) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (tracker.acknowledgedAt == null) ...[
                    FilledButton.icon(
                      onPressed: onAcknowledge,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Acknowledge'),
                    ),
                  ] else if (tracker.actionTakenAt == null) ...[
                    OutlinedButton(
                      onPressed: onResolve,
                      child: const Text('Resolve'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onRecordAction,
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text('Record Action'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColorForStatus(EscalationTrackingStatus status) {
    switch (status) {
      case EscalationTrackingStatus.overdue:
        return Colors.red;
      case EscalationTrackingStatus.pending:
        return const Color(0xFFF9A825);
      case EscalationTrackingStatus.acknowledged:
        return const Color(0xFF42A5F5);
      case EscalationTrackingStatus.actionTaken:
        return const Color(0xFF4CAF50);
      case EscalationTrackingStatus.resolved:
        return const Color(0xFF4CAF50);
      case EscalationTrackingStatus.dismissed:
        return const Color(0xFF78909C);
    }
  }

  IconData _getIconForStatus(EscalationTrackingStatus status) {
    switch (status) {
      case EscalationTrackingStatus.overdue:
        return Icons.warning_amber_rounded;
      case EscalationTrackingStatus.pending:
        return Icons.pending_actions;
      case EscalationTrackingStatus.acknowledged:
        return Icons.visibility;
      case EscalationTrackingStatus.actionTaken:
        return Icons.check_circle;
      case EscalationTrackingStatus.resolved:
        return Icons.check_circle;
      case EscalationTrackingStatus.dismissed:
        return Icons.cancel;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final bool isCompleted;
  final bool isOverdue;
  final bool isLast;

  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.isCompleted,
    this.isOverdue = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOverdue
        ? Colors.red
        : isCompleted
            ? const Color(0xFF4CAF50)
            : Theme.of(context).colorScheme.outline;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: isCompleted
                    ? const Color(0xFF4CAF50).withOpacity(0.3)
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isOverdue ? Colors.red : null,
                      ),
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverdue
                            ? Colors.red
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (isCompleted)
          const Icon(Icons.check, size: 16, color: Color(0xFF4CAF50)),
        if (isOverdue) const Icon(Icons.error, size: 16, color: Colors.red),
      ],
    );
  }
}
