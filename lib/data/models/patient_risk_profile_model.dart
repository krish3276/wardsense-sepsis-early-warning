/// Hive data model for PatientRiskProfile
///
/// Hive-compatible model for local persistence of patient risk profiles.

import 'package:hive/hive.dart';
import '../../domain/entities/patient_risk_profile.dart';
import '../../domain/entities/comorbidity.dart';

part 'patient_risk_profile_model.g.dart';

@HiveType(typeId: 10)
class ComorbidityModel extends HiveObject {
  @HiveField(0)
  final int typeIndex;

  @HiveField(1)
  final String? severity;

  @HiveField(2)
  final DateTime? diagnosedDate;

  @HiveField(3)
  final String? notes;

  @HiveField(4)
  final bool isActive;

  ComorbidityModel({
    required this.typeIndex,
    this.severity,
    this.diagnosedDate,
    this.notes,
    this.isActive = true,
  });

  factory ComorbidityModel.fromEntity(Comorbidity comorbidity) {
    return ComorbidityModel(
      typeIndex: comorbidity.type.index,
      severity: comorbidity.severity,
      diagnosedDate: comorbidity.diagnosedDate,
      notes: comorbidity.notes,
      isActive: comorbidity.isActive,
    );
  }

  Comorbidity toEntity() {
    return Comorbidity(
      type: ComorbidityType.values[typeIndex],
      severity: severity,
      diagnosedDate: diagnosedDate,
      notes: notes,
      isActive: isActive,
    );
  }
}

@HiveType(typeId: 11)
class PatientRiskProfileModel extends HiveObject {
  @HiveField(0)
  final String patientId;

  @HiveField(1)
  final int age;

  @HiveField(2)
  final List<ComorbidityModel> comorbidities;

  @HiveField(3)
  final bool hasRecentSurgery;

  @HiveField(4)
  final bool hasRecentHospitalization;

  @HiveField(5)
  final bool hasIndwellingDevices;

  @HiveField(6)
  final List<String> allergies;

  @HiveField(7)
  final DateTime lastUpdated;

  @HiveField(8)
  final String? notes;

  PatientRiskProfileModel({
    required this.patientId,
    required this.age,
    required this.comorbidities,
    this.hasRecentSurgery = false,
    this.hasRecentHospitalization = false,
    this.hasIndwellingDevices = false,
    this.allergies = const [],
    required this.lastUpdated,
    this.notes,
  });

  factory PatientRiskProfileModel.fromEntity(PatientRiskProfile profile) {
    return PatientRiskProfileModel(
      patientId: profile.patientId,
      age: profile.age,
      comorbidities: profile.comorbidities
          .map((c) => ComorbidityModel.fromEntity(c))
          .toList(),
      hasRecentSurgery: profile.hasRecentSurgery,
      hasRecentHospitalization: profile.hasRecentHospitalization,
      hasIndwellingDevices: profile.hasIndwellingDevices,
      allergies: profile.allergies,
      lastUpdated: profile.lastUpdated,
      notes: profile.notes,
    );
  }

  PatientRiskProfile toEntity() {
    return PatientRiskProfile(
      patientId: patientId,
      age: age,
      comorbidities: comorbidities.map((c) => c.toEntity()).toList(),
      hasRecentSurgery: hasRecentSurgery,
      hasRecentHospitalization: hasRecentHospitalization,
      hasIndwellingDevices: hasIndwellingDevices,
      allergies: allergies,
      lastUpdated: lastUpdated,
      notes: notes,
    );
  }
}
