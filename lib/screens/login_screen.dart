import 'package:flutter/material.dart';
import 'package:nivaas/screens/bottom_navigation_screen.dart';
import 'package:nivaas/widgets/my_button.dart';
import 'package:nivaas/widgets/my_textfield.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:nivaas/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:nivaas/core/services/hive/hive_service.dart';
import 'package:nivaas/features/auth/data/models/user_hive_model.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AuthRepositoryImpl _authRepository;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    final remoteDataSource = AuthRemoteDataSource(apiClient: apiClient);
    _authRepository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      apiClient: apiClient,
    );

    // Check if already logged in
    _checkIfLoggedIn();
  }

  void _checkIfLoggedIn() {
    final hiveService = HiveService();
    if (hiveService.isLoggedIn()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavigationScreen()),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _loginUser() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Validation
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter email and password', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authRepository.login(email, password);

      result.fold(
        (failure) {
          _showSnackBar(failure.message, Colors.red);
        },
        (user) {
          // Save user to Hive
          final hiveService = HiveService();
          final userHive = UserHiveModel.fromEntity(user);
          hiveService.createUser(userHive);
          hiveService.saveLoginState(user.email);
          // Token is saved in apiClient

          _showSnackBar('Login successful!', Colors.green);
          // Navigate to home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BottomNavigationScreen()),
          );
        },
      );
    } catch (e) {
      _showSnackBar('An error occurred: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Log In To",
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/images/logo.png',
                        height: 45,
                        fit: BoxFit.contain,
                        semanticLabel: 'Nivaas logo',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                MyTextfield(
                  hintText: 'Email',
                  icon: Icons.email,
                  controller: _emailController,
                ),
                const SizedBox(height: 20),
                MyTextfield(
                  hintText: 'Password',
                  icon: Icons.lock,
                  obscureText: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 20),
                MyButton(
                  text: _isLoading ? 'Logging in...' : 'Login',
                  onPressed: _isLoading ? null : _loginUser,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Register',
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
