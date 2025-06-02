// dog_detail_screen.dart - Updated version
import 'package:flutter/material.dart';
import '../models/dog_breed_model.dart';
import '../models/note_dog.dart';
import '../services/dog_local_service.dart';
import 'note_edit_screen.dart';

class DogBreedDetailScreen extends StatefulWidget {
  final DogBreed apiBreed;
  final DogBreedLocal? localData;

  const DogBreedDetailScreen({
    super.key,
    required this.apiBreed,
    this.localData,
  });

  @override
  State<DogBreedDetailScreen> createState() => _DogBreedDetailScreenState();
}

class _DogBreedDetailScreenState extends State<DogBreedDetailScreen> {
  late DogBreedLocal _localData;

  @override
  void initState() {
    super.initState();
    // Inisialisasi data lokal
    _localData = widget.localData ??
        DogLocalService.getById(widget.apiBreed.id.toString()) ??
        DogBreedLocal(id: widget.apiBreed.id.toString());
  }

  // Fungsi untuk toggle favorite dan langsung simpan
  Future<void> _toggleFavorite() async {
    setState(() {
      _localData.isFavorite = !_localData.isFavorite;
    });

    // Langsung simpan ke local storage
    await DogLocalService.save(_localData);

    // Tampilkan snackbar dengan warna sesuai status
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _localData.isFavorite
                ? '${widget.apiBreed.name} ditambahkan ke favorit'
                : '${widget.apiBreed.name} dihapus dari favorit',
          ),
          backgroundColor: _localData.isFavorite ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Fungsi untuk refresh data setelah edit note
  void _refreshData() {
    final updatedData = DogLocalService.getById(widget.apiBreed.id.toString());
    if (updatedData != null) {
      setState(() {
        _localData = updatedData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.apiBreed.name),
        actions: [
          // Tombol untuk edit catatan
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Edit Catatan',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteEditScreen(
                    breedId: widget.apiBreed.id.toString(),
                  ),
                ),
              );
              _refreshData(); // Refresh data setelah kembali dari edit
            },
          ),
          // Tombol favorite yang langsung menyimpan
          IconButton(
            icon: Icon(
              _localData.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _localData.isFavorite ? Colors.red : Colors.grey,
            ),
            tooltip: _localData.isFavorite
                ? 'Hapus dari Favorit'
                : 'Tambah ke Favorit',
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar breed
            if (widget.apiBreed.imageUrl.isNotEmpty)
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.apiBreed.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 50),
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Nama breed dengan status favorite
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.apiBreed.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (_localData.isFavorite)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, color: Colors.red, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Favorit',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Detail informasi
            _buildInfoCard('Temperament', widget.apiBreed.temperament),
            _buildInfoCard('Life Span', widget.apiBreed.lifeSpan),

            // Catatan pengguna
            if (_localData.userNote != null && _localData.userNote!.isNotEmpty)
              _buildNoteCard(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content.isNotEmpty ? content : 'Tidak ada informasi',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.amber.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Catatan Pribadi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteEditScreen(
                          breedId: widget.apiBreed.id.toString(),
                        ),
                      ),
                    );
                    _refreshData();
                  },
                  tooltip: 'Edit Catatan',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _localData.userNote!,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
