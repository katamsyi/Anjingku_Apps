import 'package:cobaprojek/screens/favorite_screen.dart';
import 'package:cobaprojek/screens/note_edit_screen.dart';
import 'package:cobaprojek/screens/notes_list_screen.dart';
import 'package:cobaprojek/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/dog_breed_local.dart';
import 'models/user_model.dart';
import 'screens/login_screen.dart';
import 'package:device_preview/device_preview.dart';
import 'widgets/nav_bar.dart'; // import NavBar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Daftarkan adapter Hive model
  Hive.registerAdapter(DogBreedLocalAdapter());
  Hive.registerAdapter(UserAdapter());

  // Buka box Hive sebelum runApp
  await Hive.openBox<DogBreedLocal>('dogBreedsLocal');
  await Hive.openBox<User>('users');

  // Debug: cek data user di Hive
  var userBox = Hive.box<User>('users');
  for (var user in userBox.values) {
    print('User in Hive at startup: ${user.username}');
  }

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Apps',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/navbar': (context) => const NavBar(),
        '/favorites': (context) => const FavoriteScreen(),
        '/notes_list': (context) => const NotesListScreen(),
        '/note_edit': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return NoteEditScreen(breedId: args);
        },
      },
    );
  }
}
