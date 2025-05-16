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
      appBar: AppBar(title: const Text('Daftar Ras Anjing')),
      body: FutureBuilder<List<DogBreed>>(
        future: _breedsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Data kosong'));
          } else {
            final apiBreeds = snapshot.data!;

            return ListView.builder(
              itemCount: apiBreeds.length,
              itemBuilder: (context, index) {
                final apiBreed = apiBreeds[index];
                print('URL gambar index $index: ${apiBreed.imageUrl}');
                final localData =
                    DogLocalService.getById(apiBreed.id.toString());

                return ListTile(
                  leading: apiBreed.imageUrl.isNotEmpty
                      ? Image.network(apiBreed.imageUrl,
                          width: 60, height: 60, fit: BoxFit.cover)
                      : const SizedBox(width: 60, height: 60),
                  title: Text(apiBreed.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Temperament: ${apiBreed.temperament}'),
                      if (localData?.userNote != null &&
                          localData!.userNote!.isNotEmpty)
                        Text('Catatan: ${localData.userNote}',
                            style:
                                const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      (localData?.isFavorite ?? false)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: () async {
                      final newFavoriteStatus =
                          !(localData?.isFavorite ?? false);
                      final newLocalData = localData ??
                          DogBreedLocal(id: apiBreed.id.toString());
                      newLocalData.isFavorite = newFavoriteStatus;
                      await DogLocalService.save(newLocalData);
                      setState(() {});
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DogBreedDetailScreen(
                            apiBreed: apiBreed, localData: localData),
                      ),
                    ).then((_) => setState(() {})); // refresh saat kembali
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
