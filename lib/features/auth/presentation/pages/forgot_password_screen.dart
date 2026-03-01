import 'package:flutter/material.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/features/auth/data/datasource/remote/auth_remote_datasource.dart';
import 'package:nivaas/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:nivaas/features/auth/presentation/pages/login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late AuthRepositoryImpl _authRepository;

  bool _isLoading = false;
  bool _otpSent = false;
  String _message = '';
  bool _isError = false;

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
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setMessage(String msg, {bool isError = false}) {
    setState(() {
      _message = msg;
      _isError = isError;
    });
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _setMessage('Please enter your email', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    _setMessage('');

    final result = await _authRepository.forgotPassword(email);
    result.fold(
      (failure) => _setMessage(failure.message, isError: true),
      (msg) {
        _setMessage(msg);
        setState(() => _otpSent = true);
      },
    );

    setState(() => _isLoading = false);
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (otp.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _setMessage('Please fill all fields', isError: true);
      return;
    }

    if (password.length < 6) {
      _setMessage('Password must be at least 6 characters', isError: true);
      return;
    }

    if (password != confirmPassword) {
      _setMessage('Passwords do not match', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    _setMessage('');

    final result = await _authRepository.resetPassword(email, otp, password, confirmPassword);
    result.fold(
      (failure) => _setMessage(failure.message, isError: true),
      (msg) {
        _setMessage(msg);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        });
      },
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colorScheme.onSurface.withOpacity(0.9),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.lock_reset, size: 40, color: primaryOrange),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Forgot Password',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _otpSent
                      ? 'Enter the OTP sent to your email'
                      : 'We\'ll email you an OTP to reset your password',
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Email field
              _buildField(
                controller: _emailController,
                label: 'Email address',
                hint: 'name@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: !_otpSent,
              ),
              const SizedBox(height: 16),

              // Message
              if (_message.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _message,
                    style: TextStyle(
                      color: _isError ? Colors.red.shade700 : Colors.green.shade700,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Send OTP button
              if (!_otpSent)
                _buildButton(
                  text: _isLoading ? 'Sending OTP...' : 'Send OTP',
                  onPressed: _isLoading ? null : _sendOtp,
                ),

              // Reset section (shown after OTP sent)
              if (_otpSent) ...[
                const Divider(height: 32),
                _buildField(
                  controller: _otpController,
                  label: 'OTP',
                  hint: '6-digit code',
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _passwordController,
                  label: 'New password',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscure: true,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _confirmPasswordController,
                  label: 'Confirm password',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscure: true,
                ),
                const SizedBox(height: 24),
                _buildButton(
                  text: _isLoading ? 'Resetting...' : 'Reset Password',
                  onPressed: _isLoading ? null : _resetPassword,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    child: const Text('Resend OTP', style: TextStyle(color: primaryOrange)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
          ),
        ),
        
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            filled: true,
            fillColor: enabled
                ? Theme.of(context).colorScheme.surfaceContainerLow
                : Theme.of(context).colorScheme.surfaceContainerHighest,
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
        ),
      ],
    );
  }

  Widget _buildButton({required String text, VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
