import 'package:flutter/material.dart';
import '../models/note_dog.dart';
import '../services/dog_local_service.dart';

class NoteEditScreen extends StatefulWidget {
  final String breedId;
  const NoteEditScreen({super.key, required this.breedId});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late DogBreedLocal _localData;
  List<TextEditingController> _controllers = [];
  List<String> _notesList = [];

  @override
  void initState() {
    super.initState();
    _localData = DogLocalService.getById(widget.breedId) ??
        DogBreedLocal(id: widget.breedId);
    _loadNotes();
  }

  void _loadNotes() {
    _notesList = (_localData.userNote?.split('\n') ?? [])
        .where((note) => note.trim().isNotEmpty)
        .toList();

    // Buat controller untuk setiap catatan yang ada
    _controllers =
        _notesList.map((note) => TextEditingController(text: note)).toList();

    // Jika tidak ada catatan, buat satu controller kosong
    if (_controllers.isEmpty) {
      _controllers.add(TextEditingController());
      _notesList.add('');
    }
  }

  void _addNewNote() {
    setState(() {
      _controllers.add(TextEditingController());
      _notesList.add('');
    });
  }

  void _removeNote(int index) {
    if (_controllers.length > 1) {
      setState(() {
        _controllers[index].dispose();
        _controllers.removeAt(index);
        _notesList.removeAt(index);
      });
      _saveAllNotes();
    }
  }

  void _updateNote(int index, String value) {
    _notesList[index] = value;
  }

  void _saveAllNotes() async {
    // Update notesList dengan nilai terbaru dari controllers
    for (int i = 0; i < _controllers.length; i++) {
      _notesList[i] = _controllers[i].text;
    }

    // Filter catatan yang tidak kosong
    final filteredNotes =
        _notesList.where((note) => note.trim().isNotEmpty).toList();

    _localData.userNote =
        filteredNotes.isEmpty ? null : filteredNotes.join('\n');
    await DogLocalService.save(_localData);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Catatan berhasil disimpan'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _clearAllNotes() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Konfirmasi'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin menghapus semua catatan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Dispose semua controller yang ada
              for (var controller in _controllers) {
                controller.dispose();
              }
              setState(() {
                _controllers.clear();
                _notesList.clear();
                // Buat satu controller kosong
                _controllers.add(TextEditingController());
                _notesList.add('');
              });
              _localData.userNote = null;
              await DogLocalService.save(_localData);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Semua catatan berhasil dihapus'),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Dispose semua controllers
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          ' Edit Catatan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color.fromARGB(255, 201, 175, 112),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_controllers.length > 1 || _controllers.first.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all_rounded),
              onPressed: _clearAllNotes,
              tooltip: 'Hapus Semua Catatan',
            ),
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _saveAllNotes,
            tooltip: 'Simpan Catatan',
          ),
        ],
      ),
      body: Column(
        children: [
          // Notes List Section
          Expanded(
            child: _controllers.isEmpty
                ? Center(
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
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _controllers.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header dengan nomor dan tombol hapus
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 201, 175, 112),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Catatan ${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: const Color.fromARGB(
                                            255, 201, 175, 112),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (_controllers.length > 1)
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red.shade400,
                                        size: 20,
                                      ),
                                      onPressed: () => _removeNote(index),
                                      tooltip: 'Hapus catatan ini',
                                    ),
                                ],
                              ),
                            ),
                            // Text field untuk edit
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextField(
                                controller: _controllers[index],
                                decoration: InputDecoration(
                                  hintText: 'Tulis catatan Anda di sini...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                maxLines: 4,
                                textInputAction: TextInputAction.newline,
                                onChanged: (value) => _updateNote(index, value),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Add new note button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addNewNote,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Catatan Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 201, 175, 112),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
