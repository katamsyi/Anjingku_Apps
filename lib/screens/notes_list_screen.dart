import 'package:flutter/material.dart';
import '../models/note_dog.dart';
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
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _notesFuture = _loadNotes();
  }

  Future<List<_NoteBreed>> _loadNotes() async {
    try {
      final apiBreeds = await DogApiService.fetchAllBreeds();
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
    } catch (e) {
      return [];
    }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Konfirmasi Hapus'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
            children: [
              const TextSpan(text: 'Yakin ingin menghapus catatan untuk '),
              TextSpan(
                text: breedName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote(String id, String breedName) async {
    setState(() {
      _isDeleting = true;
    });
    await DogLocalService.delete(id);
    _reloadNotes();
    setState(() {
      _isDeleting = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Catatan untuk $breedName berhasil dihapus'),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  int _countNotes(String noteText) {
    return noteText.split('\n').where((line) => line.trim().isNotEmpty).length;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              'Daftar Catatan',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color.fromARGB(255, 212, 173, 115),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: FutureBuilder<List<_NoteBreed>>(
            future: _notesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Memuat catatan...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Terjadi kesalahan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_add_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada catatan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mulai buat catatan untuk ras anjing favorit Anda!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final notes = snapshot.data!;

              return RefreshIndicator(
                onRefresh: () async {
                  _reloadNotes();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final noteCount =
                        _countNotes(note.localData.userNote ?? '');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: Key(note.localData.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          final confirm = await _showConfirmDialog(
                              context, note.apiBreed.name);
                          return confirm;
                        },
                        onDismissed: (_) async {
                          await _deleteNote(
                              note.localData.id, note.apiBreed.name);
                        },
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_sweep,
                                  color: Colors.white, size: 32),
                              SizedBox(height: 4),
                              Text(
                                'Hapus',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: note.apiBreed.imageUrl.isNotEmpty
                                  ? Image.network(
                                      note.apiBreed.imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey.shade300,
                                          child: Icon(
                                            Icons.pets,
                                            color: Colors.grey.shade600,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.pets,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    note.apiBreed.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$noteCount catatan',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                note.localData.userNote
                                        ?.replaceAll('\n', ' • ') ??
                                    '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Delete button
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red.shade400,
                                  ),
                                  tooltip: 'Hapus Catatan',
                                  onPressed: () async {
                                    final confirm = await _showConfirmDialog(
                                        context, note.apiBreed.name);
                                    if (confirm == true) {
                                      await _deleteNote(note.localData.id,
                                          note.apiBreed.name);
                                    }
                                  },
                                ),
                                // Edit button
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blue.shade600,
                                  ),
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (_isDeleting)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Menghapus catatan...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NoteBreed {
  final DogBreed apiBreed;
  final DogBreedLocal localData;

  _NoteBreed({required this.apiBreed, required this.localData});
}
