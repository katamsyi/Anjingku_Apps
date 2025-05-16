import 'package:flutter/material.dart';
import '../services/auth_preferences.dart';
import 'dog_breed_list_screen.dart';
import 'favorite_screen.dart';
import 'note_edit_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final username = await AuthPreferences.getUsername();
    setState(() {
      _username = username;
    });
  }

  void _logout() async {
    await AuthPreferences.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goToDogList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DogBreedListScreen()),
    );
  }

  void _goToFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FavoriteScreen()),
    );
  }

  void _goToNotes() {
    // Untuk contoh, kita bisa pakai breedId kosong (atau modifikasi sesuai kebutuhan)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteEditScreen(breedId: '')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selamat Datang, ${_username ?? ''}'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _goToDogList,
              child: const Text('Lihat Daftar Ras Anjing'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _goToFavorites,
              child: const Text('Daftar Favorite & Catatan'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/notes_list');
              },
              child: const Text('Lihat Daftar Catatan'),
            ),
          ],
        ),
      ),
    );
  }
}
