// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vital_signs_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VitalSignsModelAdapter extends TypeAdapter<VitalSignsModel> {
  @override
  final int typeId = 1;

  @override
  VitalSignsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VitalSignsModel(
      id: fields[0] as String,
      patientId: fields[1] as String,
      heartRate: fields[2] as int,
      systolicBP: fields[3] as int,
      diastolicBP: fields[4] as int,
      respiratoryRate: fields[5] as int,
      temperature: fields[6] as double,
      spO2: fields[7] as int,
      timestamp: fields[8] as DateTime,
      createdAt: fields[9] as DateTime,
      recordedBy: fields[10] as String?,
      notes: fields[11] as String?,
      isReviewed: fields.containsKey(12) && fields[12] != null
          ? fields[12] as bool
          : false,
      newsScore: fields[13] as int?,
      isOnSupplementalOxygen: fields.containsKey(14) && fields[14] != null
          ? fields[14] as bool
          : false,
      consciousnessLevelIndex:
          fields.containsKey(15) && fields[15] != null ? fields[15] as int : 0,
    );
  }

  @override
  void write(BinaryWriter writer, VitalSignsModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.heartRate)
      ..writeByte(3)
      ..write(obj.systolicBP)
      ..writeByte(4)
      ..write(obj.diastolicBP)
      ..writeByte(5)
      ..write(obj.respiratoryRate)
      ..writeByte(6)
      ..write(obj.temperature)
      ..writeByte(7)
      ..write(obj.spO2)
      ..writeByte(8)
      ..write(obj.timestamp)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.recordedBy)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.isReviewed)
      ..writeByte(13)
      ..write(obj.newsScore)
      ..writeByte(14)
      ..write(obj.isOnSupplementalOxygen)
      ..writeByte(15)
      ..write(obj.consciousnessLevelIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VitalSignsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
