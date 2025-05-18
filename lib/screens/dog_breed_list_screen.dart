import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../models/dog_breed_model.dart';
import '../models/dog_breed_local.dart';
import '../services/dog_api_service.dart';
import '../services/dog_local_service.dart';
import 'dog_breed_detail_screen.dart';

class DogBreedListScreen extends StatefulWidget {
  const DogBreedListScreen({super.key});

  @override
  State<DogBreedListScreen> createState() => _DogBreedListScreenState();
}

class _DogBreedListScreenState extends State<DogBreedListScreen> {
  final Logger logger = Logger();

  TextEditingController _searchController = TextEditingController();
  Future<List<DogBreed>>? _breedsFuture;

  @override
  void initState() {
    super.initState();
    _breedsFuture = DogApiService.fetchAllBreeds();
    _searchController.addListener(_onSearchTextChanged);
  }

  void _onSearchTextChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _breedsFuture = DogApiService.fetchAllBreeds();
      });
    } else {
      setState(() {
        _breedsFuture = DogApiService.searchBreeds(query);
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Daftar Ras Anjing'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Cari ras anjing...',
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _breedsFuture = DogApiService.fetchAllBreeds();
                          });
                        },
                      )
                    : null,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                _onSearchTextChanged();
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DogBreed>>(
              future: _breedsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  logger.e('Error fetching breeds: ${snapshot.error}');
                  return Center(
                      child: Text('Terjadi kesalahan: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Data ras anjing kosong.'));
                } else {
                  final breeds = snapshot.data!;
                  logger.i('Displaying ${breeds.length} breeds');

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: breeds.length,
                    itemBuilder: (context, index) {
                      final breed = breeds[index];
                      final localData =
                          DogLocalService.getById(breed.id.toString());

                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DogBreedDetailScreen(
                                apiBreed: breed,
                                localData: localData,
                              ),
                            ),
                          );
                          setState(() {});
                        },
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: breed.imageUrl.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            breed.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(Icons.pets,
                                                  color: Colors.grey, size: 32);
                                            },
                                          ),
                                        )
                                      : const Icon(Icons.pets,
                                          color: Colors.grey, size: 32),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        breed.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        breed.temperament,
                                        style: const TextStyle(
                                            color: Colors.black54),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if ((localData?.userNote ?? '')
                                          .isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            '📒 ${localData!.userNote}',
                                            style: const TextStyle(
                                              fontStyle: FontStyle.italic,
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    (localData?.isFavorite ?? false)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    final isFavorite =
                                        !(localData?.isFavorite ?? false);
                                    final newLocalData = localData ??
                                        DogBreedLocal(id: breed.id.toString());
                                    newLocalData.isFavorite = isFavorite;
                                    await DogLocalService.save(newLocalData);
                                    setState(() {});
                                  },
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
