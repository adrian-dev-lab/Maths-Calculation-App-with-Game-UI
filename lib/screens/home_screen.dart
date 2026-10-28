import 'package:flutter/material.dart';
import '../models/game_settings.dart';

class HomeScreen extends StatefulWidget {
  final GameSettings settings;
  final VoidCallback onCalculationTap;
  final VoidCallback onBeadsTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onSettingsTap;

  const HomeScreen({
    super.key,
    required this.settings,
    required this.onCalculationTap,
    required this.onBeadsTap,
    required this.onHistoryTap,
    required this.onSettingsTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0214),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF381460),
              Color(0xFF150A21),
              Color(0xFF0A0214),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isPortrait = constraints.maxHeight > constraints.maxWidth;
            final bool isMobile = constraints.maxWidth < 850 || isPortrait;

            // -----------------------------------------------------------------
            // Mascot with Floating Animation & Glow
            // -----------------------------------------------------------------
            final mascotImage = Image.asset(
              'assets/images/mascot_home.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image_not_supported, color: Colors.grey, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Image not found:\nassets/images/mascot_home.png',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            );

            final mascotWidget = Stack(
              alignment: Alignment.center,
              children: [
                // Glowing Aura behind mascot
                Container(
                  width: isMobile ? 200 : 300,
                  height: isMobile ? 200 : 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                        blurRadius: 100,
                        spreadRadius: 20,
                      ),
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.1),
                        blurRadius: 60,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
                // Floating Mascot
                AnimatedBuilder(
                  animation: _floatController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -15 + 30 * _floatController.value),
                      child: child,
                    );
                  },
                  child: mascotImage,
                ),
              ],
            );

            // -----------------------------------------------------------------
            // Glowing Title
            // -----------------------------------------------------------------
            final titleWidget = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MATHS GENIUS ACADEMY',
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.6),
                        blurRadius: 20,
                      ),
                      Shadow(
                        color: Colors.purpleAccent.withValues(alpha: 0.6),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'MASTER YOUR MIND',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 16,
                    color: Colors.cyanAccent.withValues(alpha: 0.8),
                    letterSpacing: 6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );

            // -----------------------------------------------------------------
            // Glassmorphism Buttons
            // -----------------------------------------------------------------
            final buttonsWidget = ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GlassMenuButton(
                    title: 'CALCULATION',
                    icon: Icons.calculate,
                    accentColor: const Color(0xFFFACC15),
                    onTap: widget.onCalculationTap,
                  ),
                  const SizedBox(height: 8),
                  _GlassMenuButton(
                    title: 'BEADS',
                    icon: Icons.view_module,
                    accentColor: const Color(0xFF4ADE80),
                    onTap: widget.onBeadsTap,
                  ),
                  const SizedBox(height: 8),
                  _GlassMenuButton(
                    title: 'HISTORY',
                    icon: Icons.history,
                    accentColor: const Color(0xFFF87171),
                    onTap: widget.onHistoryTap,
                  ),
                  const SizedBox(height: 8),
                  _GlassMenuButton(
                    title: 'SETTINGS',
                    icon: Icons.settings,
                    accentColor: const Color(0xFFA78BFA),
                    onTap: widget.onSettingsTap,
                  ),
                ],
              ),
            );

            // -----------------------------------------------------------------
            // Layout (Mobile vs Desktop)
            // -----------------------------------------------------------------
            // Compact landscape: on narrow phones a vertical menu requires
            // scrolling, hiding the lower actions. Fit the mascot and all
            // four buttons side-by-side within the available height.
            if (!isPortrait &&
                constraints.maxHeight < 650 &&
                constraints.maxWidth >= 600) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: titleWidget,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 3,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: 320,
                                  height: 350,
                                  child: mascotWidget,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: 400,
                                  height: 380,
                                  child: buttonsWidget,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (isMobile) {
              return SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        titleWidget,
                        const SizedBox(height: 40),
                        SizedBox(
                          height: constraints.maxHeight * 0.35,
                          child: mascotWidget,
                        ),
                        const SizedBox(height: 40),
                        buttonsWidget,
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        titleWidget,
                        const SizedBox(height: 60),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 350,
                              height: 380,
                              child: mascotWidget,
                            ),
                            const SizedBox(width: 80),
                            SizedBox(
                              width: 400,
                              child: buttonsWidget,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          }
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// New Glassmorphism UI Button (Replacing the old Chunky 3D button)
// -----------------------------------------------------------------------------
class _GlassMenuButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _GlassMenuButton({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_GlassMenuButton> createState() => _GlassMenuButtonState();
}

class _GlassMenuButtonState extends State<_GlassMenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 72,
          decoration: BoxDecoration(
            color: _isHovered 
                ? widget.accentColor.withValues(alpha: 0.15) 
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered ? widget.accentColor : Colors.white.withValues(alpha: 0.1),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  widget.icon, 
                  size: 32, 
                  color: _isHovered ? Colors.white : widget.accentColor
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: _isHovered ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 24,
                  color: _isHovered ? widget.accentColor : Colors.white30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
