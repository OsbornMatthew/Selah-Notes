import 'package:flutter/material.dart';

/// A simple, elegant feather silhouette drawn with CustomPainter — used as
/// the brand mark above "Selah Notes" on the sign-in / sign-up screen.
class FeatherIcon extends StatelessWidget {
  final double size;
  final Color color;
  const FeatherIcon({super.key, this.size = 44, this.color = const Color(0xFFD4AF37)});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FeatherPainter(color: color),
      ),
    );
  }
}

class _FeatherPainter extends CustomPainter {
  final Color color;
  _FeatherPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round;

    // Main plume: a tapered leaf-like shape running from the tip (top-right)
    // down to the base (bottom-left), with a gentle outward bow on each side.
    final plume = Path()
      ..moveTo(w * 0.82, h * 0.06) // tip
      ..quadraticBezierTo(w * 0.98, h * 0.34, w * 0.62, h * 0.62)
      ..quadraticBezierTo(w * 0.40, h * 0.82, w * 0.18, h * 0.95) // base
      ..quadraticBezierTo(w * 0.30, h * 0.70, w * 0.46, h * 0.50)
      ..quadraticBezierTo(w * 0.60, h * 0.32, w * 0.82, h * 0.06)
      ..close();
    canvas.drawPath(plume, fillPaint);

    // Central spine (quill shaft) running through the plume.
    final spine = Path()
      ..moveTo(w * 0.80, h * 0.10)
      ..quadraticBezierTo(w * 0.46, h * 0.46, w * 0.20, h * 0.92);
    canvas.drawPath(spine, strokePaint..color = color.withOpacity(0.55));

    // Barb lines fanning off the spine on the upper-right side, evoking the
    // texture of a feather's vane.
    final barbPaint = Paint()
      ..color = color.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.016
      ..strokeCap = StrokeCap.round;

    final barbStarts = [
      Offset(w * 0.70, h * 0.20),
      Offset(w * 0.60, h * 0.32),
      Offset(w * 0.50, h * 0.44),
      Offset(w * 0.40, h * 0.56),
      Offset(w * 0.30, h * 0.68),
    ];
    final barbEnds = [
      Offset(w * 0.88, h * 0.30),
      Offset(w * 0.80, h * 0.40),
      Offset(w * 0.70, h * 0.50),
      Offset(w * 0.58, h * 0.60),
      Offset(w * 0.46, h * 0.70),
    ];
    for (var i = 0; i < barbStarts.length; i++) {
      canvas.drawLine(barbStarts[i], barbEnds[i], barbPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FeatherPainter oldDelegate) =>
      oldDelegate.color != color;
}
