import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _mottoController = TextEditingController();

  late SharedPreferences prefs;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isEditing = false;
  bool _isLoading = false;

  // Form key untuk validasi
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    initial();
  }

  void initial() async {
    prefs = await SharedPreferences.getInstance();
    await _loadUserData();
    _loadSavedImage();
  }

  // CREATE & UPDATE - Save user data
  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, String> userData = {
        'name': _nameController.text,
        'nim': _nimController.text,
        'email': _emailController.text,
        'birthDate': _birthDateController.text,
        'motto': _mottoController.text,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      String userDataJson = jsonEncode(userData);
      await prefs.setString('user_profile', userDataJson);

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

  // READ - Load user data
  Future<void> _loadUserData() async {
    try {
      String? userDataJson = prefs.getString('user_profile');

      if (userDataJson != null) {
        Map<String, dynamic> userData = jsonDecode(userDataJson);
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _nimController.text = userData['nim'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _birthDateController.text = userData['birthDate'] ?? '';
          _mottoController.text = userData['motto'] ?? '';
        });
      } else {
        // Default data jika belum ada data tersimpan
        setState(() {
          _nameController.text = "Kaifa Ahlal Katamsyi";
          _nimController.text = "123220006";
          _emailController.text = "kaifaahlalkatamsyi@gmail.com";
          _birthDateController.text = "23 April 2004";
          _mottoController.text = "Man Jadda Wa jada";
        });
      }
    } catch (e) {
      _showSnackBar('Error loading profile: $e', Colors.red);
    }
  }

  // DELETE - Reset profile data
  Future<void> _resetProfileData() async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Reset Profile',
          style:
              TextStyle(color: Color(0xffAD8B73), fontWeight: FontWeight.bold),
        ),
        content: const Text(
            'Are you sure you want to reset all profile data to default?'),
        actions: <TextButton>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performReset();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  Future<void> _performReset() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await prefs.remove('user_profile');
      await prefs.remove('profile_image');

      setState(() {
        _nameController.text = "Kaifa اhlal Katamsyi";
        _nimController.text = "123220006";
        _emailController.text = "kaifaahlalkatamsyi@gmail.com";
        _birthDateController.text = "23 April 2004";
        _mottoController.text = "Man Jadda Wa jada";
        _selectedImage = null;
        _isEditing = false;
        _isLoading = false;
      });

      _showSnackBar('Profile reset successfully!', Colors.orange);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error resetting profile: $e', Colors.red);
    }
  }

  // Load saved image path from SharedPreferences
  void _loadSavedImage() async {
    String? imagePath = prefs.getString('profile_image');
    if (imagePath != null && imagePath.isNotEmpty) {
      File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        setState(() {
          _selectedImage = imageFile;
        });
      }
    }
  }

  // Save image path to SharedPreferences
  void _saveImagePath(String path) async {
    await prefs.setString('profile_image', path);
  }

  // Show snackbar message
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Show image picker options
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

  // Build image option widget
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

  // Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Close bottom sheet

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
        _saveImagePath(pickedFile.path);
        _showSnackBar('Profile picture updated!', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', Colors.red);
    }
  }

  // Remove selected image
  void _removeImage() {
    Navigator.pop(context); // Close bottom sheet

    setState(() {
      _selectedImage = null;
    });
    prefs.remove('profile_image');
    _showSnackBar('Profile picture removed!', Colors.orange);
  }

  // Select birth date
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

  void _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Logout',
          style:
              TextStyle(color: Color(0xffAD8B73), fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: <TextButton>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await prefs.remove('username');
              if (!mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Yes', style: TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height / 3 + 50,
                        decoration: const BoxDecoration(color: Colors.white),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height / 3,
                          decoration: const BoxDecoration(
                            color: Color(0xffCEAB93),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(36),
                              bottomRight: Radius.circular(36),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 50,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Profile",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                                color: Colors.black87,
                              ),
                            ),
                            Row(
                              children: [
                                // Edit/Save Button
                                IconButton(
                                  onPressed: () {
                                    if (_isEditing) {
                                      _saveUserData();
                                    } else {
                                      setState(() {
                                        _isEditing = true;
                                      });
                                    }
                                  },
                                  icon: Icon(
                                    _isEditing ? Icons.save : Icons.edit,
                                    color: Colors.black87,
                                  ),
                                  tooltip: _isEditing ? 'Save' : 'Edit',
                                ),
                                // Reset Button
                                IconButton(
                                  onPressed: _resetProfileData,
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.black87,
                                  ),
                                  tooltip: 'Reset Profile',
                                ),
                                // Logout Button
                                IconButton(
                                  onPressed: _logout,
                                  icon: const Icon(
                                    Icons.logout_outlined,
                                    color: Colors.black87,
                                  ),
                                  tooltip: 'Logout',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Profile Picture with Camera Icon
                      Positioned(
                        left: 100,
                        top: 100,
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: _showImagePickerOptions,
                              child: CircleAvatar(
                                radius: 100,
                                backgroundColor: const Color(0xffAD8B73),
                                child: CircleAvatar(
                                  radius: 96,
                                  backgroundColor:
                                      const Color(0xffCEAB93).withOpacity(0.3),
                                  backgroundImage: _selectedImage != null
                                      ? FileImage(_selectedImage!)
                                      : null,
                                  child: _selectedImage == null
                                      ? Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.transparent,
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            size: 80,
                                            color: Color(0xffAD8B73),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            // Camera icon overlay
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: _showImagePickerOptions,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Color(0xffAD8B73),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        _nameField(),
                        const SizedBox(height: 20),
                        _nimField(),
                        const SizedBox(height: 20),
                        _emailField(),
                        const SizedBox(height: 20),
                        _birthDateField(),
                        const SizedBox(height: 20),
                        _mottoField(),
                        const SizedBox(height: 40),

                        // Action Buttons
                        if (_isEditing) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                    });
                                    _loadUserData(); // Reload original data
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Cancel',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveUserData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xffAD8B73),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Save Changes',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 20),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xffAD8B73)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _nameField() {
    return TextFormField(
      enabled: _isEditing,
      controller: _nameController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Name cannot be empty';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Name',
        labelStyle: const TextStyle(
          color: Color(0xffAD8B73),
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.account_circle,
          color: Color(0xffAD8B73),
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
      ),
    );
  }

  Widget _nimField() {
    return TextFormField(
      enabled: _isEditing,
      controller: _nimController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'NIM cannot be empty';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'NIM',
        labelStyle: const TextStyle(
          color: Color(0xffAD8B73),
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.contacts_outlined,
          color: Color(0xffAD8B73),
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
      ),
    );
  }

  Widget _emailField() {
    return TextFormField(
      enabled: _isEditing,
      controller: _emailController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email cannot be empty';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: const TextStyle(
          color: Color(0xffAD8B73),
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.email_rounded,
          color: Color(0xffAD8B73),
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
      ),
    );
  }

  Widget _birthDateField() {
    return TextFormField(
      enabled: _isEditing,
      controller: _birthDateController,
      readOnly: true,
      onTap: _selectDate,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Birth date cannot be empty';
        }
        return null;
      },
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
            ? const Icon(Icons.calendar_today,
                color: Color(0xffAD8B73), size: 20)
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

  Widget _mottoField() {
    return TextFormField(
      enabled: _isEditing,
      controller: _mottoController,
      maxLines: 2,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Motto cannot be empty';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Motto',
        labelStyle: const TextStyle(
          color: Color(0xffAD8B73),
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.note,
          color: Color(0xffAD8B73),
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
      ),
    );
  }
}
