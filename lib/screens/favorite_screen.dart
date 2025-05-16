import 'package:flutter/material.dart';
import '../models/dog_breed_local.dart';
import '../models/dog_breed_model.dart';
import '../services/dog_api_service.dart';
import '../services/dog_local_service.dart';
import 'dog_breed_detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  late Future<List<_FavoriteBreed>> _favoriteBreedsFuture;

  @override
  void initState() {
    super.initState();
    _favoriteBreedsFuture = _loadFavoriteBreeds();
  }

  Future<List<_FavoriteBreed>> _loadFavoriteBreeds() async {
    final apiBreeds = await DogApiService.fetchDogBreeds();
    final localFavorites = DogLocalService.getFavorites();

    List<_FavoriteBreed> favoritesWithDetail = [];

    for (var local in localFavorites) {
      final matchApi = apiBreeds.firstWhere(
        (apiBreed) => apiBreed.id.toString() == local.id,
        orElse: () => DogBreed(
          id: 0,
          name: 'Data tidak ditemukan',
          temperament: '',
          lifeSpan: '',
          imageUrl: '',
        ),
      );
      favoritesWithDetail
          .add(_FavoriteBreed(apiBreed: matchApi, localData: local));
    }
    return favoritesWithDetail;
  }

  void _reloadFavorites() {
    setState(() {
      _favoriteBreedsFuture = _loadFavoriteBreeds();
    });
  }

  Future<bool?> _showConfirmDialog(BuildContext context, String breedName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus $breedName dari favorit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Favorit')),
      body: FutureBuilder<List<_FavoriteBreed>>(
        future: _favoriteBreedsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada favorit'));
          }

          final favorites = snapshot.data!;

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final fav = favorites[index];

              return Dismissible(
                key: Key(fav.localData.id),
                direction: DismissDirection.horizontal,
                confirmDismiss: (_) async {
                  final confirm =
                      await _showConfirmDialog(context, fav.apiBreed.name);
                  return confirm;
                },
                onDismissed: (_) async {
                  fav.localData.isFavorite = false;
                  await DogLocalService.save(fav.localData);
                  _reloadFavorites();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('${fav.apiBreed.name} dihapus dari favorit')),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: fav.apiBreed.imageUrl.isNotEmpty
                        ? Image.network(
                            fav.apiBreed.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(width: 60, height: 60),
                    title: Text(fav.apiBreed.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Temperament: ${fav.apiBreed.temperament}'),
                        if (fav.localData.userNote != null &&
                            fav.localData.userNote!.isNotEmpty)
                          Text('Catatan: ${fav.localData.userNote}',
                              style:
                                  const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit Catatan',
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DogBreedDetailScreen(
                                  apiBreed: fav.apiBreed,
                                  localData: fav.localData,
                                ),
                              ),
                            );
                            _reloadFavorites();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          tooltip: 'Hapus Favorit',
                          onPressed: () async {
                            fav.localData.isFavorite = false;
                            await DogLocalService.save(fav.localData);
                            _reloadFavorites();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteBreed {
  final DogBreed apiBreed;
  final DogBreedLocal localData;

  _FavoriteBreed({
    required this.apiBreed,
    required this.localData,
  });
}
