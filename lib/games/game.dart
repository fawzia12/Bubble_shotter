import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widget/AimLinePainter.dart';
import '../widget/BubbleWidget.dart';
import '../widget/StarsPainter.dart';
import '../widget/ShooterBasePainter.dart';

const List<Color> kBubbleColors = [
  Color(0xFFFF4E91),
  Color(0xFF00CFFF),
  Color(0xFF7CFF6B),
  Color(0xFFFFD93D),
  Color(0xFFB44FFF),
  Color(0xFFFF7B54),
];

class BubbleModel {
  double x;
  double y;
  Color color;
  bool alive;

  BubbleModel({
    required this.x,
    required this.y,
    required this.color,
    this.alive = true,
  });
}

class ShooterBubble {
  double x;
  double y;
  double dx;
  double dy;
  Color color;
  bool moving;

  ShooterBubble({
    required this.x,
    required this.y,
    required this.color,
    this.dx = 0,
    this.dy = 0,
    this.moving = false,
  });
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const int kCols = 8;
  static const int kRows = 10;
  static const double kBubbleRadius = 22;
  static const double kSpeed = 10.0;

  List<BubbleModel?> grid = [];
  ShooterBubble? shooterBubble;
  Color nextColor = kBubbleColors[0];
  Color currentColor = kBubbleColors[1];

  double shooterX = 0;
  double aimX = 0;
  double aimY = 0;
  bool isAiming = false;

  int score = 0;
  int level = 1;
  bool gameOver = false;
  bool gameWon = false;

  Timer? gameTimer;
  final Random rng = Random();

  double get bubbleDiameter => kBubbleRadius * 2;

  late AnimationController _shooterPulse;

  @override
  void initState() {
    super.initState();
    _shooterPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGame();
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _shooterPulse.dispose();
    super.dispose();
  }

