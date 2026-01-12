/// Hive adapters registration
///
/// Registers all Hive type adapters for local data persistence.
/// Must be called before opening any Hive boxes.

import 'package:hive/hive.dart';
import '../../models/patient_model.dart';
import '../../models/vital_signs_model.dart';
import '../../models/alert_model.dart';
import '../../models/escalation_model.dart';

/// Register all Hive type adapters
///
/// This function should be called once during app initialization,
/// before opening any Hive boxes.
void registerHiveAdapters() {
  // Patient model adapter (typeId: 0)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PatientModelAdapter());
  }

  // VitalSigns model adapter (typeId: 1)
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(VitalSignsModelAdapter());
  }

  // Alert model adapter (typeId: 2)
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(AlertModelAdapter());
  }

  // AlertFactor model adapter (typeId: 3)
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(AlertFactorModelAdapter());
  }

  // Escalation model adapter (typeId: 4)
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(EscalationModelAdapter());
  }
}
