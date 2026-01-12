/// Input validators for vital signs and patient data
///
/// Provides validation functions for all user inputs with
/// clinical-appropriate error messages. Uses constants from
/// AppConstants to ensure consistency.

import '../constants/app_constants.dart';

class Validators {
  Validators._();

  // ═══════════════════════════════════════════════════════════════════════════
  // VITAL SIGN VALIDATORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validate heart rate input
  /// Returns null if valid, error message if invalid
  static String? validateHeartRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Heart rate is required';
    }

    final hr = int.tryParse(value.trim());
    if (hr == null) {
      return 'Enter a valid number';
    }

    if (hr < AppConstants.hrMin || hr > AppConstants.hrMax) {
      return 'Heart rate must be ${AppConstants.hrMin}-${AppConstants.hrMax} bpm';
    }

    return null;
  }

  /// Validate systolic blood pressure
  static String? validateSystolicBP(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Systolic BP is required';
    }

    final sbp = int.tryParse(value.trim());
    if (sbp == null) {
      return 'Enter a valid number';
    }

    if (sbp < AppConstants.sbpMin || sbp > AppConstants.sbpMax) {
      return 'Systolic BP must be ${AppConstants.sbpMin}-${AppConstants.sbpMax} mmHg';
    }

    return null;
  }

  /// Validate diastolic blood pressure
  static String? validateDiastolicBP(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Diastolic BP is required';
    }

    final dbp = int.tryParse(value.trim());
    if (dbp == null) {
      return 'Enter a valid number';
    }

    if (dbp < AppConstants.dbpMin || dbp > AppConstants.dbpMax) {
      return 'Diastolic BP must be ${AppConstants.dbpMin}-${AppConstants.dbpMax} mmHg';
    }

    return null;
  }

  /// Validate blood pressure relationship (systolic > diastolic)
  static String? validateBPRelationship(int systolic, int diastolic) {
    if (systolic <= diastolic) {
      return 'Systolic must be higher than diastolic';
    }

    final pulsePressure = systolic - diastolic;
    if (pulsePressure < 20) {
      return 'Pulse pressure seems too narrow. Please verify readings.';
    }

    return null;
  }

  /// Validate respiratory rate
  static String? validateRespiratoryRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Respiratory rate is required';
    }

    final rr = int.tryParse(value.trim());
    if (rr == null) {
      return 'Enter a valid number';
    }

    if (rr < AppConstants.rrMin || rr > AppConstants.rrMax) {
      return 'Respiratory rate must be ${AppConstants.rrMin}-${AppConstants.rrMax} /min';
    }

    return null;
  }

  /// Validate temperature
  static String? validateTemperature(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Temperature is required';
    }

    final temp = double.tryParse(value.trim());
    if (temp == null) {
      return 'Enter a valid number';
    }

    if (temp < AppConstants.tempMin || temp > AppConstants.tempMax) {
      return 'Temperature must be ${AppConstants.tempMin}-${AppConstants.tempMax}°C';
    }

    return null;
  }

  /// Validate SpO2
  static String? validateSpO2(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'SpO2 is required';
    }

    final spo2 = int.tryParse(value.trim());
    if (spo2 == null) {
      return 'Enter a valid number';
    }

    if (spo2 < AppConstants.spo2Min || spo2 > AppConstants.spo2Max) {
      return 'SpO2 must be ${AppConstants.spo2Min}-${AppConstants.spo2Max}%';
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PATIENT IDENTIFICATION VALIDATORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validate patient ID
  static String? validatePatientId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Patient ID is required';
    }

    if (value.trim().length < 2) {
      return 'Patient ID must be at least 2 characters';
    }

    if (value.trim().length > 20) {
      return 'Patient ID must be less than 20 characters';
    }

    return null;
  }

  /// Validate bed ID
  static String? validateBedId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bed ID is required';
    }

    if (value.trim().length > 10) {
      return 'Bed ID must be less than 10 characters';
    }

    return null;
  }

  /// Validate patient name
  static String? validatePatientName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Patient name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.trim().length > 100) {
      return 'Name must be less than 100 characters';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-'\.]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name contains invalid characters';
    }

    return null;
  }

  /// Validate age
  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }

    final age = int.tryParse(value.trim());
    if (age == null) {
      return 'Enter a valid number';
    }

    if (age < 0 || age > 150) {
      return 'Age must be 0-150 years';
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIMESTAMP VALIDATORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validate that timestamp is not in the future
  static String? validateTimestamp(DateTime? timestamp) {
    if (timestamp == null) {
      return 'Timestamp is required';
    }

    if (timestamp.isAfter(DateTime.now())) {
      return 'Timestamp cannot be in the future';
    }

    // Check if timestamp is too old (more than 24 hours)
    final maxAge = DateTime.now().subtract(const Duration(hours: 24));
    if (timestamp.isBefore(maxAge)) {
      return 'Timestamp is more than 24 hours old';
    }

    return null;
  }
}
