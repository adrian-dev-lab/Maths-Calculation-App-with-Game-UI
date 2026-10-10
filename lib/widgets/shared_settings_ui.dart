import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final String? title;
  final Widget child;

  const SettingsSection({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF251446),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF412A6C), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF412A6C).withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: const Border(bottom: BorderSide(color: Color(0xFF412A6C), width: 2)),
              ),
              child: Center(
                child: Text(
                  title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class OptionChip extends StatelessWidget {
  final bool isSelected;
  final Widget child;
  final VoidCallback onTap;
  final Color accentColor;
  final double? height;

  const OptionChip({
    super.key,
    required this.isSelected,
    required this.child,
    required this.onTap,
    this.accentColor = Colors.lightBlue,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 650 || MediaQuery.of(context).size.height > MediaQuery.of(context).size.width;
    final baseHeight = height ?? 56.0;
    final actualHeight = isMobile ? baseHeight * 0.85 : baseHeight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        height: actualHeight,
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class NeonOutlineButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final IconData icon;
  final Color color;

  const NeonOutlineButton({
    super.key,
    required this.onTap,
    required this.text,
    required this.icon,
    this.color = Colors.cyanAccent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsInnerTitle extends StatelessWidget {
  final String title;
  final String? desc;
  final Color color;

  const SettingsInnerTitle({
    super.key,
    required this.title,
    this.desc,
    this.color = Colors.cyanAccent,
  });

  @override
  Widget build(BuildContext context) {
    if (desc == null || desc!.isEmpty) {
      return Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2)),
        const SizedBox(height: 2),
        Text(desc!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
