import 'package:flutter/material.dart';
import 'package:nivaas/features/auth/presentation/pages/login_screen.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/features/auth/data/datasource/remote/auth_remote_datasource.dart';
import 'package:nivaas/features/auth/data/repositories/auth_repository_impl.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late AuthRepositoryImpl _authRepository;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
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
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final name = '$firstName $lastName'.trim();
      final result = await _authRepository.register(
        name,
        email,
        password,
        phone,
        confirmPassword: confirmPassword,
      );

      result.fold(
        (failure) {
          setState(() => _error = failure.message);
        },
        (user) {
          // Navigate to login on success
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
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
              const SizedBox(height: 24),
              // Back arrow
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 20),

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
                    const Text('Create an account',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      'Join Nivaas to start your adventure',
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // First Name & Last Name (side by side like web)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('First name'),
                        const SizedBox(height: 6),
                        _inputField(
                          controller: _firstNameController,
                          hint: 'John',
                          icon: Icons.person_outline,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Last name'),
                        const SizedBox(height: 6),
                        _inputField(
                          controller: _lastNameController,
                          hint: 'Doe',
                          icon: Icons.person_outline,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Email
              _label('Email address'),
              const SizedBox(height: 6),
              _inputField(
                controller: _emailController,
                hint: 'name@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),

              // Phone
              _label('Phone number'),
              const SizedBox(height: 6),
              _inputField(
                controller: _phoneController,
                hint: '+977 98XXXXXXXX',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),

              // Password
              _label('Password'),
              const SizedBox(height: 6),
              _passwordField(
                controller: _passwordController,
                hint: '••••••••',
                obscure: _obscurePassword,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 18),

              // Confirm Password
              _label('Confirm password'),
              const SizedBox(height: 6),
              _passwordField(
                controller: _confirmPasswordController,
                hint: '••••••••',
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 20),

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

              // Register button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
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
                      : const Text('Create account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Log in',
                        style: TextStyle(
                            color: primaryOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          onPressed: onToggle,
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
