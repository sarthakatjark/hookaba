// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_program_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalProgramModelAdapter extends TypeAdapter<LocalProgramModel> {
  @override
  final int typeId = 1;

  @override
  LocalProgramModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalProgramModel(
      id: fields[0] as String,
      name: fields[1] as String,
      bmpBytes: fields[2] as Uint8List,
      jsonCommand: (fields[3] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, LocalProgramModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.bmpBytes)
      ..writeByte(3)
      ..write(obj.jsonCommand);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalProgramModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
