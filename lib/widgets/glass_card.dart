import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// High-performance glass card.
///
/// BackdropFilter (blur) is the single biggest GPU cost on Android —
/// every card with blur = one full offscreen render pass per frame.
/// Strategy:
///   • Cards on scrollable lists → NO blur (imperceptible when moving)
///   • Modal sheets / dialogs  → blur (static, one-shot cost)
///   • Background glow blobs   → pre-painted, no blur needed
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;   // pass 0 to skip blur entirely (default for lists)
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? fillColor;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 18,
    this.blurSigma = 0,       // ← default: NO blur → smooth scrolling
    this.onTap,
    this.onLongPress,
    this.fillColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final fill = fillColor ?? AppColors.glassFill;
    final border = borderColor ?? AppColors.glassBorder;

    // Inner decorated box — always built
    Widget inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            fill.withOpacity((fill.opacity + 0.06).clamp(0, 1)),
            fill,
          ],
        ),
        border: Border.all(color: border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    // Only wrap in ClipRRect + BackdropFilter when blur is explicitly requested
    Widget content;
    if (blurSigma > 0) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: inner,
        ),
      );
    } else {
      // No blur — just clip for the border-radius
      content = ClipRRect(borderRadius: radius, child: inner);
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null || onLongPress != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
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

/// Layered dark background — uses RepaintBoundary so the background
/// is rasterized once and never re-painted during scroll.
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Static background — isolated from repaints by RepaintBoundary
        RepaintBoundary(
          child: Stack(
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
                top: -80, right: -60,
                child: Container(
                  width: 260, height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.gold.withOpacity(0.14),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              // Glow blob bottom-left
              Positioned(
                bottom: -100, left: -80,
                child: Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.goldMuted.withOpacity(0.12),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}
