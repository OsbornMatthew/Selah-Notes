import 'package:flutter/material.dart';
import 'package:pattern_lock/pattern_lock.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/notes_database.dart';

enum PatternLockMode { setup, verify }

class PatternLockScreen extends StatefulWidget {
  final PatternLockMode mode;
  const PatternLockScreen({super.key, required this.mode});

  @override
  State<PatternLockScreen> createState() => _PatternLockScreenState();
}

class _PatternLockScreenState extends State<PatternLockScreen> {
  List<int>? _firstPattern;
  String _message = '';
  bool _isError = false;

  String get _title {
    if (widget.mode == PatternLockMode.verify) return 'Archive Locked';
    return _firstPattern == null ? 'Set Archive Pattern' : 'Confirm Pattern';
  }

  String get _subtitle {
    if (widget.mode == PatternLockMode.verify) return 'Draw your pattern to unlock';
    return _firstPattern == null ? 'Draw a pattern to protect your archive' : 'Draw the same pattern again';
  }

  Future<void> _onPatternComplete(List<int> pattern) async {
    if (pattern.length < 4) {
      setState(() { _message = 'Pattern too short. Use at least 4 dots.'; _isError = true; });
      return;
    }

    if (widget.mode == PatternLockMode.verify) {
      final saved = await NotesService.getArchivePattern();
      final entered = pattern.join(',');
      if (entered == saved) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() { _message = 'Wrong pattern. Try again.'; _isError = true; });
      }
      return;
    }

    // Setup mode
    if (_firstPattern == null) {
      setState(() { _firstPattern = pattern; _message = ''; _isError = false; });
    } else {
      if (pattern.join(',') == _firstPattern!.join(',')) {
        await NotesService.saveArchivePattern(pattern.join(','));
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() { _firstPattern = null; _message = "Patterns don't match. Start again."; _isError = true; });
      }
    }
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
                  const SizedBox(height: kToolbarHeight + 24),
                  const Icon(Icons.lock_outline_rounded, color: AppColors.gold, size: 48),
                  const SizedBox(height: 16),
                  Text(_subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 8),
                  if (_message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(_message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _isError ? AppColors.danger : AppColors.gold, fontSize: 13)),
                    ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: PatternLock(
                        selectedColor: AppColors.gold,
                        notSelectedColor: AppColors.textSecondary,
                        pointRadius: 9,
                        showInput: true,
                        dimension: 3,
                        relativePadding: 0.7,
                        fillPoints: true,
                        onInputComplete: _onPatternComplete,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
