import 'package:flutter/material.dart';

class HexagonPainter extends CustomPainter {
  final bool isActive;
  HexagonPainter(this.isActive);

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return; // Only draw beads that represent the actual value

    final double w = size.width;
    final double h = size.height;
    
    final path = Path();
    path.moveTo(w * 0.2, 0);
    path.lineTo(w * 0.8, 0);
    path.lineTo(w, h * 0.5);
    path.lineTo(w * 0.8, h);
    path.lineTo(w * 0.2, h);
    path.lineTo(0, h * 0.5);
    path.close();

    // High Contrast Black Fill
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // High Contrast White Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant HexagonPainter oldDelegate) {
    return oldDelegate.isActive != isActive;
  }
}

class AbacusBead extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  final bool isUpper;

  const AbacusBead({
    super.key,
    required this.isActive,
    required this.onTap,
    required this.isUpper,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
        width: 56,
        height: 24,
        child: CustomPaint(
          painter: HexagonPainter(isActive),
        ),
      ),
    );
  }
}