  void _initGame() {
    final size = MediaQuery.of(context).size;
    shooterX = size.width / 2;

    grid = List.filled(kCols * kRows, null);

    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < kCols; col++) {
        final index = row * kCols + col;
        grid[index] = BubbleModel(
          x: _colToX(col, row),
          y: _rowToY(row),
          color: kBubbleColors[rng.nextInt(kBubbleColors.length)],
        );
      }
    }

    currentColor = kBubbleColors[rng.nextInt(kBubbleColors.length)];
    nextColor = kBubbleColors[rng.nextInt(kBubbleColors.length)];

    gameOver = false;
    gameWon = false;
    score = 0;
    level = 1;

    setState(() {});
  }

  double _colToX(int col, int row) {
    final size = MediaQuery.of(context).size;
    final startX = (size.width - kCols * bubbleDiameter) / 2;
    final offset = (row % 2 == 0) ? 0.0 : kBubbleRadius;
    return startX + col * bubbleDiameter + kBubbleRadius + offset;
  }

  double _rowToY(int row) {
    return 199.0 + row * (kBubbleRadius * 1.75);
  }

  void _shoot(double targetX, double targetY) {
    if (shooterBubble != null && shooterBubble!.moving) return;
    if (gameOver || gameWon) return;

    final size = MediaQuery.of(context).size;

    final startY = size.height - 190;

    final dx = targetX - shooterX;
    final dy = targetY - startY;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist == 0 || dy >= 0) return;

    final ndx = (dx / dist) * kSpeed;
    final ndy = (dy / dist) * kSpeed;

    shooterBubble = ShooterBubble(
      x: shooterX,
      y: startY,
      dx: ndx,
      dy: ndy,
      color: currentColor,
      moving: true,
    );

    currentColor = nextColor;
    nextColor = kBubbleColors[rng.nextInt(kBubbleColors.length)];

    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), _tick);

    setState(() {});
  }

  void _tick(Timer timer) {
    if (shooterBubble == null || !shooterBubble!.moving) {
      timer.cancel();
      return;
    }

    final size = MediaQuery.of(context).size;
    final b = shooterBubble!;

    b.x += b.dx;
    b.y += b.dy;

    if (b.x - kBubbleRadius < 0) {
      b.x = kBubbleRadius;
      b.dx = -b.dx;
    } else if (b.x + kBubbleRadius > size.width) {
      b.x = size.width - kBubbleRadius;
      b.dx = -b.dx;
    }

    if (b.y - kBubbleRadius < 60) {
      b.moving = false;
      timer.cancel();
      _snapToGrid(b);
      return;
    }

    for (int i = 0; i < grid.length; i++) {
      final g = grid[i];
      if (g == null || !g.alive) continue;

      final dist = sqrt(pow(b.x - g.x, 2) + pow(b.y - g.y, 2));
      if (dist < bubbleDiameter - 4) {
        b.moving = false;
        timer.cancel();
        _snapToGrid(b);
        return;
      }
    }

    if (mounted) setState(() {});
  }

  void _snapToGrid(ShooterBubble b) {
    int bestRow = 0;
    int bestCol = 0;
    double bestDist = double.infinity;

    for (int row = 0; row < kRows; row++) {
      for (int col = 0; col < kCols; col++) {
        final index = row * kCols + col;
        if (grid[index] != null && grid[index]!.alive) continue;

        final gx = _colToX(col, row);
        final gy = _rowToY(row);
        final dist = sqrt(pow(b.x - gx, 2) + pow(b.y - gy, 2));

        if (dist < bestDist) {
          bestDist = dist;
          bestRow = row;
          bestCol = col;
        }
      }
    }

    final index = bestRow * kCols + bestCol;
    grid[index] = BubbleModel(
      x: _colToX(bestCol, bestRow),
      y: _rowToY(bestRow),
      color: b.color,
    );

    shooterBubble = null;

    _findAndPop(bestRow, bestCol, b.color);
    _checkGameOver();

    setState(() {});
  }

  void _findAndPop(int row, int col, Color color) {
    final visited = <int>{};
    final matched = <int>[];

    void dfs(int r, int c) {
      if (r < 0 || r >= kRows || c < 0 || c >= kCols) return;
      final i = r * kCols + c;
      if (visited.contains(i)) return;
      final cell = grid[i];
      if (cell == null || !cell.alive || cell.color != color) return;

      visited.add(i);
      matched.add(i);

      final isOdd = r % 2 == 1;
      dfs(r, c - 1);
      dfs(r, c + 1);
      dfs(r - 1, c);
      dfs(r + 1, c);
      if (isOdd) {
        dfs(r - 1, c + 1);
        dfs(r + 1, c + 1);
      } else {
        dfs(r - 1, c - 1);
        dfs(r + 1, c - 1);
      }
    }

    dfs(row, col);

    if (matched.length >= 3) {
      for (final i in matched) {
        grid[i] = null;
      }
      score += matched.length * 10 * level;
      _dropFloating();
    }
  }

  void _dropFloating() {
    final connected = <int>{};

    for (int col = 0; col < kCols; col++) {
      final i = col;
      if (grid[i] != null && grid[i]!.alive) {
        _markConnected(0, col, connected);
      }
    }

    for (int i = 0; i < grid.length; i++) {
      if (grid[i] != null && grid[i]!.alive && !connected.contains(i)) {
        grid[i] = null;
        score += 5;
      }
    }
  }

  void _markConnected(int row, int col, Set<int> visited) {
    if (row < 0 || row >= kRows || col < 0 || col >= kCols) return;
    final i = row * kCols + col;
    if (visited.contains(i)) return;
    if (grid[i] == null || !grid[i]!.alive) return;

    visited.add(i);

    final isOdd = row % 2 == 1;
    _markConnected(row, col - 1, visited);
    _markConnected(row, col + 1, visited);
    _markConnected(row - 1, col, visited);
    _markConnected(row + 1, col, visited);
    if (isOdd) {
      _markConnected(row - 1, col + 1, visited);
      _markConnected(row + 1, col + 1, visited);
    } else {
      _markConnected(row - 1, col - 1, visited);
      _markConnected(row + 1, col - 1, visited);
    }
  }

  void _checkGameOver() {
    final size = MediaQuery.of(context).size;
    bool anyAlive = false;

    for (int i = 0; i < grid.length; i++) {
      if (grid[i] != null && grid[i]!.alive) {
        anyAlive = true;
        if (grid[i]!.y > size.height - 200) {
          setState(() => gameOver = true);
          return;
        }
      }
    }

    if (!anyAlive) {
      setState(() => gameWon = true);
    }
  }

  List<Offset> _getAimLine(double targetX, double targetY, Size size) {
    final points = <Offset>[];
    double x = shooterX;

    double startY = size.height - 190;
    double dx = targetX - x;
    double dy = targetY - startY;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0 || dy >= 0) return points;

    dx = (dx / dist) * kSpeed;
    dy = (dy / dist) * kSpeed;

    int steps = 0;
    while (startY > 80 && steps < 200) {
      points.add(Offset(x, startY));
      x += dx;
      startY += dy;
      if (x < kBubbleRadius) {
        x = kBubbleRadius;
        dx = -dx;
      } else if (x > size.width - kBubbleRadius) {
        x = size.width - kBubbleRadius;
        dx = -dx;
      }
      steps++;
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: GestureDetector(
        onPanStart: (d) {
          setState(() {
            isAiming = true;
            aimX = d.localPosition.dx;
            aimY = d.localPosition.dy;
          });
        },
        onPanUpdate: (d) {
          setState(() {
            aimX = d.localPosition.dx;
            aimY = d.localPosition.dy;
          });
        },
        onPanEnd: (_) {
          if (isAiming) {
            _shoot(aimX, aimY);
          }
          setState(() => isAiming = false);
        },
        onTapUp: (d) {
          _shoot(d.localPosition.dx, d.localPosition.dy);
        },
        child: Container(
          width: size.width,
          height: size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF07071A), Color(0xFF0D0D2B), Color(0xFF12123A)],
            ),
          ),
          child: Stack(
            children: [
              _buildStars(size),
              _buildGrid(),
              if (isAiming && aimY < size.height - 100)
                CustomPaint(
                  size: size,
                  painter: AimLinePainter(
                    _getAimLine(aimX, aimY, size),
                    currentColor,
                  ),
                ),
              if (shooterBubble != null && shooterBubble!.moving)
                _buildMovingBubble(),
              Positioned(top: 50, left: 0, right: 0, child: _buildTopBar()),
              _buildShooterArea(size),
              if (gameOver || gameWon) _buildOverlay(size),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStars(Size size) {
    return CustomPaint(size: size, painter: StarsPainter(seed: 42));
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const Spacer(),
          Column(
            children: [
              const Text(
                'SCORE',
                style: TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          Spacer(),
          Column(
            children: [
              const Text(
                'LEVEL',
                style: TextStyle(
                  color: Color.fromARGB(97, 232, 222, 222),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '$level',
                style: const TextStyle(
                  color: Color(0xFFFFD93D),
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _initGame,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Stack(
      children: grid.where((b) => b != null && b.alive).map((b) {
        return Positioned(
          left: b!.x - kBubbleRadius,
          top: b.y - kBubbleRadius,
          child: BubbleWidget(color: b.color, radius: kBubbleRadius),
        );
      }).toList(),
    );
  }

  Widget _buildMovingBubble() {
    final b = shooterBubble!;
    return Positioned(
      left: b.x - kBubbleRadius,
      top: b.y - kBubbleRadius,
      child: BubbleWidget(color: b.color, radius: kBubbleRadius),
    );
  }

  Widget _buildShooterArea(Size size) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              const Color(0xFF07071A).withOpacity(0.95),
              Colors.transparent,
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 40,
              bottom: 50,
              child: Column(
                children: [
                  const Text(
                    'NEXT',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  BubbleWidget(color: nextColor, radius: 18),
                ],
              ),
            ),
            Positioned(
              bottom: 90,
              child: Column(
                children: [
                  const Text(
                    'SHOOT',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _shooterPulse,
                    builder: (_, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: currentColor.withOpacity(
                                0.3 + 0.3 * _shooterPulse.value,
                              ),
                              blurRadius: 20 + 10 * _shooterPulse.value,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: BubbleWidget(
                          color: currentColor,
                          radius: kBubbleRadius + 4,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gameWon
                  ? [const Color(0xFF1A3A2A), const Color(0xFF0D2018)]
                  : [const Color(0xFF3A1A1A), const Color(0xFF200D0D)],
            ),
            border: Border.all(
              color: gameWon
                  ? const Color(0xFF7CFF6B)
                  : const Color(0xFFFF4E91),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(gameWon ? '🎉' : '💥', style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                gameWon ? 'YOU WIN!' : 'GAME OVER',
                style: TextStyle(
                  color: gameWon
                      ? const Color(0xFF7CFF6B)
                      : const Color(0xFFFF4E91),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Score: $score',
                style: const TextStyle(color: Colors.white70, fontSize: 20),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _overlayButton(
                    'PLAY AGAIN',
                    const Color(0xFF7C3AED),
                    _initGame,
                  ),
                  const SizedBox(width: 12),
                  _overlayButton(
                    'HOME',
                    const Color(0xFF374151),
                    () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overlayButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12)],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
