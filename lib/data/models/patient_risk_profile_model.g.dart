// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_risk_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ComorbidityModelAdapter extends TypeAdapter<ComorbidityModel> {
  @override
  final int typeId = 10;

  @override
  ComorbidityModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ComorbidityModel(
      typeIndex: fields[0] as int,
      severity: fields[1] as String?,
      diagnosedDate: fields[2] as DateTime?,
      notes: fields[3] as String?,
      isActive: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ComorbidityModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.typeIndex)
      ..writeByte(1)
      ..write(obj.severity)
      ..writeByte(2)
      ..write(obj.diagnosedDate)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComorbidityModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PatientRiskProfileModelAdapter
    extends TypeAdapter<PatientRiskProfileModel> {
  @override
  final int typeId = 11;

  @override
  PatientRiskProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatientRiskProfileModel(
      patientId: fields[0] as String,
      age: fields[1] as int,
      comorbidities: (fields[2] as List).cast<ComorbidityModel>(),
      hasRecentSurgery: fields[3] as bool,
      hasRecentHospitalization: fields[4] as bool,
      hasIndwellingDevices: fields[5] as bool,
      allergies: (fields[6] as List).cast<String>(),
      lastUpdated: fields[7] as DateTime,
      notes: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PatientRiskProfileModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.patientId)
      ..writeByte(1)
      ..write(obj.age)
      ..writeByte(2)
      ..write(obj.comorbidities)
      ..writeByte(3)
      ..write(obj.hasRecentSurgery)
      ..writeByte(4)
      ..write(obj.hasRecentHospitalization)
      ..writeByte(5)
      ..write(obj.hasIndwellingDevices)
      ..writeByte(6)
      ..write(obj.allergies)
      ..writeByte(7)
      ..write(obj.lastUpdated)
      ..writeByte(8)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientRiskProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
