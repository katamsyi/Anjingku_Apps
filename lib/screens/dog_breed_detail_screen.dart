import 'package:flutter/material.dart';
import '../models/dog_breed_model.dart';
import '../models/dog_breed_local.dart';
import '../services/dog_local_service.dart';

class DogBreedDetailScreen extends StatefulWidget {
  final DogBreed apiBreed;
  final DogBreedLocal? localData;

  const DogBreedDetailScreen(
      {super.key, required this.apiBreed, this.localData});

  @override
  State<DogBreedDetailScreen> createState() => _DogBreedDetailScreenState();
}

class _DogBreedDetailScreenState extends State<DogBreedDetailScreen> {
  late TextEditingController _noteController;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _noteController =
        TextEditingController(text: widget.localData?.userNote ?? '');
    _isFavorite = widget.localData?.isFavorite ?? false;
  }

  void _save() async {
    final localData =
        widget.localData ?? DogBreedLocal(id: widget.apiBreed.id.toString());
    localData.userNote = _noteController.text;
    localData.isFavorite = _isFavorite;
    await DogLocalService.save(localData);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data lokal berhasil disimpan')),
    );
  }

  void _delete() async {
    if (widget.localData != null) {
      await DogLocalService.delete(widget.localData!.id);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breed = widget.apiBreed;
    return Scaffold(
      appBar: AppBar(
        title: Text(breed.name),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.red),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
          if (widget.localData != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _delete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (breed.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  breed.imageUrl,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: Colors.grey[300],
                      child:
                          const Icon(Icons.pets, size: 100, color: Colors.grey),
                    );
                  },
                ),
              )
            else
              Container(
                height: 250,
                color: Colors.grey[300],
                child: const Icon(Icons.pets, size: 100, color: Colors.grey),
              ),
            Text('Temperament: ${breed.temperament}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Life Span: ${breed.lifeSpan}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan pribadi',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Simpan Catatan & Favorit'),
            ),
          ],
        ),
      ),
    );
  }
}
