import 'package:flutter/material.dart';
import 'package:nivaas/screens/login_screen.dart';
import 'package:nivaas/widgets/my_button.dart';
import 'package:nivaas/widgets/my_textfield.dart';
import 'package:nivaas/core/services/hive/hive_service.dart';
import 'package:nivaas/features/auth/data/models/user_hive_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  late HiveService _hiveService;

  @override
  void initState() {
    super.initState();
    _hiveService = HiveService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _registerUser() {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    String name = _nameController.text.trim();

    // Validation
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      _showSnackBar('Please fill all fields', Colors.red);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match', Colors.red);
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters', Colors.red);
      return;
    }

    // Check if email already exists
    if (_hiveService.getUserByEmail(email) != null) {
      _showSnackBar('Email already registered', Colors.red);
      return;
    }

    // Create and save user
    final newUser = UserHiveModel(
      email: email,
      password: password,
      createdAt: DateTime.now(),
    );

    _hiveService.createUser(newUser);
    _showSnackBar('Account created successfully!', Colors.green);

    // Navigate to login after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign up to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                MyTextfield(
                  hintText: 'Full Name',
                  icon: Icons.person,
                  controller: _nameController,
                ),
                const SizedBox(height: 16),
                MyTextfield(
                  hintText: 'Email',
                  icon: Icons.email,
                  controller: _emailController,
                ),
                const SizedBox(height: 16),
                MyTextfield(
                  hintText: 'Phone Number',
                  icon: Icons.phone,
                  controller: _phoneController,
                ),
                const SizedBox(height: 16),
                MyTextfield(
                  hintText: 'Password',
                  icon: Icons.lock,
                  obscureText: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 16),
                MyTextfield(
                  hintText: 'Confirm Password',
                  icon: Icons.lock,
                  obscureText: true,
                  controller: _confirmPasswordController,
                ),
                const SizedBox(height: 30),
                MyButton(
                  text: 'Register',
                  onPressed: _registerUser,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
