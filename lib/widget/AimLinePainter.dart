import 'package:flutter/material.dart';

class AimLinePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  AimLinePainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i += 10) {
      final radius = 3.0 - (i / points.length) * 2.5;
      if (radius > 0) {
        canvas.drawCircle(points[i], radius, dotPaint);
      }
    }

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (final p in points) {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(AimLinePainter old) => true;
}