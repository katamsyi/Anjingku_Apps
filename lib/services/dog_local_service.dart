import 'package:hive/hive.dart';
import '../models/note_dog.dart';

class DogLocalService {
  static const _boxName = 'dogBreedsLocal';

  static Box<DogBreedLocal> getBox() => Hive.box<DogBreedLocal>(_boxName);

  static DogBreedLocal? getById(String id) {
    final box = getBox();
    return box.get(id);
  }

  static List<DogBreedLocal> getFavorites() {
    final box = getBox();
    return box.values.where((element) => element.isFavorite).toList();
  }

  static Future<void> save(DogBreedLocal data) async {
    final box = getBox();
    await box.put(data.id, data);
  }

  static Future<void> delete(String id) async {
    final box = getBox();
    await box.delete(id);
  }
}
