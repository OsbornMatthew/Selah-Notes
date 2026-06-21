import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firebase_sync_service.dart';
import 'folders_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  static const _gold = Color(0xFFFFD700);
  static const _bg = Color(0xFF0D0D0D);

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await AuthService.signIn(_emailCtrl.text, _passCtrl.text);
      } else {
        await AuthService.signUp(_emailCtrl.text, _passCtrl.text);
      }
      // Pull data from Firestore after login
      await FirebaseSyncService.syncFromFirestore();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FoldersScreen()),
        );
      }
    } on Exception catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _resetPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() { _error = 'Enter your email first.'; });
      return;
    }
    await AuthService.resetPassword(_emailCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo / Title
                const Icon(Icons.auto_stories_rounded, color: _gold, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Selah Notes',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Welcome back' : 'Create your account',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // Email field
                _GoldField(controller: _emailCtrl, label: 'Email', obscure: false),
                const SizedBox(height: 16),

                // Password field
                _GoldField(controller: _passCtrl, label: 'Password', obscure: true),
                const SizedBox(height: 8),

                // Error message
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                            _isLogin ? 'Sign In' : 'Sign Up',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Toggle login / signup
                TextButton(
                  onPressed: () => setState(() { _isLogin = !_isLogin; _error = null; }),
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign up"
                        : 'Already have an account? Sign in',
                    style: const TextStyle(color: _gold),
                  ),
                ),

                if (_isLogin)
                  TextButton(
                    onPressed: _resetPassword,
                    child: const Text('Forgot password?', style: TextStyle(color: Colors.white38)),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  const _GoldField({required this.controller, required this.label, required this.obscure});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: obscure ? TextInputType.visiblePassword : TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
    );
  }
}
