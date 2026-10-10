import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import '../widgets/shared_settings_ui.dart';

class CalculationSettingsScreen extends StatefulWidget {
  final GameSettings settings;
  final ValueChanged<GameSettings> onSettingsChanged;
  final VoidCallback onBack;

  const CalculationSettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onBack,
  });

  @override
  State<CalculationSettingsScreen> createState() => _CalculationSettingsScreenState();
}

class _CalculationSettingsScreenState extends State<CalculationSettingsScreen> {
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
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        widget.onBack();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF150A21),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: const Text('Calculation Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 650 || constraints.maxHeight > constraints.maxWidth;

              final gameConfigContent = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SettingsInnerTitle(title: 'DIGITS'),
                  const SizedBox(height: 12),
                  Row(
                    children: [1, 2, 3, 4, 5].map((d) {
                      final isSelected = _currentSettings.digits == d;
                      return Expanded(
                        child: OptionChip(
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
                  const SizedBox(height: 24),
                  if (isMobile) ...[
                    Divider(color: const Color(0xFF412A6C).withValues(alpha: 0.5), thickness: 2, height: 1),
                    const SizedBox(height: 24),
                  ],
                  const SettingsInnerTitle(title: 'DISPLAY COUNT'),
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
              );

              final modeColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SettingsInnerTitle(title: 'MODE', color: Colors.greenAccent),
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

                      return OptionChip(
                        isSelected: isSelected,
                        accentColor: Colors.lightBlue,
                        onTap: () => _updateSettings(_currentSettings.copyWith(mode: m)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icons[m], size: 20, color: textColor),
                              const SizedBox(width: 8),
                              Text(labels[m]!, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 14)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );

              final speedColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SettingsInnerTitle(title: 'DISPLAY SPEED', color: Colors.greenAccent),
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

                      return OptionChip(
                        isSelected: isSelected,
                        accentColor: Colors.orange,
                        onTap: () => _updateSettings(_currentSettings.copyWith(speed: s)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(labels[s]!, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: List.generate(5, (index) {
                                      final isFilled = index < stars[s]!;
                                      return Icon(
                                        isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: isFilled 
                                            ? (isSelected ? Colors.white : Colors.orangeAccent)
                                            : (isSelected ? Colors.white54 : Colors.white38),
                                        size: 14,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.black.withValues(alpha: 0.15) : const Color(0xFF1A0C2E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(ms[s]!, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );

              final saveButton = Center(
                child: SizedBox(
                  width: 300,
                  child: NeonOutlineButton(
                    color: _saved ? Colors.greenAccent : Colors.cyanAccent,
                    onTap: _handleSave,
                    text: _saved ? 'SAVED!' : 'SAVE SETTINGS',
                    icon: _saved ? Icons.check_circle : Icons.check_circle_outline,
                  ),
                ),
              );

              if (isMobile) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsSection(title: 'GAME CONFIGURATION', child: gameConfigContent),
                      const SizedBox(height: 24),
                      SettingsSection(
                        title: 'PRACTICE MODES & SPEED',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            modeColumn,
                            const SizedBox(height: 24),
                            const Divider(color: Color(0xFF412A6C)),
                            const SizedBox(height: 24),
                            speedColumn,
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      saveButton,
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              } else {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1300),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SettingsSection(title: 'GAME CONFIGURATION', child: gameConfigContent),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: SettingsSection(
                                title: 'PRACTICE MODES & SPEED',
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: modeColumn),
                                    const SizedBox(width: 16),
                                    Expanded(child: speedColumn),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      saveButton,
                    ],
                  ),
                ),
              ),
              ),
            );
          }
            },
          ),
        ),
      ),
      ),
    );
  }
}
