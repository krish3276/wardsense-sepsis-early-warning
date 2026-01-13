/// Escalation Prompt Display Widgets
///
/// Displays context-aware escalation prompts in a calm, clinical style.
/// Designed to reduce alert fatigue while providing actionable guidance.
///
/// Key design principles:
/// - Calm, not alarming
/// - Clinical reasoning style
/// - Actionable suggestions
/// - Clear time expectations

import 'package:flutter/material.dart';
import '../../domain/entities/escalation_prompt.dart';
import '../../core/constants/risk_level.dart';

/// Main escalation prompt card
class EscalationPromptCard extends StatelessWidget {
  final EscalationPrompt prompt;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onViewDetails;

  const EscalationPromptCard({
    super.key,
    required this.prompt,
    this.onAcknowledge,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColorForUrgency(prompt.urgency);
    final isOverdue = prompt.isOverdue;

    return Card(
      elevation: isOverdue ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue ? Colors.red : color.withOpacity(0.5),
          width: isOverdue ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForUrgency(prompt.urgency),
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            prompt.urgency.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: prompt.riskLevel.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              prompt.riskLevel.shortLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: prompt.riskLevel.color,
                              ),
                            ),
                          ),
                          if (prompt.isHighRiskPatient) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF6C00).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    size: 10,
                                    color: Color(0xFFEF6C00),
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'High-Risk',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF6C00),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prompt.timeSinceDisplay,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isOverdue
                                  ? Colors.red
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (!prompt.isAcknowledged)
                  Text(
                    'Review in ${prompt.urgency.timeframeDisplay}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),

          // Main prompt content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main prompt message
                Text(
                  prompt.mainPrompt,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                      ),
                ),

                // Velocity flag
                if (prompt.hasVelocityDeteriorationFlag) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF6C00).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFEF6C00).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.speed,
                          size: 14,
                          color: Color(0xFFEF6C00),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Rapid vital sign changes detected',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFFEF6C00),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Suggested actions
                const SizedBox(height: 12),
                Text(
                  'Suggested Actions',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                ...prompt.suggestedActions.take(3).map(
                      (action) => _ActionItem(action: action),
                    ),
              ],
            ),
          ),

          // Actions bar
          if (!prompt.isAcknowledged) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onViewDetails,
                    child: const Text('View Details'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onAcknowledge,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Acknowledge'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColorForUrgency(EscalationUrgency urgency) {
    switch (urgency) {
      case EscalationUrgency.urgent:
        return const Color(0xFFD32F2F);
      case EscalationUrgency.prompt:
        return const Color(0xFFEF6C00);
      case EscalationUrgency.soon:
        return const Color(0xFFF9A825);
      case EscalationUrgency.routine:
        return const Color(0xFF42A5F5);
      case EscalationUrgency.informational:
        return const Color(0xFF78909C);
    }
  }

  IconData _getIconForUrgency(EscalationUrgency urgency) {
    switch (urgency) {
      case EscalationUrgency.urgent:
        return Icons.priority_high;
      case EscalationUrgency.prompt:
        return Icons.notifications_active;
      case EscalationUrgency.soon:
        return Icons.schedule;
      case EscalationUrgency.routine:
        return Icons.checklist;
      case EscalationUrgency.informational:
        return Icons.info_outline;
    }
  }
}

class _ActionItem extends StatelessWidget {
  final EscalationAction action;

  const _ActionItem({required this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: Text(
                '${action.priority}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (action.contextNotes != null)
                  Text(
                    action.contextNotes!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact escalation banner for patient card
class EscalationBanner extends StatelessWidget {
  final EscalationPrompt prompt;
  final VoidCallback? onTap;

  const EscalationBanner({
    super.key,
    required this.prompt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColorForUrgency(prompt.urgency);
    final isOverdue = prompt.isOverdue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(isOverdue ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOverdue ? Colors.red : color.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getIconForUrgency(prompt.urgency),
              size: 16,
              color: isOverdue ? Colors.red : color,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _getShortMessage(prompt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isOverdue ? Colors.red : color,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              prompt.timeSinceDisplay,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  String _getShortMessage(EscalationPrompt prompt) {
    if (prompt.isOverdue) {
      return 'Overdue: ${prompt.urgency.displayName} needed';
    }
    if (prompt.hasVelocityDeteriorationFlag) {
      return 'Rapid deterioration - ${prompt.urgency.displayName}';
    }
    if (prompt.isHighRiskPatient) {
      return 'High-risk patient - ${prompt.urgency.displayName}';
    }
    return prompt.urgency.displayName;
  }

  Color _getColorForUrgency(EscalationUrgency urgency) {
    switch (urgency) {
      case EscalationUrgency.urgent:
        return const Color(0xFFD32F2F);
      case EscalationUrgency.prompt:
        return const Color(0xFFEF6C00);
      case EscalationUrgency.soon:
        return const Color(0xFFF9A825);
      case EscalationUrgency.routine:
        return const Color(0xFF42A5F5);
      case EscalationUrgency.informational:
        return const Color(0xFF78909C);
    }
  }

  IconData _getIconForUrgency(EscalationUrgency urgency) {
    switch (urgency) {
      case EscalationUrgency.urgent:
        return Icons.priority_high;
      case EscalationUrgency.prompt:
        return Icons.notifications_active;
      case EscalationUrgency.soon:
        return Icons.schedule;
      case EscalationUrgency.routine:
        return Icons.checklist;
      case EscalationUrgency.informational:
        return Icons.info_outline;
    }
  }
}
