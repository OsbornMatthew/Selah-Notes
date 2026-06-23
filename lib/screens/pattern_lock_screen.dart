import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/notes_database.dart';

enum PatternLockMode { setup, verify, change }

const int _kPasswordLength = 8;

class PatternLockScreen extends StatefulWidget {
  final PatternLockMode mode;
  const PatternLockScreen({super.key, required this.mode});

  @override
  State<PatternLockScreen> createState() => _PatternLockScreenState();
}

class _PatternLockScreenState extends State<PatternLockScreen> {
  // Stages: for `change` mode we first verify the OLD password, then move
  // into a setup-style flow (enter new, confirm new).
  bool _oldVerified = false;
  String? _firstEntry;
  String _input = '';
  String _message = '';
  bool _isError = false;
  bool _isShaking = false;

  bool get _isChangeMode => widget.mode == PatternLockMode.change;
  bool get _needsOldPassword => _isChangeMode && !_oldVerified;
  bool get _isVerifyStage => widget.mode == PatternLockMode.verify || _needsOldPassword;

  String get _title {
    if (widget.mode == PatternLockMode.verify) return 'Archive Locked';
    if (_needsOldPassword) return 'Enter Current Password';
    if (_isChangeMode) return _firstEntry == null ? 'Set New Password' : 'Confirm New Password';
    return _firstEntry == null ? 'Set Archive Password' : 'Confirm Password';
  }

  String get _subtitle {
    if (widget.mode == PatternLockMode.verify) return 'Enter your 8-digit password to unlock';
    if (_needsOldPassword) return 'Enter your current password to continue';
    if (_isChangeMode) return _firstEntry == null
        ? 'Enter a new 8-digit password'
        : 'Enter the new password again';
    return _firstEntry == null
        ? 'Create an 8-digit password to protect your archive'
        : 'Enter the same password again';
  }

  void _onDigit(String digit) {
    if (_input.length >= _kPasswordLength) return;
    setState(() {
      _input += digit;
      _message = '';
      _isError = false;
    });
    if (_input.length == _kPasswordLength) {
      Future.delayed(const Duration(milliseconds: 150), _submit);
    }
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _shakeAndReset({required String message}) async {
    setState(() { _isError = true; _message = message; _isShaking = true; });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() { _input = ''; _isShaking = false; });
  }

  Future<void> _submit() async {
    final entered = _input;

    // Verify mode (or the "enter old password" stage of change mode)
    if (_isVerifyStage) {
      final saved = await NotesService.getArchivePassword();
      if (entered == saved) {
        if (_needsOldPassword) {
          setState(() { _oldVerified = true; _input = ''; _message = ''; _isError = false; });
        } else {
          if (mounted) Navigator.pop(context, true);
        }
      } else {
        await _shakeAndReset(message: 'Wrong password. Try again.');
      }
      return;
    }

    // Setup / change new-password flow
    if (_firstEntry == null) {
      setState(() { _firstEntry = entered; _input = ''; _message = ''; _isError = false; });
    } else {
      if (entered == _firstEntry) {
        await NotesService.saveArchivePassword(entered);
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() { _firstEntry = null; _input = ''; });
        await _shakeAndReset(message: "Passwords don't match. Start again.");
      }
    }
  }

  Widget _buildDots() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_isShaking),
      tween: Tween(begin: 0, end: _isShaking ? 1 : 0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticIn,
      builder: (context, value, child) {
        final shakeOffset = _isShaking ? (8.0 * (1 - value)) * (((value * 10).floor() % 2 == 0) ? 1 : -1) : 0.0;
        return Transform.translate(offset: Offset(shakeOffset, 0), child: child);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_kPasswordLength, (i) {
          final filled = i < _input.length;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? (_isError ? AppColors.danger : AppColors.gold)
                  : Colors.transparent,
              border: Border.all(
                color: _isError ? AppColors.danger : AppColors.gold,
                width: 1.5,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKey(String label, {VoidCallback? onTap, Widget? child}) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              splashColor: AppColors.gold.withOpacity(0.15),
              highlightColor: AppColors.gold.withOpacity(0.08),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.glassFill,
                  border: Border.all(color: AppColors.glassBorder),
                ),
                alignment: Alignment.center,
                child: child ??
                    Text(label,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(children: [
          _buildKey('1', onTap: () => _onDigit('1')),
          _buildKey('2', onTap: () => _onDigit('2')),
          _buildKey('3', onTap: () => _onDigit('3')),
        ]),
        Row(children: [
          _buildKey('4', onTap: () => _onDigit('4')),
          _buildKey('5', onTap: () => _onDigit('5')),
          _buildKey('6', onTap: () => _onDigit('6')),
        ]),
        Row(children: [
          _buildKey('7', onTap: () => _onDigit('7')),
          _buildKey('8', onTap: () => _onDigit('8')),
          _buildKey('9', onTap: () => _onDigit('9')),
        ]),
        Row(children: [
          _buildKey('', child: const SizedBox.shrink()),
          _buildKey('0', onTap: () => _onDigit('0')),
          _buildKey('',
              onTap: _onBackspace,
              child: const Icon(Icons.backspace_outlined, color: AppColors.textSecondary, size: 22)),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context, false)),
      ),
      body: GlassBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - kToolbarHeight - statusBarHeight,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: kToolbarHeight + 24),
                  const Icon(Icons.lock_outline_rounded, color: AppColors.gold, size: 44),
                  const SizedBox(height: 16),
                  Text(_subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 8),
                  if (_message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(_message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _isError ? AppColors.danger : AppColors.gold, fontSize: 13)),
                    ),
                  const SizedBox(height: 28),
                  _buildDots(),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: _buildKeypad(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
