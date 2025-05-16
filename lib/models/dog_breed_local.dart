import 'package:hive/hive.dart';

part 'dog_breed_local.g.dart';

@HiveType(typeId: 1)
class DogBreedLocal extends HiveObject {
  @HiveField(0)
  String id; // pakai string biar fleksibel

  @HiveField(1)
  String? userNote;

  @HiveField(2)
  bool isFavorite;

  DogBreedLocal({
    required this.id,
    this.userNote,
    this.isFavorite = false,
  });
}
