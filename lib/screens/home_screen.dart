import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import 'settings_screen.dart' show ParticleClickEffect;

class HomeScreen extends StatelessWidget {
  final GameSettings settings;
  final VoidCallback onAdventureTap;
  final VoidCallback onCalculationTap;
  final VoidCallback onBeadsTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onSettingsTap;

  const HomeScreen({
    super.key,
    required this.settings,
    required this.onAdventureTap,
    required this.onCalculationTap,
    required this.onBeadsTap,
    required this.onHistoryTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2B0B3F), // Cosmic Deep Purple
              Color(0xFF0D021A), // Deep Space Dark
            ],
          ),
        ),
        child: Row(
          children: [
            // Left Side: Mascot Image
            Expanded(
              flex: 5,
              child: Center(
                child: ShaderMask(
                  blendMode: BlendMode.screen,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2B0B3F), 
                      Color(0xFF0D021A),
                    ],
                  ).createShader(bounds),
                  child: Image.asset(
                    'assets/images/mascot_home.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_not_supported, color: Colors.grey, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Image not found:\nassets/images/mascot_home.jpg\n\nError: $error',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // Right Side: Buttons
          Expanded(
            flex: 4,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Premium3DMenuButton(
                      title: 'ADVENTURE', 
                      icon: Icons.explore, 
                      colorDark: const Color(0xFF2874A6), // Soft Dark Blue
                      colorLight: const Color(0xFF5DADE2), // Soft Sky Blue
                      onTap: onAdventureTap,
                    ),
                    const SizedBox(height: 18),
                    Premium3DMenuButton(
                      title: 'CALCULATION', 
                      icon: Icons.calculate, 
                      colorDark: const Color(0xFFD4AC0D), // Soft Mustard Gold
                      colorLight: const Color(0xFFF4D03F), // Soft Sun Yellow
                      onTap: onCalculationTap,
                    ),
                    const SizedBox(height: 18),
                    Premium3DMenuButton(
                      title: 'BEADS', 
                      icon: Icons.view_module, 
                      colorDark: const Color(0xFF229954), // Soft Leaf Green
                      colorLight: const Color(0xFF58D68D), // Soft Mint Green
                      onTap: onBeadsTap,
                    ),
                    const SizedBox(height: 18),
                    Premium3DMenuButton(
                      title: 'HISTORY', 
                      icon: Icons.history, 
                      colorDark: const Color(0xFFC0392B), // Soft Brick Red
                      colorLight: const Color(0xFFEC7063), // Soft Watermelon Pink
                      onTap: onHistoryTap,
                    ),
                    const SizedBox(height: 18),
                    Premium3DMenuButton(
                      title: 'SETTINGS', 
                      icon: Icons.settings, 
                      colorDark: const Color(0xFF8E44AD), // Soft Grape Purple
                      colorLight: const Color(0xFFBB8FCE), // Soft Lilac
                      onTap: onSettingsTap,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
      ),
    );
  }
}

class Premium3DMenuButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color colorDark;
  final Color colorLight;
  final VoidCallback onTap;

  const Premium3DMenuButton({
    super.key,
    required this.title,
    required this.icon,
    required this.colorDark,
    required this.colorLight,
    required this.onTap,
  });

  @override
  State<Premium3DMenuButton> createState() => _Premium3DMenuButtonState();
}

class _Premium3DMenuButtonState extends State<Premium3DMenuButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Top layer gradient for a rich 3D curved look
    final topGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _isHovered ? Color.lerp(Colors.white, widget.colorLight, 0.6)! : widget.colorLight,
        _isHovered ? widget.colorLight : Color.lerp(widget.colorLight, widget.colorDark, 0.4)!,
      ],
    );
    // Bottom layer color: dark shadow
    final bottomColor = widget.colorDark;
    
    // Position of the top layer (distance from bottom)
    final double offset = _isPressed ? 2.0 : (_isHovered ? 6.0 : 8.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: ParticleClickEffect(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            height: 64,
            child: Stack(
              children: [
                // Bottom shadow layer
                Positioned(
                  bottom: 0, left: 0, right: 0, top: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: bottomColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black45, width: 2),
                    ),
                  ),
                ),
                // Top clickable layer
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                  bottom: offset,
                  left: 0, right: 0,
                  top: 12 - offset,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: topGradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black45, width: 2),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 2)), // Highlight
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(widget.icon, size: 24, color: Colors.white),
                            const SizedBox(width: 12),
                            Text(
                              widget.title.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 2.0,
                                shadows: [Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 0)],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
