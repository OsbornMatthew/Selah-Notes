import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A frosted-glass card with a subtle gold border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: radius,
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: radius,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A gradient background that gives the glass cards something to float on.
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgTop, AppColors.bgBottom],
        ),
      ),
      child: child,
    );
  }
}
