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

  factory DogBreed.fromJson(Map<String, dynamic> json) {
    return DogBreed(
      id: json['id'],
      name: json['name'],
      temperament: json['temperament'] ?? '',
      lifeSpan: json['life_span'] ?? '',
      imageUrl: json['image'] != null ? json['image']['url'] : '',
    );
  }
}
