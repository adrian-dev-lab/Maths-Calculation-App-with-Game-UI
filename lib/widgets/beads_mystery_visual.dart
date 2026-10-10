import 'package:flutter/material.dart';

class BeadsMysteryVisual extends StatelessWidget {
  const BeadsMysteryVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cx = w / 2;
        final cy = h / 2;

        // Orb diameter
        final orbSize = w * 0.48;

        // Helper to place items relative to the exact center point
        Widget centerPositioned({required double x, required double y, required Widget child}) {
          return Positioned(
            left: cx + x,
            top: cy + y,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: child,
            ),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ----------------------------------------------------
            // Decorations (placed behind or around orb)
            // ----------------------------------------------------
            
            // Top-Left Yellow Star
            centerPositioned(
              x: -w * 0.22,
              y: -w * 0.18,
              child: _FourPointSparkle(size: w * 0.06, color: const Color(0xFFFFD447)),
            ),
            
            // Left Pink Dash
            centerPositioned(
              x: -w * 0.35,
              y: -w * 0.05,
              child: Transform.rotate(
                angle: -1.0, // Top tilts left
                child: _AccentDash(width: w * 0.025, height: w * 0.09, colors: const [Color(0xFFF36CFF), Color(0xFFC743FF)]),
              ),
            ),
            
            // Bottom-Left Yellow Star
            centerPositioned(
              x: -w * 0.26,
              y: w * 0.15,
              child: _FourPointSparkle(size: w * 0.045, color: const Color(0xFFFFD447)),
            ),
            
            // Bottom-Left Purple Dash
            centerPositioned(
              x: -w * 0.15,
              y: w * 0.25,
              child: Transform.rotate(
                angle: 0.6, // Top tilts right
                child: _AccentDash(width: w * 0.018, height: w * 0.05, colors: const [Color(0xFF8E4BFF), Color(0xFF6B2DD1)]),
              ),
            ),

            // Top-Right Purple Star
            centerPositioned(
              x: w * 0.20,
              y: -w * 0.18,
              child: _FourPointSparkle(size: w * 0.045, color: const Color(0xFF8E4BFF)),
            ),

            // Right Pink Dash
            centerPositioned(
              x: w * 0.32,
              y: -w * 0.02,
              child: Transform.rotate(
                angle: 1.0, // Top tilts right
                child: _AccentDash(width: w * 0.025, height: w * 0.09, colors: const [Color(0xFFF36CFF), Color(0xFFC743FF)]),
              ),
            ),

            // Bottom-Right Yellow Star
            centerPositioned(
              x: w * 0.25,
              y: w * 0.12,
              child: _FourPointSparkle(size: w * 0.05, color: const Color(0xFFFFD447)),
            ),

            // Bottom-Right Purple Dash
            centerPositioned(
              x: w * 0.15,
              y: w * 0.25,
              child: Transform.rotate(
                angle: -0.6, // Top tilts left
                child: _AccentDash(width: w * 0.018, height: w * 0.05, colors: const [Color(0xFF8E4BFF), Color(0xFF6B2DD1)]),
              ),
            ),

            // ----------------------------------------------------
            // Center purple orb
            // ----------------------------------------------------
            centerPositioned(
              x: 0,
              y: 0,
              child: _MysteryOrb(size: orbSize),
            ),
          ],
        );
      },
    );
  }
}

class _MysteryOrb extends StatelessWidget {
  final double size;

  const _MysteryOrb({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Match the smooth dark purple of the target UI orb
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.3),
          radius: 1.0,
          colors: [
            Color(0xFF7A2BE5), // soft highlight top-left
            Color(0xFF4C15A6), // mid
            Color(0xFF280B5C), // dark edges
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          // subtle glow
          BoxShadow(
            color: const Color(0xFF5A1EB2).withValues(alpha: 0.3),
            blurRadius: size * 0.15,
            spreadRadius: size * 0.02,
          ),
          // soft drop shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: size * 0.1,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Center(
        // Allow the Question Mark to size itself fully without tight clipping
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: _QuestionMark3D(size: size * 0.9),
        ),
      ),
    );
  }
}

class _QuestionMark3D extends StatelessWidget {
  final double size;

  const _QuestionMark3D({required this.size});

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: size * 0.85, 
      height: 1.1, 
      fontWeight: FontWeight.w900,
    );

    // Using a moderate stroke makes the font chubby (hiding Segoe UI sharp edges)
    // without being so thick that it merges the dot into a blob.
    Widget buildThickText(Color color, {double strokeMultiplier = 1.0}) {
      return Padding(
        padding: EdgeInsets.all(size * 0.1), // Expands bounds for ShaderMask
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Text(
              '?',
              style: textStyle.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = size * 0.035 * strokeMultiplier // Carefully tuned width
                  ..strokeJoin = StrokeJoin.round
                  ..color = color,
              ),
            ),
            Text(
              '?',
              style: textStyle.copyWith(color: color),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // 1. Drop Shadow
        Transform.translate(
          offset: Offset(0, size * 0.08),
          child: buildThickText(Colors.black.withValues(alpha: 0.3), strokeMultiplier: 1.2),
        ),
        
        // 2. Dark Base (Extrusion / 3D depth)
        Transform.translate(
          offset: Offset(0, size * 0.03),
          child: buildThickText(const Color(0xFF5B24A3)), 
        ),

        // 3. Main 3D Face
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF3E5FF), // bright highlight top
                Color(0xFFCA94FF), // main light purple
                Color(0xFF8F48ED), // dark bottom
              ],
              stops: [0.0, 0.4, 1.0],
            ).createShader(bounds);
          },
          child: buildThickText(Colors.white),
        ),
      ],
    );
  }
}

class _AccentDash extends StatelessWidget {
  final double width;
  final double height;
  final List<Color> colors;

  const _AccentDash({
    required this.width,
    required this.height,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.4),
            blurRadius: width * 0.6,
          ),
        ],
      ),
    );
  }
}

class _FourPointSparkle extends StatelessWidget {
  final double size;
  final Color color;

  const _FourPointSparkle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _FourPointSparklePainter(color: color),
    );
  }
}

class _FourPointSparklePainter extends CustomPainter {
  final Color color;

  _FourPointSparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final path = Path();
    
    // Smooth four-point diamond/star
    path.moveTo(cx, 0);
    path.quadraticBezierTo(
      cx + size.width * 0.1, cy - size.height * 0.1, 
      size.width, cy
    );
    path.quadraticBezierTo(
      cx + size.width * 0.1, cy + size.height * 0.1, 
      cx, size.height
    );
    path.quadraticBezierTo(
      cx - size.width * 0.1, cy + size.height * 0.1, 
      0, cy
    );
    path.quadraticBezierTo(
      cx - size.width * 0.1, cy - size.height * 0.1, 
      cx, 0
    );
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Soft glow
    canvas.drawShadow(path, color.withValues(alpha: 0.6), size.width * 0.15, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FourPointSparklePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
