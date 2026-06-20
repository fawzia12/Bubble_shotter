import 'dart:math';
import 'package:flutter/material.dart';

class StarsPainter extends CustomPainter {
  final int seed;
  StarsPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final paint = Paint()..color = Colors.white;

    for (int i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.5 + 0.3;
      final opacity = rng.nextDouble() * 0.6 + 0.1;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
