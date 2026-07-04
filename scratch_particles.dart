
class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  Color color;
  double size;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    required this.size,
  });
}

class ParticleClickEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ParticleClickEffect({super.key, required this.child, this.onTap});

  @override
  State<ParticleClickEffect> createState() => _ParticleClickEffectState();
}

class _ParticleClickEffectState extends State<ParticleClickEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();
  final List<Color> _colors = [
    Colors.yellowAccent,
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.orangeAccent,
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(() {
            setState(() {
              for (var p in _particles) {
                p.x += p.vx;
                p.y += p.vy;
                p.life -= 0.03;
              }
              _particles.removeWhere((p) => p.life <= 0);
            });
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerParticles(PointerDownEvent details) {
    widget.onTap?.call();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 20; i++) {
      double angle = _random.nextDouble() * 2 * pi;
      double speed = _random.nextDouble() * 5 + 2;
      _particles.add(
        _Particle(
          x: center.dx,
          y: center.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          life: 1.0,
          color: _colors[_random.nextInt(_colors.length)],
          size: _random.nextDouble() * 6 + 4,
        ),
      );
    }

    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _triggerParticles,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_particles.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _ParticlePainter(_particles)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: max(0.0, p.life))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size * p.life, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
