// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PatientModelAdapter extends TypeAdapter<PatientModel> {
  @override
  final int typeId = 0;

  @override
  PatientModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatientModel(
      id: fields[0] as String,
      bedId: fields[1] as String,
      name: fields[2] as String,
      age: fields[3] as int,
      gender: fields[4] as String,
      medicalRecordNumber: fields[5] as String?,
      admissionDate: fields[6] as DateTime,
      wardName: fields[7] as String,
      currentRiskLevelIndex: fields[8] as int,
      lastVitalsTime: fields[9] as DateTime?,
      isMonitored: fields[10] as bool,
      notes: fields[11] as String?,
      isActive: fields[12] as bool,
      // Handle migration from old data without comorbidity fields
      comorbidityTypeIndices: (fields[13] as List?)?.cast<int>() ?? const [],
      comorbiditySeverityIndices:
          (fields[14] as List?)?.cast<int>() ?? const [],
    );
  }

  @override
  void write(BinaryWriter writer, PatientModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bedId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.age)
      ..writeByte(4)
      ..write(obj.gender)
      ..writeByte(5)
      ..write(obj.medicalRecordNumber)
      ..writeByte(6)
      ..write(obj.admissionDate)
      ..writeByte(7)
      ..write(obj.wardName)
      ..writeByte(8)
      ..write(obj.currentRiskLevelIndex)
      ..writeByte(9)
      ..write(obj.lastVitalsTime)
      ..writeByte(10)
      ..write(obj.isMonitored)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.isActive)
      ..writeByte(13)
      ..write(obj.comorbidityTypeIndices)
      ..writeByte(14)
      ..write(obj.comorbiditySeverityIndices);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
