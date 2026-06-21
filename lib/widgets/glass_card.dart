import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double blurSigma;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.blurSigma = 8,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    Widget card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: radius,
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: radius,
              border: Border.all(color: borderColor ?? AppColors.glassBorder),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (margin != null) {
      return Container(margin: margin, child: card);
    }
    return card;
  }
}

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
