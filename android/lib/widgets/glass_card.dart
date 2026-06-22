import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A frosted-glass card: blurred backdrop, translucent fill, soft gold border
/// and a faint top highlight to sell the "glass" look.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final VoidCallback? onTap;
  final Color? fillColor;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 18,
    this.blurSigma = 18,
    this.onTap,
    this.fillColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    Widget content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (fillColor ?? AppColors.glassFill).withOpacity(
                  (fillColor ?? AppColors.glassFill).opacity + 0.06,
                ),
                fillColor ?? AppColors.glassFill,
              ],
            ),
            border: Border.all(
              color: borderColor ?? AppColors.glassBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: AppColors.gold.withOpacity(0.08),
          highlightColor: AppColors.gold.withOpacity(0.04),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Layered dark background with soft gold glow blobs, so the glass cards
/// floating on top have something visually rich to refract.
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.bgTop, AppColors.background, AppColors.bgBottom],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Glow blob top-right
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.gold.withOpacity(0.16), Colors.transparent],
              ),
            ),
          ),
        ),
        // Glow blob bottom-left
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.goldMuted.withOpacity(0.14), Colors.transparent],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
