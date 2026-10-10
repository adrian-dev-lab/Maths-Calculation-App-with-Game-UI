import 'package:flutter/material.dart';

class LevelNode {
  final int id;
  final double xOffset; // 0.0 to 1.0 (relative to width)
  final double yOffset; // 0.0 to 1.0 (relative to height)
  final bool isLocked;
  final int stars;

  LevelNode({
    required this.id,
    required this.xOffset,
    required this.yOffset,
    this.isLocked = true,
    this.stars = 0,
  });
}

class AdventureScreen extends StatefulWidget {
  final VoidCallback onBack;

  const AdventureScreen({super.key, required this.onBack});

  @override
  State<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends State<AdventureScreen> {
  final List<LevelNode> levels = [
    LevelNode(id: 1, xOffset: 0.2, yOffset: 0.35, isLocked: false, stars: 3),
    LevelNode(id: 2, xOffset: 0.4, yOffset: 0.65, isLocked: false, stars: 3),
    LevelNode(id: 3, xOffset: 0.45, yOffset: 0.3, isLocked: false, stars: 3),
    LevelNode(id: 4, xOffset: 0.65, yOffset: 0.45, isLocked: false, stars: 1),
    LevelNode(id: 5, xOffset: 0.75, yOffset: 0.7, isLocked: false, stars: 1),
    LevelNode(id: 6, xOffset: 0.85, yOffset: 0.35, isLocked: true, stars: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/adventure_map_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Path Painter
          Positioned.fill(
            child: CustomPaint(painter: PathPainter(levels: levels)),
          ),
          // Level Nodes
          ...levels.map((level) {
            return Positioned(
              left: MediaQuery.of(context).size.width * level.xOffset - 40,
              top: MediaQuery.of(context).size.height * level.yOffset - 40,
              child: LevelButton(level: level),
            );
          }),
          // Custom App Bar
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                InkWell(
                  onTap: widget.onBack,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.brown.shade900,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                // Map Title
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade600,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.brown.shade900, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(0, 4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Text(
                    'MAP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                // Score
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2A4A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blueAccent, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 24),
                      const SizedBox(width: 5),
                      const Text(
                        '1250',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LevelButton extends StatelessWidget {
  final LevelNode level;

  const LevelButton({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: level.isLocked
                  ? [Colors.grey.shade400, Colors.grey.shade700]
                  : [Colors.lightBlueAccent, Colors.blue.shade800],
            ),
            border: Border.all(
              color: level.isLocked
                  ? Colors.grey.shade800
                  : Colors.blue.shade900,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                offset: const Offset(0, 4),
                blurRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: level.isLocked
                ? const Icon(Icons.lock, color: Colors.white70, size: 30)
                : Text(
                    '${level.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 5),
        if (!level.isLocked)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return Icon(
                Icons.star,
                color: index < level.stars
                    ? Colors.amber
                    : Colors.grey.shade800,
                size: 18,
              );
            }),
          ),
      ],
    );
  }
}

class PathPainter extends CustomPainter {
  final List<LevelNode> levels;

  PathPainter({required this.levels});

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.length < 2) return;

    final paint = Paint()
      ..color = Colors.brown.shade300
      ..strokeWidth = 15
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final borderPaint = Paint()
      ..color = Colors.brown.shade700
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Start from first level
    path.moveTo(
      size.width * levels[0].xOffset,
      size.height * levels[0].yOffset,
    );

    // Draw bezier curves to subsequent levels
    for (int i = 1; i < levels.length; i++) {
      final p0 = Offset(
        size.width * levels[i - 1].xOffset,
        size.height * levels[i - 1].yOffset,
      );
      final p1 = Offset(
        size.width * levels[i].xOffset,
        size.height * levels[i].yOffset,
      );

      // Control point logic for a winding path
      final controlPointX = (p0.dx + p1.dx) / 2 + (i % 2 == 0 ? 50 : -50);
      final controlPointY = (p0.dy + p1.dy) / 2 + (i % 2 == 0 ? -50 : 50);

      path.quadraticBezierTo(controlPointX, controlPointY, p1.dx, p1.dy);
    }

    // Draw border first, then inner path
    canvas.drawPath(path, borderPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
