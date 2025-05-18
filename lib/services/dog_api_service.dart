import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/dog_breed_model.dart';

class DogApiService {
  static const _baseUrl = 'https://api.thedogapi.com/v1';
  static const _apiKey =
      'live_nOIn0QFXaTO84ezfSnfu2tVBcUpstrVATsK7EnpTiSJlMGD37tMQHwQYqc4T6Z9Z';

  static final Logger logger = Logger();

  static List<DogBreed>? _allBreedsCache;

  /// Ambil semua breed lengkap dengan gambar, cache hasilnya untuk optimasi
  static Future<List<DogBreed>> fetchAllBreeds() async {
    if (_allBreedsCache != null) {
      logger.i('Returning cached breeds: ${_allBreedsCache!.length}');
      return _allBreedsCache!;
    }

    final url = Uri.parse('$_baseUrl/breeds');
    logger.i('Requesting all dog breeds from $url');

    final response = await http.get(url, headers: {'x-api-key': _apiKey});

    if (response.statusCode == 200) {
      final List jsonResponse = json.decode(response.body);
      final breedsWithImage = jsonResponse.where((e) {
        final img = e['image']?['url'] ?? '';
        final refId = e['reference_image_id'] ?? '';
        return img.isNotEmpty || refId.isNotEmpty;
      }).toList();

      _allBreedsCache =
          breedsWithImage.map((e) => DogBreed.fromJson(e)).toList();

      logger.i('Fetched and cached ${_allBreedsCache!.length} breeds');
      return _allBreedsCache!;
    } else {
      logger.e('Failed to load dog breeds: ${response.statusCode}');
      throw Exception('Failed to load dog breeds');
    }
  }

  /// Cari breed berdasarkan query nama, lalu gabungkan dengan data lengkap supaya dapat gambar
  static Future<List<DogBreed>> searchBreeds(String query) async {
    final url = Uri.parse('$_baseUrl/breeds/search?q=$query');
    logger.i('Searching dog breeds with query: $query');

    final response = await http.get(url, headers: {'x-api-key': _apiKey});

    if (response.statusCode == 200) {
      final List searchResults = json.decode(response.body);

      logger.i('Found ${searchResults.length} breeds matching query');

      // Ambil semua breed lengkap (cached atau fetch)
      final allBreeds = await fetchAllBreeds();

      // Gabungkan hasil search dengan data lengkap berdasarkan id
      List<DogBreed> resultWithImages = [];
      for (var breedData in searchResults) {
        final id = breedData['id'];
        // Cari di allBreeds yang punya gambar sesuai id
        final matchedBreed = allBreeds.firstWhere((b) => b.id == id,
            orElse: () => DogBreed.fromJson(breedData));

        resultWithImages.add(matchedBreed);
      }

      return resultWithImages;
    } else {
      logger.e('Failed to search dog breeds: ${response.statusCode}');
      throw Exception('Failed to search dog breeds');
    }
  }
}
