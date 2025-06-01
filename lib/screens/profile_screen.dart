import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  late Box<User> userBox;
  User? currentUser;

  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isEditing = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    openHiveBox();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void openHiveBox() async {
    try {
      userBox = await Hive.openBox<User>('users');
      loadUserData();
    } catch (e) {
      _showSnackBar('Error opening database: $e', Colors.red);
    }
  }

  void loadUserData() {
    if (userBox.isNotEmpty) {
      currentUser = userBox.getAt(0);
      if (currentUser != null) {
        setState(() {
          _nameController.text = currentUser!.fullName ?? '';
          _emailController.text = currentUser!.email ?? '';
          _birthDateController.text = currentUser!.birthDate != null
              ? formatDate(currentUser!.birthDate!)
              : '';
          _selectedImage = currentUser!.profileImageUrl != null
              ? File(currentUser!.profileImageUrl!)
              : null;
        });
      }
    } else {
      setDefaultData();
    }
  }

  void setDefaultData() {
    setState(() {
      _nameController.text = "";
      _emailController.text = "";
      _birthDateController.text = "";
      _selectedImage = null;
    });
  }

  String formatDate(DateTime date) {
    return "${date.day} ${_getMonthName(date.month)} ${date.year}";
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month];
  }

  int _monthNameToNumber(String monthName) {
    const months = {
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12,
    };
    return months[monthName] ?? 1;
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      DateTime? birthDate;
      try {
        List<String> parts = _birthDateController.text.split(' ');
        if (parts.length == 3) {
          int day = int.parse(parts[0]);
          int month = _monthNameToNumber(parts[1]);
          int year = int.parse(parts[2]);
          birthDate = DateTime(year, month, day);
        }
      } catch (_) {
        birthDate = null;
      }

      if (userBox.isEmpty) {
        User newUser = User(
          username: '', // kosongkan username jika memang tidak dipakai
          password: '',
          fullName: _nameController.text,
          email: _emailController.text,
          birthDate: birthDate,
          profileImageUrl: _selectedImage?.path,
        );
        await userBox.add(newUser);
        currentUser = newUser;
      } else {
        User user = userBox.getAt(0)!;
        user.fullName = _nameController.text;
        user.email = _emailController.text;
        user.birthDate = birthDate;
        user.profileImageUrl = _selectedImage?.path;
        await user.save();
        currentUser = user;
      }

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      _showSnackBar('Profile updated successfully!', Colors.green);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error saving profile: $e', Colors.red);
    }
  }

  Future<void> _performReset() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (userBox.isNotEmpty) {
        await userBox.clear();
      }
      setDefaultData();
      setState(() {
        _isEditing = false;
        _isLoading = false;
        currentUser = null;
      });
      _showSnackBar('Profile reset successfully!', Colors.orange);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error resetting profile: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffAD8B73),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _buildImageOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  if (_selectedImage != null)
                    _buildImageOption(
                      icon: Icons.delete,
                      label: 'Remove',
                      onTap: _removeImage,
                      color: Colors.red,
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (color ?? const Color(0xffCEAB93)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: color ?? const Color(0xffAD8B73),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: color ?? const Color(0xffAD8B73),
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color ?? const Color(0xffAD8B73),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        if (currentUser != null) {
          currentUser!.profileImageUrl = pickedFile.path;
          await currentUser!.save();
        }

        _showSnackBar('Profile picture updated!', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', Colors.red);
    }
  }

  void _removeImage() {
    Navigator.pop(context);

    setState(() {
      _selectedImage = null;
    });

    if (currentUser != null) {
      currentUser!.profileImageUrl = null;
      currentUser!.save();
    }
    _showSnackBar('Profile picture removed!', Colors.orange);
  }

  Future<void> _selectDate() async {
    if (!_isEditing) return;

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xffAD8B73),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text =
            "${picked.day} ${_getMonthName(picked.month)} ${picked.year}";
      });
    }
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Logout',
          style: TextStyle(color: Color(0xffAD8B73), fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: <TextButton>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Yes', style: TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  void _resetProfile() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Reset Profile',
          style: TextStyle(color: Color(0xffAD8B73), fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to reset your profile? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performReset();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Widget fields

  Widget _nameField() {
    return TextFormField(
      enabled: _isEditing,
      controller: _nameController,
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Name cannot be empty' : null,
      decoration: _inputDecoration('Name', Icons.account_circle),
    );
  }

  Widget _emailField() {
    return TextFormField(
      enabled: _isEditing,
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email cannot be empty';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
      decoration: _inputDecoration('Email', Icons.email_rounded),
    );
  }

  Widget _birthDateField() {
    return TextFormField(
      enabled: _isEditing,
      controller: _birthDateController,
      readOnly: true,
      onTap: _selectDate,
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Birth date cannot be empty' : null,
      decoration: InputDecoration(
        labelText: 'Birth Date',
        labelStyle: const TextStyle(
          color: Color(0xffAD8B73),
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.cake,
          color: Color(0xffAD8B73),
          size: 25,
        ),
        suffixIcon: _isEditing
            ? const Icon(Icons.calendar_today, color: Color(0xffAD8B73), size: 20)
            : null,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffAD8B73), width: 1.5),
          borderRadius: BorderRadius.circular(10.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffAD8B73), width: 1.5),
          borderRadius: BorderRadius.circular(10.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffAD8B73), width: 1.5),
          borderRadius: BorderRadius.circular(10.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffAD8B73), width: 2.0),
          borderRadius: BorderRadius.circular(10.0),
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xffAD8B73),
          fontSize: 18.0,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xffAD8B73),
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xffAD8B73),
        size: 25,
      ),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xffAD8B73), width: 1.5),
        borderRadius: BorderRadius.circular(10.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xffAD8B73), width: 1.5),
        borderRadius: BorderRadius.circular(10.0),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xffAD8B73), width: 1.5),
        borderRadius: BorderRadius.circular(10.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xffAD8B73), width: 2.0),
        borderRadius: BorderRadius.circular(10.0),
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xffAD8B73),
        fontSize: 18.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3EEEA),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xffAD8B73),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xffAD8B73)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'logout':
                  _logout();
                  break;
                case 'reset':
                  _resetProfile();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Reset Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Color(0xffAD8B73)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xffAD8B73),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Picture Section
                    GestureDetector(
                      onTap: _isEditing ? _showImagePickerOptions : null,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: const Color(0xffCEAB93),
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : null,
                            child: _selectedImage == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xffAD8B73),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Form Fields
                    _nameField(),
                    const SizedBox(height: 20),
                    _emailField(),
                    const SizedBox(height: 20),
                    _birthDateField(),
                    const SizedBox(height: 40),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_isEditing) {
                                _saveUserData();
                              } else {
                                setState(() {
                                  _isEditing = true;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffAD8B73),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              _isEditing ? 'Save' : 'Edit Profile',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (_isEditing) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                });
                                loadUserData(); // Reset form to original data
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}