// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_queue.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QueuedActionAdapter extends TypeAdapter<QueuedAction> {
  @override
  final int typeId = 0;

  @override
  QueuedAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QueuedAction(
      id: fields[0] as String,
      type: fields[1] as String,
      payload: fields[2] as String,
      createdAt: fields[3] as DateTime,
      retryCount: fields[4] as int,
      status: fields[5] as String,
      parentId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, QueuedAction obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.payload)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.retryCount)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.parentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueuedActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
