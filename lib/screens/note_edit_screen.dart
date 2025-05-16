import 'package:flutter/material.dart';
import '../models/dog_breed_local.dart';
import '../services/dog_local_service.dart';

class NoteEditScreen extends StatefulWidget {
  final String breedId;
  const NoteEditScreen({super.key, required this.breedId});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late TextEditingController _noteController;
  late DogBreedLocal _localData;

  @override
  void initState() {
    super.initState();
    _localData = DogLocalService.getById(widget.breedId) ??
        DogBreedLocal(id: widget.breedId);
    _noteController = TextEditingController(text: _localData.userNote ?? '');
  }

  void _saveNote() async {
    _localData.userNote = _noteController.text;
    await DogLocalService.save(_localData);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catatan berhasil disimpan')),
    );
    Navigator.pop(context);
  }

  void _deleteNote() async {
    _localData.userNote = null;
    await DogLocalService.save(_localData);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catatan berhasil dihapus')),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Catatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              if (_noteController.text.isNotEmpty) {
                _deleteNote();
              }
            },
            tooltip: 'Hapus Catatan',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
            tooltip: 'Simpan Catatan',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'Catatan',
            border: OutlineInputBorder(),
          ),
          maxLines: 6,
          textInputAction: TextInputAction.done,
        ),
      ),
    );
  }
}
