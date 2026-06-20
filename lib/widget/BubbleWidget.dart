import 'package:flutter/material.dart';

class BubbleWidget extends StatelessWidget {
  final Color color;
  final double radius;

  const BubbleWidget({required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.9,
          colors: [
            Color.lerp(color, Colors.white, 0.4)!,
            color,
            Color.lerp(color, Colors.black, 0.3)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Align(
        alignment: const Alignment(-0.3, -0.35),
        child: Container(
          width: radius * 0.45,
          height: radius * 0.3,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}
