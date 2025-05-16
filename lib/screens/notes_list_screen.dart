import 'package:flutter/material.dart';
import '../models/dog_breed_local.dart';
import '../models/dog_breed_model.dart';
import '../services/dog_api_service.dart';
import '../services/dog_local_service.dart';
import 'note_edit_screen.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  late Future<List<_NoteBreed>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _notesFuture = _loadNotes();
  }

  Future<List<_NoteBreed>> _loadNotes() async {
    final apiBreeds = await DogApiService.fetchDogBreeds();
    final localNotes = DogLocalService.getBox()
        .values
        .where((e) => e.userNote != null && e.userNote!.isNotEmpty)
        .toList();

    List<_NoteBreed> notesWithDetail = [];

    for (var local in localNotes) {
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
      notesWithDetail.add(_NoteBreed(apiBreed: matchApi, localData: local));
    }
    return notesWithDetail;
  }

  void _reloadNotes() {
    setState(() {
      _notesFuture = _loadNotes();
    });
  }

  Future<bool?> _showConfirmDialog(BuildContext context, String breedName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus catatan untuk $breedName?'),
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
      appBar: AppBar(title: const Text('Daftar Catatan')),
      body: FutureBuilder<List<_NoteBreed>>(
        future: _notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada catatan'));
          }

          final notes = snapshot.data!;

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];

              return Dismissible(
                key: Key(note.localData.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  final confirm =
                      await _showConfirmDialog(context, note.apiBreed.name);
                  return confirm;
                },
                onDismissed: (_) async {
                  await DogLocalService.delete(note.localData.id);
                  _reloadNotes();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Catatan untuk ${note.apiBreed.name} dihapus')),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  leading: note.apiBreed.imageUrl.isNotEmpty
                      ? Image.network(
                          note.apiBreed.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox(width: 60, height: 60),
                  title: Text(note.apiBreed.name),
                  subtitle: Text(
                    note.localData.userNote ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Catatan',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NoteEditScreen(
                            breedId: note.localData.id,
                          ),
                        ),
                      );
                      _reloadNotes();
                    },
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

class _NoteBreed {
  final DogBreed apiBreed;
  final DogBreedLocal localData;

  _NoteBreed({required this.apiBreed, required this.localData});
}
