/// Patient Detail Screen
///
/// Comprehensive view of a patient's status, vital signs history,
/// trend analysis, and escalation guidance.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/risk_level.dart';
import '../../../core/utils/app_utils.dart';
import '../../../domain/entities/patient.dart';
import '../../../domain/entities/vital_signs.dart';
import '../../../domain/entities/alert.dart';
import '../../../domain/entities/ai_prediction.dart';
import '../../../domain/services/trend_analysis_engine.dart';
import '../../../domain/services/safety_net_service.dart';
import '../../providers/providers.dart';
import '../../widgets/risk_profile_badge.dart';
import '../../widgets/velocity_display.dart';
import '../../widgets/escalation_prompt_card.dart';
import '../../widgets/safety_net_display.dart';
import '../../widgets/ai_insights_card.dart';
import '../vitals/vital_entry_screen.dart';

class PatientDetailScreen extends ConsumerWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ref.watch(patientProvider(patientId));
    if (patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Not Found')),
        body: const Center(child: Text('Patient not found')),
      );
    }

    final vitals = ref.watch(vitalSignsProvider(patientId));
    final alerts = ref.watch(patientAlertsProvider(patientId));
    final analysis = ref.watch(patientAnalysisProvider(patientId));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with patient info
          SliverAppBar.large(
            pinned: true,
            backgroundColor: patient.currentRiskLevel.color.withOpacity(0.9),
            foregroundColor: Colors.white,
            title: Text(patient.name),
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      patient.currentRiskLevel.color,
                      patient.currentRiskLevel.color.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                patient.bedDisplay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (patient.medicalRecordNumber != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'MRN: ${patient.medicalRecordNumber}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${patient.age} years old • ${patient.gender}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // NEW FEATURE 1: Risk Profile Badge with Comorbidities
          // ═══════════════════════════════════════════════════════════════════
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: RiskProfileBadge(
                riskProfile: patient.riskProfile,
                showDetails: true,
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // AI/ML SEPSIS PREDICTION - THE KILLER FEATURE
          // ═══════════════════════════════════════════════════════════════════
          SliverToBoxAdapter(
            child: _AIInsightsSection(patientId: patientId),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // NEW FEATURE 2: Vital Trend Velocity Analysis
          // ═══════════════════════════════════════════════════════════════════
          SliverToBoxAdapter(
            child: _VelocitySection(patientId: patientId),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // NEW FEATURE 3: Context-Aware Escalation Prompts
          // ═══════════════════════════════════════════════════════════════════
          SliverToBoxAdapter(
            child: _EscalationPromptSection(patientId: patientId),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // NEW FEATURE 4: Safety Net Status
          // ═══════════════════════════════════════════════════════════════════
          SliverToBoxAdapter(
            child: _SafetyNetSection(patientId: patientId),
          ),

          // Risk status card
          SliverToBoxAdapter(
            child: _RiskStatusCard(patient: patient, analysis: analysis),
          ),

          // Latest vitals
          if (vitals.isNotEmpty)
            SliverToBoxAdapter(child: _LatestVitalsCard(vitals: vitals.first)),

          // Trend charts
          if (vitals.length >= 2)
            SliverToBoxAdapter(child: _TrendChartsCard(vitals: vitals)),

          // Escalation guidance (if elevated risk)
          if (patient.currentRiskLevel.index >= RiskLevel.orange.index)
            SliverToBoxAdapter(
              child: _EscalationGuidanceCard(
                riskLevel: patient.currentRiskLevel,
                analysis: analysis,
              ),
            ),

          // Recent alerts
          if (alerts.isNotEmpty)
            SliverToBoxAdapter(
              child: _RecentAlertsCard(alerts: alerts.take(5).toList()),
            ),

          // Vital signs history
          SliverToBoxAdapter(child: _VitalHistoryCard(vitals: vitals)),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VitalEntryScreen(preselectedPatientId: patientId),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Vitals'),
      ),
    );
  }
}

class _RiskStatusCard extends StatelessWidget {
  final Patient patient;
  final PatientAnalysisResult? analysis;

  const _RiskStatusCard({required this.patient, this.analysis});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: patient.currentRiskLevel.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    patient.currentRiskLevel.icon,
                    color: patient.currentRiskLevel.color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Risk Level: ${patient.currentRiskLevel.displayName}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: patient.currentRiskLevel.color,
                                ),
                      ),
                      if (patient.lastVitalsTime != null)
                        Text(
                          'Last vitals: ${AppUtils.formatRelativeTime(patient.lastVitalsTime!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (analysis != null) ...[
              const Divider(height: 24),
              Text(
                'Analysis Summary',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                analysis!.summary,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (analysis!.recommendedActions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: analysis!.recommendedActions.take(3).map((action) {
                    return Chip(
                      avatar: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(action, style: const TextStyle(fontSize: 12)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _LatestVitalsCard extends StatelessWidget {
  final VitalSigns vitals;

  const _LatestVitalsCard({required this.vitals});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latest Vitals',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  AppUtils.formatRelativeTime(vitals.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _VitalTile(
                  label: 'HR',
                  value: '${vitals.heartRate}',
                  unit: 'bpm',
                  icon: Icons.favorite,
                  color: Colors.red,
                ),
                _VitalTile(
                  label: 'BP',
                  value: '${vitals.systolicBP}/${vitals.diastolicBP}',
                  unit: 'mmHg',
                  icon: Icons.speed,
                  color: Colors.blue,
                ),
                _VitalTile(
                  label: 'RR',
                  value: '${vitals.respiratoryRate}',
                  unit: '/min',
                  icon: Icons.waves,
                  color: Colors.teal,
                ),
                _VitalTile(
                  label: 'Temp',
                  value: vitals.temperature.toStringAsFixed(1),
                  unit: '°C',
                  icon: Icons.thermostat,
                  color: Colors.orange,
                ),
                _VitalTile(
                  label: 'SpO₂',
                  value: '${vitals.spO2}',
                  unit: '%',
                  icon: Icons.air,
                  color: Colors.indigo,
                ),
                _VitalTile(
                  label: 'NEWS',
                  value: '${vitals.newsScore ?? 0}',
                  unit: '',
                  icon: Icons.analytics,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _VitalTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            '$label $unit',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TrendChartsCard extends StatelessWidget {
  final List<VitalSigns> vitals;

  const _TrendChartsCard({required this.vitals});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vital Trends (Last ${vitals.length} readings)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildTrendChart(context),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: Colors.red, label: 'HR'),
                const SizedBox(width: 16),
                _LegendItem(color: Colors.blue, label: 'SBP'),
                const SizedBox(width: 16),
                _LegendItem(color: Colors.teal, label: 'RR'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context) {
    final displayVitals = vitals.take(10).toList().reversed.toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < displayVitals.length) {
                  final time = displayVitals[idx].timestamp;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 160,
        lineBarsData: [
          // Heart Rate
          LineChartBarData(
            spots: displayVitals.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.heartRate.toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.red,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.red,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
          // Systolic BP
          LineChartBarData(
            spots: displayVitals.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.systolicBP.toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.blue,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
          // Respiratory Rate (scaled up for visibility)
          LineChartBarData(
            spots: displayVitals.asMap().entries.map((e) {
              return FlSpot(
                  e.key.toDouble(), (e.value.respiratoryRate * 3).toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.teal,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.teal,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _EscalationGuidanceCard extends StatelessWidget {
  final RiskLevel riskLevel;
  final PatientAnalysisResult? analysis;

  const _EscalationGuidanceCard({
    required this.riskLevel,
    this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: riskLevel.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: riskLevel.color),
                const SizedBox(width: 8),
                Text(
                  'Escalation Guidance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: riskLevel.color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              riskLevel.clinicalAction,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Divider(height: 24),
            Text(
              'Recommended Actions:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ..._getRecommendedActions().map((action) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 18, color: riskLevel.color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(action)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<String> _getRecommendedActions() {
    if (riskLevel == RiskLevel.red) {
      return [
        'Immediate senior clinician review',
        'Consider ICU/HDU transfer',
        'Continuous monitoring if available',
        'Obtain blood cultures if sepsis suspected',
        'Initiate Sepsis 6 bundle if indicated',
        'Document escalation decision',
      ];
    } else if (riskLevel == RiskLevel.orange) {
      return [
        'Increase monitoring frequency to every 30-60 minutes',
        'Contact senior nurse or registrar',
        'Review medications and fluid balance',
        'Consider blood tests (FBC, CRP, Lactate)',
        'Prepare for potential escalation',
      ];
    }
    return [
      'Continue routine monitoring',
      'Watch for changes in condition',
    ];
  }
}

class _RecentAlertsCard extends StatelessWidget {
  final List<Alert> alerts;

  const _RecentAlertsCard({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Alerts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...alerts.map((alert) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
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
                title: Text(
                  alert.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  AppUtils.formatRelativeTime(alert.timestamp),
                ),
                trailing: alert.isAcknowledged
                    ? Icon(Icons.check_circle, color: Colors.green.shade400)
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _VitalHistoryCard extends StatelessWidget {
  final List<VitalSigns> vitals;

  const _VitalHistoryCard({required this.vitals});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vital Signs History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (vitals.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No vital signs recorded yet'),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('HR'), numeric: true),
                    DataColumn(label: Text('BP')),
                    DataColumn(label: Text('RR'), numeric: true),
                    DataColumn(label: Text('Temp'), numeric: true),
                    DataColumn(label: Text('SpO₂'), numeric: true),
                    DataColumn(label: Text('NEWS'), numeric: true),
                  ],
                  rows: vitals.take(10).map((v) {
                    final newsScore = v.newsScore ?? 0;
                    return DataRow(cells: [
                      DataCell(Text(AppUtils.formatTime(v.timestamp))),
                      DataCell(Text('${v.heartRate}')),
                      DataCell(Text('${v.systolicBP}/${v.diastolicBP}')),
                      DataCell(Text('${v.respiratoryRate}')),
                      DataCell(Text(v.temperature.toStringAsFixed(1))),
                      DataCell(Text('${v.spO2}')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getNewsColor(newsScore).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$newsScore',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getNewsColor(newsScore),
                            ),
                          ),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getNewsColor(int score) {
    if (score >= 7) return RiskLevel.red.color;
    if (score >= 5) return RiskLevel.orange.color;
    if (score >= 3) return RiskLevel.yellow.color;
    return RiskLevel.green.color;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AI/ML SEPSIS PREDICTION SECTION - KILLER FEATURE
// ═══════════════════════════════════════════════════════════════════════════

/// AI Insights Section - Shows ML-powered sepsis prediction
class _AIInsightsSection extends ConsumerWidget {
  final String patientId;

  const _AIInsightsSection({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prediction = ref.watch(sepsisPredictionProvider(patientId));

    if (prediction == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AIInsightsCard(
        prediction: prediction,
        onViewDetails: () {
          _showAIDetailsDialog(context, ref, prediction);
        },
      ),
    );
  }

  void _showAIDetailsDialog(
    BuildContext context,
    WidgetRef ref,
    SepsisPrediction prediction,
  ) {
    final qsofa = ref.read(qsofaProvider(patientId));
    final modelInfo = ref.read(aiModelInfoProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A237E), Color(0xFF7C4DFF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Analysis Details',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Powered by ${modelInfo.name}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Model info
                    _buildModelInfoCard(context, modelInfo),
                    const SizedBox(height: 16),
                    // qSOFA details
                    if (qsofa != null) ...[
                      QSofaDisplay(qsofa: qsofa),
                      const SizedBox(height: 16),
                    ],
                    // All risk factors
                    _buildAllRiskFactors(context, prediction),
                    const SizedBox(height: 16),
                    // All anomalies
                    if (prediction.anomalies.isNotEmpty)
                      _buildAllAnomalies(context, prediction),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelInfoCard(BuildContext context, AIModelInfo info) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_toy, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Model Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Model', info.name),
            _buildInfoRow(context, 'Version', info.version),
            _buildInfoRow(context, 'Type', info.type),
            _buildInfoRow(
              context,
              'Accuracy',
              '${(info.accuracy * 100).toStringAsFixed(1)}%',
            ),
            _buildInfoRow(
              context,
              'Sensitivity',
              '${(info.sensitivity * 100).toStringAsFixed(1)}%',
            ),
            _buildInfoRow(
              context,
              'Specificity',
              '${(info.specificity * 100).toStringAsFixed(1)}%',
            ),
            _buildInfoRow(
              context,
              'Training Data',
              '${info.trainingDataSize.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} patients',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllRiskFactors(
      BuildContext context, SepsisPrediction prediction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, size: 20),
                const SizedBox(width: 8),
                Text(
                  'All Risk Factors',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...prediction.topRiskFactors.map((factor) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              factor.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: factor.isAbnormal
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              factor.currentValue,
                              style: TextStyle(
                                fontSize: 12,
                                color: factor.isAbnormal
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        factor.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: factor.importance,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            factor.importance >= 0.5
                                ? Colors.red
                                : Colors.orange,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAllAnomalies(BuildContext context, SepsisPrediction prediction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber,
                    size: 20, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Detected Anomalies',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...prediction.anomalies.map((anomaly) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: anomaly.severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: anomaly.severityColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        anomaly.type.icon,
                        color: anomaly.severityColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              anomaly.vitalName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              anomaly.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${anomaly.type.displayName} • ${anomaly.trend}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: anomaly.severityColor,
                                  ),
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
                          color: anomaly.severityColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(anomaly.severity * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NEW FEATURE SECTION WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Velocity Analysis Section - Shows vital trend velocity
class _VelocitySection extends ConsumerWidget {
  final String patientId;

  const _VelocitySection({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final velocityResult = ref.watch(patientVelocityProvider(patientId));

    // Show if we have any velocity data (even stable)
    if (velocityResult == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: VelocityAnalysisCard(
        result: velocityResult,
        onTap: () {
          if (velocityResult.concerningVelocities.isNotEmpty) {
            showDialog(
              context: context,
              builder: (context) => VelocityDetailDialog(
                velocity: velocityResult.concerningVelocities.first,
              ),
            );
          }
        },
      ),
    );
  }
}

/// Escalation Prompt Section - Shows context-aware clinical prompts
class _EscalationPromptSection extends ConsumerWidget {
  final String patientId;

  const _EscalationPromptSection({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompt = ref.watch(patientEscalationPromptProvider(patientId));
    final isAcknowledged = ref.watch(isPromptAcknowledgedProvider(patientId));

    if (prompt == null || isAcknowledged) {
      return const SizedBox.shrink();
    }

    void acknowledgePrompt() {
      ref.read(acknowledgedPromptsProvider.notifier).acknowledge(patientId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Escalation acknowledged at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () {
              ref.read(acknowledgedPromptsProvider.notifier).clear(patientId);
            },
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: EscalationPromptCard(
        prompt: prompt,
        onAcknowledge: acknowledgePrompt,
        onViewDetails: () {
          // Show detailed escalation prompt dialog
          showDialog(
            context: context,
            builder: (context) => EscalationPromptDetailDialog(
              prompt: prompt,
              onAcknowledge: acknowledgePrompt,
            ),
          );
        },
      ),
    );
  }
}

/// Safety Net Section - Shows escalation tracking status
class _SafetyNetSection extends ConsumerWidget {
  final String patientId;

  const _SafetyNetSection({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(patientSafetyNetProvider(patientId));

    if (tracker == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: EscalationTrackerCard(
        tracker: tracker,
        onAcknowledge: () {
          // Acknowledge the tracker using the safety net service
          final safetyNetService = ref.read(safetyNetServiceProvider);
          final updated = safetyNetService.acknowledge(
            trackerId: tracker.id,
            acknowledgedBy: 'Current User', // In a real app, get from auth
          );

          if (updated != null) {
            // Refresh data to reflect the change
            refreshAllData(ref);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Escalation acknowledged at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        onRecordAction: () {
          // Show dialog to record action
          _showRecordActionDialog(context, ref, tracker.id);
        },
        onResolve: () {
          // Resolve the tracker using the safety net service
          final safetyNetService = ref.read(safetyNetServiceProvider);
          final updated = safetyNetService.resolve(
            trackerId: tracker.id,
            resolutionNotes: 'Resolved via patient detail screen',
          );

          if (updated != null) {
            // Refresh data to reflect the change
            refreshAllData(ref);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Escalation resolved successfully'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        },
      ),
    );
  }

  void _showRecordActionDialog(
      BuildContext context, WidgetRef ref, String trackerId) {
    final actionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: Colors.blue),
            SizedBox(width: 8),
            Text('Record Action'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Document the clinical action taken for this patient:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: actionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'e.g., Administered IV fluids, called senior doctor, started antibiotics...',
                border: OutlineInputBorder(),
                labelText: 'Action Description',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (actionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter an action description'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final safetyNetService = ref.read(safetyNetServiceProvider);
              final updated = safetyNetService.recordAction(
                trackerId: trackerId,
                actionTakenBy: 'Current User',
                actionDescription: actionController.text.trim(),
              );

              Navigator.pop(context);

              if (updated != null) {
                refreshAllData(ref);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Action documented: ${actionController.text.trim()}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Action'),
          ),
        ],
      ),
    );
  }
}
