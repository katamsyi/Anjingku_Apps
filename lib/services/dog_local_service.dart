import 'package:hive/hive.dart';
import '../models/dog_breed_local.dart';

class DogLocalService {
  static const _boxName = 'dogBreedsLocal';

  static Box<DogBreedLocal> getBox() => Hive.box<DogBreedLocal>(_boxName);

  static DogBreedLocal? getById(String id) {
    final box = getBox();
    try {
      return box.values.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<DogBreedLocal> getFavorites() {
    final box = getBox();
    return box.values.where((element) => element.isFavorite).toList();
  }

  static Future<void> save(DogBreedLocal data) async {
    final box = getBox();
    final existing = getById(data.id);
    if (existing != null) {
      existing.userNote = data.userNote;
      existing.isFavorite = data.isFavorite;
      await existing.save();
    } else {
      await box.add(data);
    }
  }

  static Future<void> delete(String id) async {
    final box = getBox();
    final existing = getById(id);
    if (existing != null) {
      await existing.delete();
    }
  }
}
