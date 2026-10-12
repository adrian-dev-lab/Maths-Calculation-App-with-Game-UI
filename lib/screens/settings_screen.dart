import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import '../widgets/shared_settings_ui.dart';

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
    // Keep edits local until the user explicitly saves.
    setState(() {
      _currentSettings = newSettings;
      _saved = false;
    });
  }

  void _handleSave() {
    if (_saved) return;
    // This is the only path that updates the parent and persists settings.
    widget.onSettingsChanged(_currentSettings);
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
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white, letterSpacing: 1.2)),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                        SettingsSection(
                title: 'APP SETTINGS',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SettingsInnerTitle(title: 'FONT SIZE', desc: 'Number display size'),
                    const SizedBox(height: 12),
                    Row(
                      children: DisplayFontSize.values.map((fs) {
                        final isSelected = _currentSettings.fontSize == fs;
                        final labels = {
                          DisplayFontSize.extraSmall: 'XS',
                          DisplayFontSize.small: 'S',
                          DisplayFontSize.normal: 'M',
                          DisplayFontSize.large: 'L',
                          DisplayFontSize.extraLarge: 'XL',
                        };
                        return Expanded(
                          child: OptionChip(
                            isSelected: isSelected,
                            onTap: () => _updateSettings(_currentSettings.copyWith(fontSize: fs)),
                            child: Text(
                              labels[fs]!,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SettingsSection(
                title: 'VOICE GENDER',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SettingsInnerTitle(title: 'VOICE GENDER', desc: 'Choose male or female voice for audio', color: Colors.pinkAccent),
                    const SizedBox(height: 12),
                    Row(
                      children: [TtsVoiceGender.male, TtsVoiceGender.female].map((vg) {
                        final isSelected = _currentSettings.voiceGender == vg;
                        final isMale = vg == TtsVoiceGender.male;
                        final color = isMale ? Colors.blueAccent : Colors.pinkAccent;
                        final icon = isMale ? Icons.male : Icons.female;
                        final label = isMale ? 'MALE' : 'FEMALE';

                        return Expanded(
                          child: OptionChip(
                            isSelected: isSelected,
                            accentColor: color,
                            onTap: () => _updateSettings(_currentSettings.copyWith(voiceGender: vg)),
                            height: 80, // Taller buttons for gender
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icon, color: isSelected ? Colors.white : color.withValues(alpha: 0.7), size: 28),
                                const SizedBox(height: 8),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : color.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 1.5,
                                  ),
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

                  const SizedBox(height: 80),
                  Center(
                    child: SizedBox(
                      width: 300,
                      child: NeonOutlineButton(
                        color: _saved ? Colors.greenAccent : Colors.cyanAccent,
                        onTap: _handleSave,
                        text: _saved ? 'SAVED!' : 'SAVE SETTINGS',
                        icon: _saved ? Icons.check_circle : Icons.check_circle_outline,
                      ),
                  ),
                ),
                const SizedBox(height: 48),
                const Center(
                  child: Text(
                    'App Version 1.0.0',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
            ],
          ),
        ),
        ),
      ),
      ),
      );
      },
    ),
  ),
);
  }
}
