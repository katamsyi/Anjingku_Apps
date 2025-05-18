import 'package:hive/hive.dart';

part 'user_model.g.dart'; // Untuk kode generate adapter

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  String password;

  User({required this.username, required this.password});
}
