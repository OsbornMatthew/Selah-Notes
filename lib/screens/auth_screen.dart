import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

// ── Minimal golden quill-on-letter icon ──────────────────────────────────────
class _SelahLogoIcon extends StatelessWidget {
  const _SelahLogoIcon({this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _QuillPainter()),
    );
  }
}

class _QuillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final gold = const Color(0xFFD4AF37);
    final goldDim = const Color(0xFFA07C20);
    final w = s.width;
    final h = s.height;

    // ── Letter (simple open rectangle, no fill) ───────────────────────────
    final letterPaint = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final lx = w * 0.08;
    final ly = h * 0.20;
    final lw = w * 0.55;
    final lh = h * 0.52;

    final letterPath = Path()
      ..moveTo(lx, ly + lh)
      ..lineTo(lx, ly)
      ..lineTo(lx + lw, ly)
      ..lineTo(lx + lw, ly + lh)
      ..lineTo(lx, ly + lh);
    canvas.drawPath(letterPath, letterPaint);

    // Three horizontal lines inside the letter (text lines)
    final linePaint = Paint()
      ..color = gold.withOpacity(0.50)
      ..strokeWidth = w * 0.030
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final y = ly + lh * (0.28 + i * 0.22);
      canvas.drawLine(Offset(lx + lw * 0.18, y), Offset(lx + lw * (i == 2 ? 0.60 : 0.82), y), linePaint);
    }

    // ── Quill feather (overlapping bottom-right corner) ───────────────────
    // Rotated ~-45° around its tip
    canvas.save();
    final pivotX = w * 0.70;
    final pivotY = h * 0.82;
    canvas.translate(pivotX, pivotY);
    canvas.rotate(-0.75);
    canvas.translate(-pivotX, -pivotY);

    // Feather body — single tapered shape
    final featherPaint = Paint()
      ..color = gold
      ..style = PaintingStyle.fill;
    final featherPath = Path();
    final tx = pivotX;
    final ty = pivotY;
    featherPath.moveTo(tx, ty); // tip
    featherPath.cubicTo(tx + w * 0.03, ty - h * 0.12, tx + w * 0.13, ty - h * 0.32, tx + w * 0.06, ty - h * 0.50);
    featherPath.cubicTo(tx + w * 0.16, ty - h * 0.46, tx + w * 0.20, ty - h * 0.28, tx + w * 0.14, ty - h * 0.08);
    featherPath.cubicTo(tx + w * 0.10, ty - h * 0.03, tx + w * 0.04, ty - h * 0.01, tx, ty);
    featherPath.close();
    canvas.drawPath(featherPath, featherPaint);

    // Feather stroke outline
    canvas.drawPath(
      featherPath,
      Paint()
        ..color = goldDim
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.020,
    );

    // Centre spine
    canvas.drawLine(
      Offset(tx, ty),
      Offset(tx + w * 0.09, ty - h * 0.44),
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..strokeWidth = w * 0.020
        ..strokeCap = StrokeCap.round,
    );

    // Dark nib at tip
    final nibPath = Path()
      ..moveTo(tx, ty)
      ..lineTo(tx + w * 0.025, ty - h * 0.06)
      ..lineTo(tx - w * 0.005, ty - h * 0.02)
      ..close();
    canvas.drawPath(nibPath, Paint()..color = Colors.black.withOpacity(0.75));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Auth Screen ───────────────────────────────────────────────────────────────
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pw = _pwCtrl.text;
    if (email.isEmpty || pw.isEmpty) {
      setState(() => _error = 'Please enter both email and password.');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    final err = _isSignUp
        ? await AuthService.signUp(email, pw)
        : await AuthService.signIn(email, pw);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (err != null) setState(() => _error = err);
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email above first.');
      return;
    }
    final err = await AuthService.sendPasswordReset(email);
    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
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
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SelahLogoIcon(size: 80),
                  const SizedBox(height: 16),
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
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.gold, size: 20),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _pwCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.gold, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppColors.textSecondary, size: 19,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                        ],
                        if (!_isSignUp) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _forgotPassword,
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                              child: const Text('Forgot password?',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
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
                                ? const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black))
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
                        : () => setState(() { _isSignUp = !_isSignUp; _error = null; }),
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
