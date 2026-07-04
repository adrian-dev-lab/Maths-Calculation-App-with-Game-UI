class _Premium3DButton extends StatelessWidget {
  final bool isSelected;
  final String label;
  final VoidCallback onTap;
  final Color accentColor;
  final IconData? icon;

  const _Premium3DButton({
    required this.isSelected,
    required this.label,
    required this.onTap,
    this.accentColor = Colors.blueAccent,
    this.icon,
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
    final textColor = isSelected ? Colors.white : Colors.white70;

    return ParticleClickEffect(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        height: 60,
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
                    color: Colors.black45,
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
                  border: Border.all(color: Colors.black45, width: 2),
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
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 22, color: textColor),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(0, 2),
                                blurRadius: 0,
                              ),
                            ],
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
    );
  }
}
