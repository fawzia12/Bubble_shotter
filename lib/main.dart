import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'games/game.dart'; 

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const BubbleShooterApp());
}

class BubbleShooterApp extends StatelessWidget {
  const BubbleShooterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bubble Shooter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bubbleController;
  final List<_FloatingBubble> _bubbles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

 
    for (int i = 0; i < 15; i++) {
      _bubbles.add(_FloatingBubble(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: 12 + _random.nextDouble() * 18,
        speed: 0.3 + _random.nextDouble() * 0.5,
        color: kBubbleColors[_random.nextInt(kBubbleColors.length)],
        phase: _random.nextDouble() * 2 * pi,
      ));
    }
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
         
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [Color(0xFF0D0D2B), Color(0xFF05051A), Color(0xFF02020D)],
              ),
            ),
          ),

      
          CustomPaint(
            size: size,
            painter: StarFieldPainter(),
          ),

       
          AnimatedBuilder(
            animation: _bubbleController,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: BubblePainter(
                  bubbles: _bubbles,
                  time: _bubbleController.value * 2 * pi,
                  size: size,
                ),
              );
            },
          ),

        
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // গ্লাসমরফিজম কার্ড
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 40,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.2),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // টাইটেল
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF00CFFF), Color(0xFFB44FFF)],
                            ).createShader(bounds),
                            child: const Text(
                              'BUBBLE',
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 8,
                              ),
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFFF6FD8), Color(0xFF00CFFF)],
                            ).createShader(bounds),
                            child: const Text(
                              'SHOOTER',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                       
                          _buildColorRow(),
                          const SizedBox(height: 40),
                     
                          _buildPlayButton(context),
                          const SizedBox(height: 20),
                      
                          const Text(
                            'Tap & Drag to Aim • Release to Shoot',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow() {
    const colors = [
      Color(0xFFFF4E91),
      Color(0xFF00CFFF),
      Color(0xFF7CFF6B),
      Color(0xFFFFD93D),
      Color(0xFFB44FFF),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: colors.map((c) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c,
            boxShadow: [
              BoxShadow(color: c.withOpacity(0.6), blurRadius: 14),
            ],
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const GameScreen(),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(opacity: anim, child: child);
            },
          ),
        );
      },
      child: Container(
        width: 220,
        height: 65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.6),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // রিপল ইফেক্ট (অ্যানিমেটেড)
            AnimatedBuilder(
              animation: _bubbleController,
              builder: (_, child) {
                final value = (_bubbleController.value * 2 * pi).toDouble().abs();
                return Container(
                  width: 220 + 30 * value,
                  height: 65 + 30 * value,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15 * value),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
            const Text(
              '▶  PLAY NOW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _FloatingBubble {
  final double x; // 0-1 অনুপাত
  final double y;
  final double radius;
  final double speed;
  final Color color;
  final double phase;

  _FloatingBubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.color,
    required this.phase,
  });
}

class BubblePainter extends CustomPainter {
  final List<_FloatingBubble> bubbles;
  final double time;
  final Size size;

  BubblePainter({required this.bubbles, required this.time, required this.size});

  @override
  void paint(Canvas canvas, Size _) {
    for (final b in bubbles) {
      final dx = b.x * size.width;
      final dy = b.y * size.height +
          sin(time * b.speed + b.phase) * 20; // উপরে-নিচে দোলা
      final paint = Paint()
        ..color = b.color.withOpacity(0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dx, dy), b.radius, paint);

      
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(dx - b.radius * 0.3, dy - b.radius * 0.3),
        b.radius * 0.3,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(BubblePainter old) => true;
}


class StarFieldPainter extends CustomPainter {
  final List<Offset> _stars = [];
  final List<double> _sizes = [];
  final List<double> _opacities = [];

  StarFieldPainter() {
    final rng = Random(42);
    for (int i = 0; i < 120; i++) {
      _stars.add(Offset(
        rng.nextDouble() * 1000,
        rng.nextDouble() * 2000,
      ));
      _sizes.add(rng.nextDouble() * 2.0 + 0.5);
      _opacities.add(rng.nextDouble() * 0.6 + 0.2);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (int i = 0; i < _stars.length; i++) {
      final x = _stars[i].dx % size.width;
      final y = _stars[i].dy % size.height;
      paint.color = Colors.white.withOpacity(_opacities[i]);
      canvas.drawCircle(Offset(x, y), _sizes[i], paint);
    }
  }

  @override
  bool shouldRepaint(StarFieldPainter old) => false;
}


const List<Color> kBubbleColors = [
  Color(0xFFFF4E91),
  Color(0xFF00CFFF),
  Color(0xFF7CFF6B),
  Color(0xFFFFD93D),
  Color(0xFFB44FFF),
  Color(0xFFFF7B54),
];