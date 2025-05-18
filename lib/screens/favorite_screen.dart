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
  final TextEditingController _searchController = TextEditingController();
  List<_FavoriteBreed> _allFavorites = [];
  List<_FavoriteBreed> _filteredFavorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteBreeds();

    _searchController.addListener(() {
      _filterFavorites(_searchController.text.trim());
    });
  }

  Future<void> _loadFavoriteBreeds() async {
    final apiBreeds = await DogApiService.fetchAllBreeds();
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

    setState(() {
      _allFavorites = favoritesWithDetail;
      _filteredFavorites = List.from(_allFavorites);
    });
  }

  void _filterFavorites(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredFavorites = List.from(_allFavorites);
      });
    } else {
      setState(() {
        _filteredFavorites = _allFavorites
            .where((fav) =>
                fav.apiBreed.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
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

  void _reloadFavorites() {
    _loadFavoriteBreeds();
    _searchController.clear();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Favorit')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Cari favorit...',
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                          _filterFavorites('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _filteredFavorites.isEmpty
                ? const Center(child: Text('Belum ada favorit'))
                : ListView.builder(
                    itemCount: _filteredFavorites.length,
                    itemBuilder: (context, index) {
                      final fav = _filteredFavorites[index];

                      return Dismissible(
                        key: Key(fav.localData.id),
                        direction: DismissDirection.horizontal,
                        confirmDismiss: (_) async {
                          final confirm = await _showConfirmDialog(
                              context, fav.apiBreed.name);
                          return confirm;
                        },
                        onDismissed: (_) async {
                          fav.localData.isFavorite = false;
                          await DogLocalService.save(fav.localData);
                          _reloadFavorites();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    '${fav.apiBreed.name} dihapus dari favorit')),
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
                                Text(
                                    'Temperament: ${fav.apiBreed.temperament}'),
                                if (fav.localData.userNote != null &&
                                    fav.localData.userNote!.isNotEmpty)
                                  Text('Catatan: ${fav.localData.userNote}',
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic)),
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
                                  icon: const Icon(Icons.favorite,
                                      color: Colors.red),
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
                  ),
          ),
        ],
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
