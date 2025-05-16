import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dog_breed_model.dart';

class DogApiService {
  static const _baseUrl = 'https://api.thedogapi.com/v1';

  static Future<List<DogBreed>> fetchDogBreeds() async {
    final response = await http.get(Uri.parse('$_baseUrl/breeds'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((e) => DogBreed.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load dog breeds');
    }
  }
}
