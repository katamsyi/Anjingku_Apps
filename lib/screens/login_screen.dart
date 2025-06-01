import 'package:flutter/material.dart';
import '../services/auth_user_service.dart';
import 'package:logger/logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final Logger logger = Logger();

  bool _isLoading = false;
  String? _errorMessage;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      logger.i('Attempt login for username: $username');

      final isValid = await AuthService.validateUser(username, password);

      logger.i('Login validation result: $isValid');

      setState(() {
        _isLoading = false;
      });

      if (isValid) {
        await AuthService.saveLoginStatus(username);

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/navbar');
      } else {
        setState(() {
          _errorMessage = 'Username atau password salah';
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color darkBrown = const Color(0xFF4E342E);
    final Color lightBrown = const Color(0xFFEFEBE9);
    final Color accentBrown = const Color(0xFF6D4C41);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [lightBrown, darkBrown.withOpacity(0.8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Card(
              elevation: 15,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              color: lightBrown,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pets,
                        size: 80,
                        color: darkBrown,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: darkBrown,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _usernameController,
                        cursorColor: darkBrown,
                        style: TextStyle(color: darkBrown),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.pets, color: darkBrown),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: accentBrown, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: darkBrown, width: 1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          labelStyle: TextStyle(color: darkBrown.withOpacity(0.7)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                        ),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Isi username' : null,
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        cursorColor: darkBrown,
                        style: TextStyle(color: darkBrown),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock, color: darkBrown),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: accentBrown, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: darkBrown, width: 1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          labelStyle: TextStyle(color: darkBrown.withOpacity(0.7)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                        ),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Isi password' : null,
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkBrown,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 8,
                            shadowColor: accentBrown.withOpacity(0.5),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          'Belum punya akun? Daftar sekarang',
                          style: TextStyle(
                            color: accentBrown,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
