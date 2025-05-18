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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteEditScreen(breedId: '')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9),
      appBar: AppBar(
        title: Text('Hai, ${_username ?? ''}!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Apa yang ingin kamu lakukan hari ini?',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _HomeMenuCard(
                    icon: Icons.pets,
                    label: 'Ras Anjing',
                    onTap: _goToDogList,
                    color: Colors.orange,
                  ),
                  _HomeMenuCard(
                    icon: Icons.favorite,
                    label: 'Favorite',
                    onTap: _goToFavorites,
                    color: Colors.redAccent,
                  ),
                  _HomeMenuCard(
                    icon: Icons.notes,
                    label: 'Catatan',
                    onTap: () {
                      Navigator.pushNamed(context, '/notes_list');
                    },
                    color: Colors.blueAccent,
                  )
                  /*_HomeMenuCard(
                    icon: Icons.edit_note,
                    label: 'Tambah Catatan',
                    onTap: _goToNotes,
                    color: Colors.green,
                  ),*/
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _HomeMenuCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: color.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }
}
