/// Doctor Dashboard Screen
///
/// Advanced interface for doctors with:
/// - Trend analysis and graphs
/// - Detailed patient timeline
/// - Alert history and explanations
/// - Escalation management

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/risk_level.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/patient.dart';
import '../../providers/providers.dart';
import '../../widgets/patient_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../patient/patient_detail_screen.dart';
import '../home/home_screen.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() =>
      _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  int _selectedIndex = 0;
  RiskLevel? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _OverviewTab(
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              setState(() => _selectedFilter = filter);
            },
          ),
          const _CriticalPatientsTab(),
          const _AnalyticsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: ref.watch(dashboardStatsProvider).redPatients > 0,
              label: Text('${ref.watch(dashboardStatsProvider).redPatients}'),
              backgroundColor: RiskLevel.red.color,
              child: const Icon(Icons.warning_amber_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: ref.watch(dashboardStatsProvider).redPatients > 0,
              label: Text('${ref.watch(dashboardStatsProvider).redPatients}'),
              backgroundColor: RiskLevel.red.color,
              child: const Icon(Icons.warning_amber),
            ),
            label: 'Critical',
          ),
          const NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('WardSense'),
              Text(
                'Doctor View',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
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
}

/// Overview Tab
class _OverviewTab extends ConsumerWidget {
  final RiskLevel? selectedFilter;
  final ValueChanged<RiskLevel?> onFilterChanged;

