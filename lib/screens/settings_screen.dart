import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_settings.dart';

class SettingsScreen extends StatefulWidget {
  final GameSettings settings;
  final ValueChanged<GameSettings> onSettingsChanged;
  final VoidCallback onBack;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onBack,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GameSettings _currentSettings;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _currentSettings = widget.settings;
  }

  void _updateSettings(GameSettings newSettings) {
    setState(() {
      _currentSettings = newSettings;
    });
    widget.onSettingsChanged(newSettings);
  }

  void _handleSave() {
    setState(() {
      _saved = true;
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _saved = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF150A21), // Deep dark purple background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Game Configuration
              Expanded(
                child: ListView(
                  children: [
                    _buildSectionTitle('GAME CONFIGURATION'),
                    const SizedBox(height: 8),
                    _Section(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInnerTitle('DIGITS', 'Number of digits per value'),
                          const SizedBox(height: 12),
                          Row(
                            children: [1, 2, 3, 4].map((d) {
                              final isSelected = _currentSettings.digits == d;
                              return Expanded(
                                child: _Premium3DButton(
                                  isSelected: isSelected,
                                  accentColor: Colors.lightBlue,
                                  onTap: () => _updateSettings(_currentSettings.copyWith(digits: d)),
                                  child: Center(
                                    child: Text(
                                      d.toString(),
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white70,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInnerTitle('DISPLAY COUNT', 'How many numbers to show (min 2, max 20)'),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (_currentSettings.count > 2) {
                                    _updateSettings(_currentSettings.copyWith(count: _currentSettings.count - 1));
                                  }
                                },
                                icon: const Icon(Icons.remove, color: Colors.white),
                                style: IconButton.styleFrom(backgroundColor: const Color(0xFF3B235A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              ),
                              Column(
                                children: [
                                  Text('${_currentSettings.count}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                                  if (_currentSettings.count == 20)
                                    const Text('Maximum', style: TextStyle(color: Colors.amber, fontSize: 10)),
                                ],
                              ),
                              IconButton(
                                onPressed: () {
                                  if (_currentSettings.count < 20) {
                                    _updateSettings(_currentSettings.copyWith(count: _currentSettings.count + 1));
                                  }
                                },
                                icon: const Icon(Icons.add, color: Colors.white),
                                style: IconButton.styleFrom(backgroundColor: const Color(0xFF3B235A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              ),
                            ],
                          ),
                          Slider(
                            value: _currentSettings.count.toDouble(),
                            min: 2, max: 20,
                            activeColor: Colors.lightBlue,
                            inactiveColor: const Color(0xFF3B235A),
                            onChanged: (val) => _updateSettings(_currentSettings.copyWith(count: val.toInt())),
                          ),
                          
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInnerTitle('DISPLAY SPEED', 'Duration each number is shown'),
                          const SizedBox(height: 12),
                          Column(
                            children: GameSpeed.values.map((s) {
                              final isSelected = _currentSettings.speed == s;
                              final labels = {
                                GameSpeed.ultraFast: 'Very Fast', GameSpeed.fast: 'Fast',
                                GameSpeed.normal: 'Normal', GameSpeed.slow: 'Slow',
                                GameSpeed.ultraSlow: 'Very Slow'
                              };
                              final ms = {
                                GameSpeed.ultraFast: '0.5s', GameSpeed.fast: '1.0s',
                                GameSpeed.normal: '2.0s', GameSpeed.slow: '3.0s',
                                GameSpeed.ultraSlow: '4.5s'
                              };
                              final stars = {
                                GameSpeed.ultraFast: 5, GameSpeed.fast: 4,
                                GameSpeed.normal: 3, GameSpeed.slow: 2,
                                GameSpeed.ultraSlow: 1
                              };
                              final textColor = isSelected ? Colors.white : Colors.white70;

                              return _Premium3DButton(
                                isSelected: isSelected,
                                accentColor: Colors.orange,
                                onTap: () => _updateSettings(_currentSettings.copyWith(speed: s)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(labels[s]!, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 14)),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: List.generate(5, (index) {
                                              final isFilled = index < stars[s]!;
                                              return Icon(
                                                isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                                                color: isFilled 
                                                    ? (isSelected ? Colors.white : Colors.orangeAccent)
                                                    : (isSelected ? Colors.white54 : Colors.white38),
                                                size: 18,
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.black.withOpacity(0.15) : const Color(0xFF1A0C2E),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(ms[s]!, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right Column: Practice Modes & Voice
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          _buildSectionTitle('PRACTICE MODES'),
                          const SizedBox(height: 8),
                          _Section(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInnerTitle('MODE', 'How numbers are presented to you'),
                                const SizedBox(height: 12),
                                Column(
                                  children: GameMode.values.map((m) {
                                    final isSelected = _currentSettings.mode == m;
                                    final labels = {
                                      GameMode.audio: 'AUDIO ONLY',
                                      GameMode.display: 'DISPLAY ONLY',
                                      GameMode.both: 'AUDIO + DISPLAY'
                                    };
                                    final icons = {
                                      GameMode.audio: Icons.volume_up,
                                      GameMode.display: Icons.desktop_windows,
                                      GameMode.both: Icons.layers
                                    };
                                    final textColor = isSelected ? Colors.white : Colors.white70;

                                    return _Premium3DButton(
                                      isSelected: isSelected,
                                      accentColor: Colors.lightBlue,
                                      onTap: () => _updateSettings(_currentSettings.copyWith(mode: m)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(icons[m], size: 20, color: textColor),
                                          const SizedBox(width: 8),
                                          Text(labels[m]!, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 14)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionTitle('VOICE GENDER'),
                          const SizedBox(height: 8),
                          _Section(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInnerTitle('VOICE GENDER', 'Choose male or female voice for audio'),
                                const SizedBox(height: 12),
                                Row(
                                  children: [TtsVoiceGender.male, TtsVoiceGender.female].map((v) {
                                    final isSelected = _currentSettings.voiceGender == v;
                                    final labels = {
                                      TtsVoiceGender.female: 'FEMALE',
                                      TtsVoiceGender.male: 'MALE'
                                    };
                                    final icons = {
                                      TtsVoiceGender.female: Icons.face_3,
                                      TtsVoiceGender.male: Icons.face
                                    };
                                    final textColor = isSelected ? Colors.white : Colors.white70;

                                    return Expanded(
                                      child: _Premium3DButton(
                                        isSelected: isSelected,
                                        accentColor: v == TtsVoiceGender.male ? Colors.lightBlue : Colors.pinkAccent,
                                        height: 80,
                                        onTap: () => _updateSettings(_currentSettings.copyWith(voiceGender: v)),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(icons[v], size: 28, color: textColor),
                                            const SizedBox(height: 4),
                                            Text(labels[v]!, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Premium3DButton(
                      isSelected: true,
                      accentColor: _saved ? Colors.green : Colors.lightBlue,
                      onTap: _handleSave,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_saved ? Icons.check : Icons.save, color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            _saved ? 'SAVED!' : 'SAVE SETTINGS',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
  
  Widget _buildInnerTitle(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
        const SizedBox(height: 2),
        Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;

  const _Section({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF251446),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF412A6C), width: 2),
      ),
      child: child,
    );
  }
}

class _Premium3DButton extends StatelessWidget {
  final bool isSelected;
  final Widget child;
  final VoidCallback onTap;
  final Color accentColor;
  final double height;

  const _Premium3DButton({
    required this.isSelected,
    required this.child,
    required this.onTap,
    this.accentColor = Colors.lightBlue,
    this.height = 72,
  });

  Color _darken(Color color, [double amount = .2]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final topColor = isSelected ? accentColor : const Color(0xFF3B235A);
    final bottomColor = isSelected
        ? _darken(accentColor)
        : const Color(0xFF1A0C2E);

    return ParticleClickEffect(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        height: height,
        child: Stack(
          children: [
            // Bottom shadow layer
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              top: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: bottomColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1A0C2E),
                    width: 2,
                  ), // Outer stroke
                ),
              ),
            ),
            // Top clickable layer
            AnimatedPositioned(
              duration: const Duration(milliseconds: 80),
              bottom: isSelected ? 4 : 8,
              left: 0,
              right: 0,
              top: isSelected ? 4 : 0,
              child: Container(
                decoration: BoxDecoration(
                  color: topColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1A0C2E), width: 2),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ), // Highlight
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
