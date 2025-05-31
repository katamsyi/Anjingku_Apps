import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/favorite_screen.dart';
import '../screens/notes_list_screen.dart'; // ganti dog_breed_list_screen ke notes_list_screen
import '../screens/profile_screen.dart';

class NavBar extends StatefulWidget {
  const NavBar({Key? key}) : super(key: key);

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _selectedIndex = 0;

  final List<Widget> pages = [
    const HomePage(),
    const FavoriteScreen(),
    const NotesListScreen(), // diganti dari DogBreedListScreen
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xffFFFBE9),
        unselectedItemColor: const Color(0xff854836),
        backgroundColor: const Color(0xffCEAB93),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Favorite'),
          BottomNavigationBarItem(
              icon: Icon(Icons.note), label: 'Notes'), // icon dan label diganti
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}
