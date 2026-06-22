import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorText = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final error = _isSignUp
        ? await AuthService.signUp(email, password)
        : await AuthService.signIn(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorText = error);
    }
    // On success, the auth state stream in main.dart automatically
    // navigates to the home screen — nothing else to do here.
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorText = 'Enter your email above first, then tap "Forgot password".');
      return;
    }
    final error = await AuthService.sendPasswordReset(email);
    if (!mounted) return;
    if (error != null) {
      setState(() => _errorText = error);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent. Check your inbox.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.spa_outlined, color: AppColors.gold, size: 44),
                  const SizedBox(height: 12),
                  const Text(
                    'Selah Notes',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUp ? 'Create an account to begin' : 'Welcome back',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  GlassCard(
                    blurSigma: 22,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.gold, size: 20),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.gold, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppColors.textSecondary,
                                size: 19,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorText!,
                            style: const TextStyle(color: AppColors.danger, fontSize: 13),
                          ),
                        ],
                        if (!_isSignUp) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _forgotPassword,
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                              child: const Text('Forgot password?', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black),
                                  )
                                : Text(
                                    _isSignUp ? 'Create Account' : 'Log In',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _errorText = null;
                            }),
                    child: Text(
                      _isSignUp ? 'Already have an account? Log in' : "Don't have an account? Sign up",
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
