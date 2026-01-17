/// Vital Entry Screen
///
/// Form for entering vital signs with validation and helpful guidance.
/// Designed for quick, accurate data entry by nurses.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/risk_level.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/patient.dart';
import '../../../domain/entities/vital_signs.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../data/repositories/vital_signs_repository.dart';
import '../../../domain/services/trend_analysis_engine.dart';
import '../../../data/repositories/alert_repository.dart';
import '../../providers/providers.dart';

class VitalEntryScreen extends ConsumerStatefulWidget {
  final String? preselectedPatientId;

  const VitalEntryScreen({super.key, this.preselectedPatientId});

  @override
  ConsumerState<VitalEntryScreen> createState() => _VitalEntryScreenState();
}

class _VitalEntryScreenState extends ConsumerState<VitalEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  static const _uuid = Uuid();

  // Controllers
  final _heartRateController = TextEditingController();
  final _systolicBPController = TextEditingController();
  final _diastolicBPController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _notesController = TextEditingController();

  // State
  Patient? _selectedPatient;
  DateTime _selectedTime = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPatientId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final patient = ref.read(patientProvider(widget.preselectedPatientId!));
        if (patient != null) {
          setState(() => _selectedPatient = patient);
        }
      });
    }
  }

  @override
  void dispose() {
    _heartRateController.dispose();
    _systolicBPController.dispose();
    _diastolicBPController.dispose();
    _respiratoryRateController.dispose();
    _temperatureController.dispose();
    _spo2Controller.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(patientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Vital Signs'),
        actions: [
          TextButton.icon(
            onPressed: _isSubmitting ? null : _clearForm,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Patient selection
            _buildPatientSelection(patients),
            const SizedBox(height: 24),

            // Timestamp
            _buildTimestampSection(),
            const SizedBox(height: 24),

            // Vital signs inputs
            Text(
              'Vital Signs',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Heart Rate and SpO2
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _VitalInputField(
                    controller: _heartRateController,
                    label: 'Heart Rate',
                    unit: 'bpm',
                    icon: Icons.favorite,
                    hint: '60-100',
                    validator: Validators.validateHeartRate,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _VitalInputField(
                    controller: _spo2Controller,
                    label: 'SpO₂',
                    unit: '%',
                    icon: Icons.air,
                    hint: '95-100',
                    validator: Validators.validateSpO2,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Blood Pressure
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _VitalInputField(
                    controller: _systolicBPController,
                    label: 'Systolic BP',
                    unit: 'mmHg',
                    icon: Icons.arrow_upward,
                    hint: '100-140',
                    validator: Validators.validateSystolicBP,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _VitalInputField(
                    controller: _diastolicBPController,
                    label: 'Diastolic BP',
                    unit: 'mmHg',
                    icon: Icons.arrow_downward,
                    hint: '60-90',
                    validator: Validators.validateDiastolicBP,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Respiratory Rate and Temperature
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _VitalInputField(
                    controller: _respiratoryRateController,
                    label: 'Respiratory Rate',
                    unit: '/min',
                    icon: Icons.waves,
                    hint: '12-20',
                    validator: Validators.validateRespiratoryRate,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _VitalInputField(
                    controller: _temperatureController,
                    label: 'Temperature',
                    unit: '°C',
                    icon: Icons.thermostat,
                    hint: '36.0-37.5',
                    validator: Validators.validateTemperature,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any additional observations...',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Submit button
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submitVitals,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSubmitting ? 'Saving...' : 'Save Vital Signs'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 16),

            // Normal ranges reference
            _buildNormalRangesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelection(List<Patient> patients) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Patient',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Patient>(
              value: _selectedPatient,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person),
                hintText: 'Choose a patient',
              ),
              items: patients.map((patient) {
                return DropdownMenuItem(
                  value: patient,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: patient.currentRiskLevel.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${patient.bedDisplay} - ${patient.name}'),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (patient) {
                setState(() => _selectedPatient = patient);
              },
              validator: (value) {
                if (value == null) return 'Please select a patient';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Measurement Time',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${_selectedTime.day}/${_selectedTime.month}/${_selectedTime.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() => _selectedTime = DateTime.now());
              },
              icon: const Icon(Icons.update, size: 16),
              label: const Text('Use current time'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalRangesCard() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Normal Ranges',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _NormalRangeChip(label: 'HR', range: '60-100 bpm'),
                _NormalRangeChip(label: 'BP', range: '90-140/60-90 mmHg'),
                _NormalRangeChip(label: 'RR', range: '12-20 /min'),
                _NormalRangeChip(label: 'Temp', range: '36.1-37.2 °C'),
                _NormalRangeChip(label: 'SpO₂', range: '≥95%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedTime = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );
    if (time != null) {
      setState(() {
        _selectedTime = DateTime(
          _selectedTime.year,
          _selectedTime.month,
          _selectedTime.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  void _clearForm() {
    _heartRateController.clear();
    _systolicBPController.clear();
    _diastolicBPController.clear();
    _respiratoryRateController.clear();
    _temperatureController.clear();
    _spo2Controller.clear();
    _notesController.clear();
    setState(() {
      _selectedPatient = null;
      _selectedTime = DateTime.now();
    });
  }

  Future<void> _submitVitals() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate BP relationship
    final sbp = int.parse(_systolicBPController.text);
    final dbp = int.parse(_diastolicBPController.text);
    final bpError = Validators.validateBPRelationship(sbp, dbp);
    if (bpError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bpError), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Create vital signs entity (without NEWS score first to calculate it)
      final vitalsWithoutScore = VitalSigns(
        id: _uuid.v4(),
        patientId: _selectedPatient!.id,
        heartRate: int.parse(_heartRateController.text),
        systolicBP: sbp,
        diastolicBP: dbp,
        respiratoryRate: int.parse(_respiratoryRateController.text),
        temperature: double.parse(_temperatureController.text),
        spO2: int.parse(_spo2Controller.text),
        timestamp: _selectedTime,
        createdAt: DateTime.now(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Calculate NEWS score and create final vitals with score
      final newsScore =
          TrendAnalysisEngine.calculateNewsScore(vitalsWithoutScore);
      final vitals = vitalsWithoutScore.copyWith(newsScore: newsScore);

      // Save vitals
      await ref.read(vitalSignsRepositoryProvider).addVitalSigns(vitals);

      // Run trend analysis
      final analysis = ref
          .read(trendAnalysisEngineProvider)
          .analyzePatient(_selectedPatient!.id);

      // Update patient risk level
      await ref.read(patientRepositoryProvider).updatePatientRiskLevel(
            _selectedPatient!.id,
            analysis.riskLevel,
            _selectedTime,
          );

      // Create alert if needed
      final alert = ref
          .read(trendAnalysisEngineProvider)
          .createAlertFromAnalysis(analysis);
      if (alert != null) {
        await ref.read(alertRepositoryProvider).addAlert(alert);
      }

      // Refresh data
      refreshAllData(ref);

      // Show success message with risk level
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vitals saved. Risk level: ${analysis.riskLevel.displayName}',
                  ),
                ),
              ],
            ),
            backgroundColor: analysis.riskLevel.color,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving vitals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

/// Custom vital input field widget
class _VitalInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final IconData icon;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _VitalInputField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.icon,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixText: unit,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }
}

/// Normal range chip
class _NormalRangeChip extends StatelessWidget {
  final String label;
  final String range;

  const _NormalRangeChip({required this.label, required this.range});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Text(
        '$label: $range',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
