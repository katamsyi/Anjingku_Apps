//Hive untuk Profile user

import 'package:hive/hive.dart';

part 'user_model.g.dart'; // Untuk kode generate adapter

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  String password;

  // Field tambahan profil
  @HiveField(2)
  String? fullName;

  @HiveField(3)
  String? email;

  @HiveField(4)
  String? profileImageUrl;

  @HiveField(5)
  DateTime? birthDate;

  User({
    required this.username,
    required this.password,
    this.fullName,
    this.email,
    this.profileImageUrl,
    this.birthDate,
  });
}
