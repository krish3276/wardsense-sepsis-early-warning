/// Hive data model for VitalSigns
///
/// Hive-compatible model with type adapters for local persistence.
/// Maps to/from the domain VitalSigns entity.

import 'package:hive/hive.dart';
import '../../../domain/entities/vital_signs.dart';

part 'vital_signs_model.g.dart';

@HiveType(typeId: 1)
class VitalSignsModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String patientId;

  @HiveField(2)
  final int heartRate;

  @HiveField(3)
  final int systolicBP;

  @HiveField(4)
  final int diastolicBP;

  @HiveField(5)
  final int respiratoryRate;

  @HiveField(6)
  final double temperature;

  @HiveField(7)
  final int spO2;

  @HiveField(8)
  final DateTime timestamp;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final String? recordedBy;

  @HiveField(11)
  final String? notes;

  @HiveField(12)
  final bool isReviewed;

  @HiveField(13)
  final int? newsScore;

  @HiveField(14)
  final bool isOnSupplementalOxygen;

  @HiveField(15)
  final int consciousnessLevelIndex;

  VitalSignsModel({
    required this.id,
    required this.patientId,
    required this.heartRate,
    required this.systolicBP,
    required this.diastolicBP,
    required this.respiratoryRate,
    required this.temperature,
    required this.spO2,
    required this.timestamp,
    required this.createdAt,
    this.recordedBy,
    this.notes,
    this.isReviewed = false,
    this.newsScore,
    this.isOnSupplementalOxygen = false,
    this.consciousnessLevelIndex = 0, // Default to Alert
  });

  /// Convert from domain entity
  factory VitalSignsModel.fromEntity(VitalSigns vitals) {
    return VitalSignsModel(
      id: vitals.id,
      patientId: vitals.patientId,
      heartRate: vitals.heartRate,
      systolicBP: vitals.systolicBP,
      diastolicBP: vitals.diastolicBP,
      respiratoryRate: vitals.respiratoryRate,
      temperature: vitals.temperature,
      spO2: vitals.spO2,
      timestamp: vitals.timestamp,
      createdAt: vitals.createdAt,
      recordedBy: vitals.recordedBy,
      notes: vitals.notes,
      isReviewed: vitals.isReviewed,
      newsScore: vitals.newsScore,
      isOnSupplementalOxygen: vitals.isOnSupplementalOxygen,
      consciousnessLevelIndex: vitals.consciousnessLevel.index,
    );
  }

  /// Convert to domain entity
  VitalSigns toEntity() {
    return VitalSigns(
      id: id,
      patientId: patientId,
      heartRate: heartRate,
      systolicBP: systolicBP,
      diastolicBP: diastolicBP,
      respiratoryRate: respiratoryRate,
      temperature: temperature,
      spO2: spO2,
      timestamp: timestamp,
      createdAt: createdAt,
      recordedBy: recordedBy,
      notes: notes,
      isReviewed: isReviewed,
      newsScore: newsScore,
      isOnSupplementalOxygen: isOnSupplementalOxygen,
      consciousnessLevel: ConsciousnessLevel.values[consciousnessLevelIndex],
    );
  }
}
