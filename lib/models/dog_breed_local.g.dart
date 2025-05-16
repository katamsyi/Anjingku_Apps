// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dog_breed_local.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DogBreedLocalAdapter extends TypeAdapter<DogBreedLocal> {
  @override
  final int typeId = 1;

  @override
  DogBreedLocal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DogBreedLocal(
      id: fields[0] as String,
      userNote: fields[1] as String?,
      isFavorite: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DogBreedLocal obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userNote)
      ..writeByte(2)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DogBreedLocalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
