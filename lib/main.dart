import 'package:cobaprojek/screens/favorite_screen.dart';
import 'package:cobaprojek/screens/note_edit_screen.dart';
import 'package:cobaprojek/screens/notes_list_screen.dart';
import 'package:cobaprojek/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/dog_breed_local.dart';
import 'screens/login_screen.dart';
//import 'screens/notes_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(DogBreedLocalAdapter());
  await Hive.openBox<DogBreedLocal>('dogBreedsLocal');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog API + Hive CRUD Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
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
