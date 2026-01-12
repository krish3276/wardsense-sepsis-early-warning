// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'escalation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EscalationModelAdapter extends TypeAdapter<EscalationModel> {
  @override
  final int typeId = 4;

  @override
  EscalationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EscalationModel(
      id: fields[0] as String,
      patientId: fields[1] as String,
      alertId: fields[2] as String,
      escalationTypeIndex: fields[3] as int,
      riskLevelIndex: fields[4] as int,
      timestamp: fields[5] as DateTime,
      initiatedBy: fields[6] as String,
      notes: fields[7] as String?,
      isCompleted: fields[8] as bool,
      completedAt: fields[9] as DateTime?,
      outcome: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EscalationModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.alertId)
      ..writeByte(3)
      ..write(obj.escalationTypeIndex)
      ..writeByte(4)
      ..write(obj.riskLevelIndex)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.initiatedBy)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.isCompleted)
      ..writeByte(9)
      ..write(obj.completedAt)
      ..writeByte(10)
      ..write(obj.outcome);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EscalationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
