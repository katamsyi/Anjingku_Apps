// favorite_screen.dart - Updated version
import 'package:flutter/material.dart';
import '../models/note_dog.dart';
import '../models/dog_breed_model.dart';
import '../services/dog_api_service.dart';
import '../services/dog_local_service.dart';
import 'dog_detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<_FavoriteBreed> _allFavorites = [];
  List<_FavoriteBreed> _filteredFavorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteBreeds();

    _searchController.addListener(() {
      _filterFavorites(_searchController.text.trim());
    });
  }

  Future<void> _loadFavoriteBreeds() async {
    setState(() {
      _isLoading = true;
    });

    try {
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Gagal memuat data favorit', false);
    }
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Fungsi untuk toggle favorite langsung
  Future<void> _toggleFavorite(_FavoriteBreed fav) async {
    final wasRemoved = fav.localData.isFavorite;

    setState(() {
      fav.localData.isFavorite = !fav.localData.isFavorite;
    });

    await DogLocalService.save(fav.localData);

    // Jika dihapus dari favorit, reload list
    if (wasRemoved) {
      _reloadFavorites();
    }

    _showSnackBar(
      fav.localData.isFavorite
          ? '${fav.apiBreed.name} ditambahkan ke favorit'
          : '${fav.apiBreed.name} dihapus dari favorit',
      fav.localData.isFavorite,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Favorit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadFavorites,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Cari favorit...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
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

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredFavorites.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Tidak ada favorit yang cocok'
                                  : 'Belum ada favorit',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Coba kata kunci lain'
                                  : 'Tambahkan breed anjing ke favorit untuk melihatnya di sini',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadFavoriteBreeds();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                await _toggleFavorite(fav);
                              },
                              background: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerLeft,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: fav.apiBreed.imageUrl.isNotEmpty
                                        ? Image.network(
                                            fav.apiBreed.imageUrl,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                    Icons.image_not_supported),
                                              );
                                            },
                                          )
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.pets),
                                          ),
                                  ),
                                  title: Text(
                                    fav.apiBreed.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (fav.apiBreed.temperament.isNotEmpty)
                                        Text(
                                          'Temperament: ${fav.apiBreed.temperament}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (fav.localData.userNote != null &&
                                          fav.localData.userNote!.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Catatan: ${fav.localData.userNote}',
                                            style: const TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Colors.blue,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.favorite,
                                          color: fav.localData.isFavorite
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                        tooltip: fav.localData.isFavorite
                                            ? 'Hapus Favorit'
                                            : 'Tambah Favorit',
                                        onPressed: () => _toggleFavorite(fav),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
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
                              ),
                            );
                          },
                        ),
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
