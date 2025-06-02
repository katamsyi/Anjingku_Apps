//Get API

class DogBreed {
  final int id;
  final String name;
  final String temperament;
  final String lifeSpan;
  final String imageUrl;

  DogBreed({
    required this.id,
    required this.name,
    required this.temperament,
    required this.lifeSpan,
    required this.imageUrl,
  });

  // factory DogBreed.fromJson(Map<String, dynamic> json) {
  //   return DogBreed(
  //     id: json['id'],
  //     name: json['name'],
  //     temperament: json['temperament'] ?? '',
  //     lifeSpan: json['life_span'] ?? '',
  //     imageUrl: json['image'] != null ? json['image']['url'] : '',
  //   );
  // }
  factory DogBreed.fromJson(Map<String, dynamic> json) {
    String imageUrl = '';
    if (json['image'] != null && json['image']['url'] != null) {
      imageUrl = json['image']['url'];
    } else if (json['reference_image_id'] != null) {
      imageUrl =
          'https://cdn2.thedogapi.com/images/${json['reference_image_id']}.jpg';
    }
    return DogBreed(
      id: json['id'],
      name: json['name'],
      temperament: json['temperament'] ?? '',
      lifeSpan: json['life_span'] ?? '',
      imageUrl: imageUrl,
    );
  }
}
