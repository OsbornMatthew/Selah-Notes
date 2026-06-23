import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

// ─── Old Letter + Quill Pen Icon ─────────────────────────────────────────────
class _SelahLogoIcon extends StatelessWidget {
  const _SelahLogoIcon({this.size = 80});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LetterAndQuillPainter()),
    );
  }
}

class _LetterAndQuillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gold = const Color(0xFFD4AF37);
    final goldDim = const Color(0xFF8A7430);
    final parchment = const Color(0xFFF5E8C0);
    final parchmentDark = const Color(0xFFD4C08A);
    final ink = const Color(0xFF1A1408);

    // ── Shadow beneath letter ──
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.18, w * 0.60, h * 0.62),
        const Radius.circular(3),
      ),
      shadowPaint,
    );

    // ── Letter body (parchment) ──
    final paperPaint = Paint()..color = parchment;
    final paperRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.14, w * 0.60, h * 0.62),
      const Radius.circular(3),
    );
    canvas.drawRRect(paperRect, paperPaint);

    // parchment gradient overlay (aged look)
    final gradPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [parchmentDark.withOpacity(0.0), parchmentDark.withOpacity(0.35)],
      ).createShader(Rect.fromLTWH(w * 0.06, h * 0.14, w * 0.60, h * 0.62));
    canvas.drawRRect(paperRect, gradPaint);

    // ── Letter border ──
    final borderPaint = Paint()
      ..color = goldDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(paperRect, borderPaint);

    // ── Folded top-right corner ──
    final foldPaint = Paint()..color = parchmentDark;
    final foldPath = Path()
      ..moveTo(w * 0.66 - w * 0.10, h * 0.14)
      ..lineTo(w * 0.66, h * 0.14 + h * 0.10)
      ..lineTo(w * 0.66, h * 0.14)
      ..close();
    canvas.drawPath(foldPath, foldPaint);
    canvas.drawPath(
      foldPath,
      Paint()
        ..color = goldDim.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // ── Text lines on the letter ──
    final linePaint = Paint()
      ..color = ink.withOpacity(0.28)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final lineLeft = w * 0.13;
    final lineRight = w * 0.59;
    const lineSpacing = 0.095;
    for (int i = 0; i < 5; i++) {
      final y = h * (0.30 + i * lineSpacing);
      // shorter last line
      canvas.drawLine(
        Offset(lineLeft, y),
        Offset(i == 4 ? lineLeft + (lineRight - lineLeft) * 0.55 : lineRight, y),
        linePaint,
      );
    }

    // ── Decorative wax-seal dot ──
    final sealPaint = Paint()..color = gold.withOpacity(0.85);
    canvas.drawCircle(Offset(w * 0.36, h * 0.76), w * 0.045, sealPaint);
    canvas.drawCircle(
      Offset(w * 0.36, h * 0.76),
      w * 0.045,
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ─── Quill Pen (overlapping bottom-right) ───────────────────────────────
    canvas.save();
    // rotate the quill ~-40°, pivot around its tip
    final tipX = w * 0.72;
    final tipY = h * 0.80;
    canvas.translate(tipX, tipY);
    canvas.rotate(-0.70); // ~-40 degrees
    canvas.translate(-tipX, -tipY);

    // Feather shape
    final featherPath = Path();
    featherPath.moveTo(tipX, tipY); // tip
    // right edge of feather
    featherPath.cubicTo(
      tipX + w * 0.04, tipY - h * 0.10,
      tipX + w * 0.14, tipY - h * 0.30,
      tipX + w * 0.08, tipY - h * 0.52,
    );
    // top of feather (barbs fan out)
    featherPath.cubicTo(
      tipX + w * 0.18, tipY - h * 0.48,
      tipX + w * 0.22, tipY - h * 0.28,
      tipX + w * 0.16, tipY - h * 0.10,
    );
    // left edge
    featherPath.cubicTo(
      tipX + w * 0.12, tipY - h * 0.04,
      tipX + w * 0.05, tipY - h * 0.02,
      tipX, tipY,
    );
    featherPath.close();

    // Feather fill — gold gradient
    final featherFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [gold, goldDim],
      ).createShader(Rect.fromLTWH(tipX, tipY - h * 0.55, w * 0.25, h * 0.55));
    canvas.drawPath(featherPath, featherFill);

    // Feather stroke
    canvas.drawPath(
      featherPath,
      Paint()
        ..color = goldDim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Quill spine
    final spinePaint = Paint()
      ..color = parchmentDark
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(tipX, tipY),
      Offset(tipX + w * 0.11, tipY - h * 0.46),
      spinePaint,
    );

    // Barb lines on the feather
    final barbPaint = Paint()
      ..color = goldDim.withOpacity(0.45)
      ..strokeWidth = 0.7;
    for (int i = 1; i <= 5; i++) {
      final t = i / 6.0;
      final bx = tipX + w * 0.11 * t;
      final by = tipY - h * 0.46 * t;
      canvas.drawLine(
        Offset(bx, by),
        Offset(bx + w * 0.06 * (1 - t * 0.4), by - h * 0.05),
        barbPaint,
      );
      canvas.drawLine(
        Offset(bx, by),
        Offset(bx + w * 0.05 * (1 - t * 0.4), by + h * 0.04),
        barbPaint,
      );
    }

    // Nib (dark tip)
    final nibPaint = Paint()..color = ink.withOpacity(0.85);
    final nibPath = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(tipX + w * 0.025, tipY - h * 0.055)
      ..lineTo(tipX + w * 0.005, tipY - h * 0.025)
      ..close();
    canvas.drawPath(nibPath, nibPaint);

    // Ink drop at nib tip
    final inkPaint = Paint()..color = ink.withOpacity(0.70);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(tipX - w * 0.005, tipY + h * 0.012),
        width: w * 0.022,
        height: h * 0.018,
      ),
      inkPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Auth Screen ──────────────────────────────────────────────────────────────
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
                  const _SelahLogoIcon(size: 88),
                  const SizedBox(height: 14),
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
                            prefixIcon: Icon(Icons.mail_outline_rounded,
                                color: AppColors.gold, size: 20),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: AppColors.gold, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textSecondary,
                                size: 19,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorText!,
                            style: const TextStyle(
                                color: AppColors.danger, fontSize: 13),
                          ),
                        ],
                        if (!_isSignUp) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _forgotPassword,
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 32)),
                              child: const Text('Forgot password?',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5)),
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
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.4, color: Colors.black),
                                  )
                                : Text(
                                    _isSignUp ? 'Create Account' : 'Log In',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15.5),
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
                      _isSignUp
                          ? 'Already have an account? Log in'
                          : "Don't have an account? Sign up",
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13.5),
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
