// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlertModelAdapter extends TypeAdapter<AlertModel> {
  @override
  final int typeId = 2;

  @override
  AlertModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlertModel(
      id: fields[0] as String,
      patientId: fields[1] as String,
      riskLevelIndex: fields[2] as int,
      title: fields[3] as String,
      description: fields[4] as String,
      factors: (fields[5] as List).cast<AlertFactorModel>(),
      recommendedActions: (fields[6] as List).cast<String>(),
      timestamp: fields[7] as DateTime,
      analysisWindowHours: fields[14] as int,
      isAcknowledged: fields[8] as bool,
      acknowledgedAt: fields[9] as DateTime?,
      acknowledgedBy: fields[10] as String?,
      acknowledgementNotes: fields[11] as String?,
      isEscalated: fields[12] as bool,
      triggeringVitalSignsId: fields[13] as String?,
      isActive: fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AlertModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.riskLevelIndex)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.factors)
      ..writeByte(6)
      ..write(obj.recommendedActions)
      ..writeByte(7)
      ..write(obj.timestamp)
      ..writeByte(8)
      ..write(obj.isAcknowledged)
      ..writeByte(9)
      ..write(obj.acknowledgedAt)
      ..writeByte(10)
      ..write(obj.acknowledgedBy)
      ..writeByte(11)
      ..write(obj.acknowledgementNotes)
      ..writeByte(12)
      ..write(obj.isEscalated)
      ..writeByte(13)
      ..write(obj.triggeringVitalSignsId)
      ..writeByte(14)
      ..write(obj.analysisWindowHours)
      ..writeByte(15)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlertFactorModelAdapter extends TypeAdapter<AlertFactorModel> {
  @override
  final int typeId = 3;

  @override
  AlertFactorModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlertFactorModel(
      vitalTypeIndex: fields[0] as int,
      directionIndex: fields[1] as int,
      currentValue: fields[2] as double,
      shortDescription: fields[6] as String,
      explanation: fields[7] as String,
      previousValue: fields[3] as double?,
      percentageChange: fields[4] as double?,
      rateOfChangePerHour: fields[5] as double?,
      isCritical: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AlertFactorModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.vitalTypeIndex)
      ..writeByte(1)
      ..write(obj.directionIndex)
      ..writeByte(2)
      ..write(obj.currentValue)
      ..writeByte(3)
      ..write(obj.previousValue)
      ..writeByte(4)
      ..write(obj.percentageChange)
      ..writeByte(5)
      ..write(obj.rateOfChangePerHour)
      ..writeByte(6)
      ..write(obj.shortDescription)
      ..writeByte(7)
      ..write(obj.explanation)
      ..writeByte(8)
      ..write(obj.isCritical);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertFactorModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
