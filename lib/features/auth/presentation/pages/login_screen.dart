import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/features/navigation/presentation/pages/bottom_navigation_screen.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/features/auth/data/datasource/remote/auth_remote_datasource.dart';
import 'package:nivaas/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:nivaas/core/services/hive/hive_service.dart';
import 'package:nivaas/features/auth/data/models/user_hive_model.dart';
import 'package:nivaas/features/auth/presentation/pages/register_screen.dart';
import 'package:nivaas/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:nivaas/features/admin/presentation/pages/admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AuthRepositoryImpl _authRepository;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    final remoteDataSource = AuthRemoteDataSource(apiClient: apiClient);
    _authRepository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      apiClient: apiClient,
    );
    _checkIfLoggedIn();
  }

  void _checkIfLoggedIn() {
    final hiveService = HiveService();
    if (hiveService.isLoggedIn()) {
      final role = hiveService.getUserRole().toLowerCase();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => role == 'admin'
                ? const AdminDashboardScreen()
                : const BottomNavigationScreen(),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final result = await _authRepository.login(email, password);

      await result.fold(
        (failure) async {
          if (mounted) {
            setState(() => _error = failure.message);
          }
        },
        (user) async {
          final hiveService = HiveService();
          final userHive = UserHiveModel.fromEntity(user);
          await hiveService.createUser(userHive);
          await hiveService.saveLoginState(user.email);
          await hiveService.saveUserRole(user.role);

          // Clear stale session caches from any previously logged-in account.
          final container = ProviderScope.containerOf(context, listen: false);
          container.invalidate(verifyProvider);
          container.invalidate(bookingsProvider);
          container.invalidate(notificationsProvider);
          container.invalidate(conversationsProvider);
          container.invalidate(reviewsProvider);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => user.isAdmin
                  ? const AdminDashboardScreen()
                  : const BottomNavigationScreen(),
            ),
          );
        },
      );
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Branding
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: primaryOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text('N',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Nivaas',
                            style: TextStyle(
                                color: primaryOrange,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Welcome back',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      'Log in to manage your bookings',
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Email
              _label('Email address'),
              const SizedBox(height: 6),
              _inputField(
                controller: _emailController,
                hint: 'name@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Password
              _label('Password'),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.45),
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withOpacity(0.25),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withOpacity(0.25),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: primaryOrange),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 4),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                  },
                  child: const Text('Forgot password?',
                      style: TextStyle(color: primaryOrange, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),

              // Error message
              if (_error.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 12),
              ],

              // Login button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    disabledBackgroundColor: primaryOrange.withOpacity(0.6),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Log in',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(color: colorScheme.outline.withOpacity(0.24)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: colorScheme.outline.withOpacity(0.24)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()));
                    },
                    child: const Text('Sign up',
                        style: TextStyle(
                            color: primaryOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
        ));
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
        ),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryOrange),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
