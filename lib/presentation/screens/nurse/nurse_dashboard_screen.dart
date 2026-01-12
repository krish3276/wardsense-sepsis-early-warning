/// Nurse Dashboard Screen
///
/// Primary interface for nurses with quick access to:
/// - Patient list with color-coded risk indicators
/// - Quick vitals entry
/// - Active alerts
/// - Last vitals time for each patient

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/risk_level.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/patient.dart';
import '../../providers/providers.dart';
import '../../widgets/patient_card.dart';
import '../../widgets/risk_summary_bar.dart';
import '../../widgets/search_bar_widget.dart';
import '../patient/patient_detail_screen.dart';
import '../vitals/vital_entry_screen.dart';
import '../home/home_screen.dart';

class NurseDashboardScreen extends ConsumerStatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  ConsumerState<NurseDashboardScreen> createState() =>
      _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends ConsumerState<NurseDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [_PatientListTab(), _AlertsTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Patients',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: ref.watch(unacknowledgedAlertCountProvider) > 0,
              label: Text('${ref.watch(unacknowledgedAlertCountProvider)}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: ref.watch(unacknowledgedAlertCountProvider) > 0,
              label: Text('${ref.watch(unacknowledgedAlertCountProvider)}'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Alerts',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openVitalEntry(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Vitals'),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('WardSense'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => refreshAllData(ref),
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
          onPressed: () {
            ref.read(themeModeProvider.notifier).toggleDarkMode();
          },
          tooltip: 'Toggle Theme',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'switch_role') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'switch_role',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz),
                  SizedBox(width: 8),
                  Text('Switch Role'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openVitalEntry(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const VitalEntryScreen()));
  }
}

/// Patient List Tab
class _PatientListTab extends ConsumerWidget {
  const _PatientListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final patients = ref.watch(filteredPatientsProvider);
    ref.watch(refreshNotifierProvider);

    return Column(
      children: [
        // Risk summary bar
        RiskSummaryBar(
          patients: patients,
        ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),

        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: SearchBarWidget(
            hintText: 'Search patients by name or bed...',
            onChanged: (query) {
              ref.read(patientSearchQueryProvider.notifier).state = query;
            },
          ),
        ),

        // Overdue vitals warning
        if (stats.overdueVitals > 0)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${stats.overdueVitals} patient(s) have overdue vitals',
                    style: TextStyle(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).shake(delay: 500.ms, hz: 2),

        const SizedBox(height: 8),

        // Patient list
        Expanded(
          child: patients.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return PatientCard(
                      patient: patient,
                      onTap: () => _openPatientDetail(context, ref, patient),
                    ).animate().fadeIn(
                          delay: Duration(milliseconds: 50 * index),
                          duration: 200.ms,
                        );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No patients found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  void _openPatientDetail(
    BuildContext context,
    WidgetRef ref,
    Patient patient,
  ) {
    ref.read(selectedPatientIdProvider.notifier).state = patient.id;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PatientDetailScreen(patientId: patient.id),
      ),
    );
  }
}

/// Alerts Tab
class _AlertsTab extends ConsumerWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(activeAlertsProvider);
    ref.watch(refreshNotifierProvider);

    if (alerts.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        final patient = ref.watch(patientProvider(alert.patientId));

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: alert.riskLevel.color.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: () {
              if (patient != null) {
                ref.read(selectedPatientIdProvider.notifier).state = patient.id;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        PatientDetailScreen(patientId: patient.id),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: alert.riskLevel.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          alert.riskLevel.icon,
                          color: alert.riskLevel.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient?.name ?? 'Unknown Patient',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              patient?.bedDisplay ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: alert.riskLevel.color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          alert.riskLevel.shortLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Alert title
                  Text(
                    alert.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),

                  const SizedBox(height: 4),

                  // Factors summary
                  Text(
                    alert.factorsSummary,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: alert.riskLevel.color,
                        ),
                  ),

                  const SizedBox(height: 8),

                  // Time
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        alert.timeSinceAlert,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(
              delay: Duration(milliseconds: 50 * index),
              duration: 200.ms,
            );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: RiskLevel.green.color,
          ),
          const SizedBox(height: 16),
          Text(
            'No active alerts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'All patients are stable',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
        ],
      ),
    );
  }
}