  const _OverviewTab({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final patients = ref.watch(filteredPatientsProvider);
    ref.watch(refreshNotifierProvider);

    // Apply risk filter if selected
    final filteredPatients = selectedFilter != null
        ? patients.where((p) => p.currentRiskLevel == selectedFilter).toList()
        : patients;

    return Column(
      children: [
        // Interactive risk summary bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: _InteractiveRiskSummary(
            stats: stats,
            selectedFilter: selectedFilter,
            onFilterChanged: onFilterChanged,
          ),
        ).animate().fadeIn(duration: 300.ms),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SearchBarWidget(
            hintText: 'Search patients...',
            onChanged: (query) {
              ref.read(patientSearchQueryProvider.notifier).state = query;
            },
          ),
        ),

        // Filter chip
        if (selectedFilter != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Chip(
              label: Text('Showing ${selectedFilter!.displayName} patients'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => onFilterChanged(null),
              backgroundColor: selectedFilter!.backgroundColor,
              side: BorderSide(color: selectedFilter!.color),
            ),
          ),

        // Patient list
        Expanded(
          child: filteredPatients.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredPatients.length,
                  itemBuilder: (context, index) {
                    final patient = filteredPatients[index];
                    return PatientCard(
                      patient: patient,
                      onTap: () => _openPatientDetail(context, ref, patient),
                    ).animate().fadeIn(
                          delay: Duration(milliseconds: 30 * index),
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

/// Interactive Risk Summary
class _InteractiveRiskSummary extends StatelessWidget {
  final DashboardStats stats;
  final RiskLevel? selectedFilter;
  final ValueChanged<RiskLevel?> onFilterChanged;

  const _InteractiveRiskSummary({
    required this.stats,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RiskTile(
          level: RiskLevel.red,
          count: stats.redPatients,
          isSelected: selectedFilter == RiskLevel.red,
          onTap: () => onFilterChanged(
            selectedFilter == RiskLevel.red ? null : RiskLevel.red,
          ),
        ),
        const SizedBox(width: 8),
        _RiskTile(
          level: RiskLevel.orange,
          count: stats.orangePatients,
          isSelected: selectedFilter == RiskLevel.orange,
          onTap: () => onFilterChanged(
            selectedFilter == RiskLevel.orange ? null : RiskLevel.orange,
          ),
        ),
        const SizedBox(width: 8),
        _RiskTile(
          level: RiskLevel.yellow,
          count: stats.yellowPatients,
          isSelected: selectedFilter == RiskLevel.yellow,
          onTap: () => onFilterChanged(
            selectedFilter == RiskLevel.yellow ? null : RiskLevel.yellow,
          ),
        ),
        const SizedBox(width: 8),
        _RiskTile(
          level: RiskLevel.green,
          count: stats.greenPatients,
          isSelected: selectedFilter == RiskLevel.green,
          onTap: () => onFilterChanged(
            selectedFilter == RiskLevel.green ? null : RiskLevel.green,
          ),
        ),
      ],
    );
  }
}

class _RiskTile extends StatelessWidget {
  final RiskLevel level;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _RiskTile({
    required this.level,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: level.color, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? level.backgroundColor : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: level.color,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  level.shortLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Critical Patients Tab
class _CriticalPatientsTab extends ConsumerWidget {
  const _CriticalPatientsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final redPatients = ref.watch(patientsByRiskProvider(RiskLevel.red));
    final orangePatients = ref.watch(patientsByRiskProvider(RiskLevel.orange));
    ref.watch(refreshNotifierProvider);

    final criticalPatients = [...redPatients, ...orangePatients];

    if (criticalPatients.isEmpty) {
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
              'No critical patients',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'All patients are stable or under routine monitoring',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: criticalPatients.length,
      itemBuilder: (context, index) {
        final patient = criticalPatients[index];
        final alerts = ref.watch(activePatientAlertsProvider(patient.id));
        final analysis = ref.watch(patientAnalysisProvider(patient.id));

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: patient.currentRiskLevel.color, width: 2),
          ),
          child: InkWell(
            onTap: () {
              ref.read(selectedPatientIdProvider.notifier).state = patient.id;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      PatientDetailScreen(patientId: patient.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: patient.currentRiskLevel.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            patient.currentRiskLevel.icon,
                            color: patient.currentRiskLevel.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${patient.bedDisplay} • ${patient.ageDisplay} • ${patient.genderDisplay}',
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
                          color: patient.currentRiskLevel.color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          patient.currentRiskLevel.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Analysis summary
                  Text(
                    'Analysis Summary',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    analysis.summary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  if (analysis.hasSepsisPattern) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: RiskLevel.red.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: RiskLevel.red.color),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: RiskLevel.red.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sepsis pattern detected',
                              style: TextStyle(
                                color: RiskLevel.red.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (alerts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Active Alerts (${alerts.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...alerts.take(2).map(
                          (alert) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: alert.riskLevel.color,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    alert.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],

                  const SizedBox(height: 12),

                  // View details button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(selectedPatientIdProvider.notifier).state =
                            patient.id;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                PatientDetailScreen(patientId: patient.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('View Full Details'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(
              delay: Duration(milliseconds: 100 * index),
              duration: 300.ms,
            );
      },
    );
  }
}

/// Analytics Tab
class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    ref.watch(refreshNotifierProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ward Statistics',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Summary cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Patients',
                  value: stats.totalPatients.toString(),
                  icon: Icons.people,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Active Alerts',
                  value: stats.activeAlerts.toString(),
                  icon: Icons.notifications_active,
                  color: AppColors.warning,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Critical (Red)',
                  value: stats.redPatients.toString(),
                  icon: Icons.warning,
                  color: RiskLevel.red.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Needs Review',
                  value: stats.orangePatients.toString(),
                  icon: Icons.visibility,
                  color: RiskLevel.orange.color,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          // Risk distribution
          Text(
            'Risk Distribution',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _RiskDistributionBar(stats: stats).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 24),

          // Guidelines reminder
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Clinical Guidelines',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _GuidelineItem(
                    level: RiskLevel.red,
                    text: 'Immediate escalation required',
                  ),
                  _GuidelineItem(
                    level: RiskLevel.orange,
                    text: 'Notify doctor within 30 minutes',
                  ),
                  _GuidelineItem(
                    level: RiskLevel.yellow,
                    text: 'Increase monitoring frequency',
                  ),
                  _GuidelineItem(
                    level: RiskLevel.green,
                    text: 'Routine monitoring every 4-6 hours',
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskDistributionBar extends StatelessWidget {
  final DashboardStats stats;

  const _RiskDistributionBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.totalPatients;
    if (total == 0) {
      return const Center(child: Text('No patients'));
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              if (stats.redPatients > 0)
                Expanded(
                  flex: stats.redPatients,
                  child: Container(height: 24, color: RiskLevel.red.color),
                ),
              if (stats.orangePatients > 0)
                Expanded(
                  flex: stats.orangePatients,
                  child: Container(height: 24, color: RiskLevel.orange.color),
                ),
              if (stats.yellowPatients > 0)
                Expanded(
                  flex: stats.yellowPatients,
                  child: Container(height: 24, color: RiskLevel.yellow.color),
                ),
              if (stats.greenPatients > 0)
                Expanded(
                  flex: stats.greenPatients,
                  child: Container(height: 24, color: RiskLevel.green.color),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _LegendItem(level: RiskLevel.red, count: stats.redPatients),
            _LegendItem(level: RiskLevel.orange, count: stats.orangePatients),
            _LegendItem(level: RiskLevel.yellow, count: stats.yellowPatients),
            _LegendItem(level: RiskLevel.green, count: stats.greenPatients),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final RiskLevel level;
  final int count;

  const _LegendItem({required this.level, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: level.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text('$count', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _GuidelineItem extends StatelessWidget {
  final RiskLevel level;
  final String text;

  const _GuidelineItem({required this.level, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: level.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
