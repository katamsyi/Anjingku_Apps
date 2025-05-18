import 'package:cobaprojek/screens/dog_breed_detail_screen.dart';
import 'package:flutter/material.dart';
import '../models/dog_breed_model.dart';
import '../models/dog_breed_local.dart';
import '../services/dog_api_service.dart';
import '../services/dog_local_service.dart';

class DogBreedListScreen extends StatefulWidget {
  const DogBreedListScreen({super.key});

  @override
  State<DogBreedListScreen> createState() => _DogBreedListScreenState();
}

class _DogBreedListScreenState extends State<DogBreedListScreen> {
  late Future<List<DogBreed>> _breedsFuture;

  @override
  void initState() {
    super.initState();
    _breedsFuture = DogApiService.fetchDogBreeds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(title: const Text('Daftar Ras Anjing')),
      body: FutureBuilder<List<DogBreed>>(
        future: _breedsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Data ras anjing kosong.'));
          } else {
            final breeds = snapshot.data!;

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: breeds.length,
              itemBuilder: (context, index) {
                final breed = breeds[index];
                final localData = DogLocalService.getById(breed.id.toString());

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
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: breed.imageUrl.isNotEmpty
                                ? NetworkImage(breed.imageUrl)
                                : null,
                            child: breed.imageUrl.isEmpty
                                ? const Icon(Icons.pets, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  style: const TextStyle(color: Colors.black54),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if ((localData?.userNote ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
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
    );
  }
}
