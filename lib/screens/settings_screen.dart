import 'package:flutter/material.dart';
import '../models/game_settings.dart';

class SettingsScreen extends StatefulWidget {
  final GameSettings settings;
  final ValueChanged<GameSettings> onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
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
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
                    const SizedBox(height: 12),
                    _Section(
                title: 'Digits',
                desc: 'Number of digits per value',
                child: Row(
                  children: [1, 2, 3, 4].map((d) {
                    final isSelected = _currentSettings.digits == d;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _updateSettings(_currentSettings.copyWith(digits: d)),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : const Color(0xFF1A1D2E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? Colors.blue : const Color(0xFF2E3150)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            d.toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Display Count',
                desc: 'How many numbers to show (min 2, max 20)',
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_currentSettings.count > 2) {
                              _updateSettings(_currentSettings.copyWith(count: _currentSettings.count - 1));
                            }
                          },
                          icon: const Icon(Icons.remove),
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFF1A1D2E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                        Column(
                          children: [
                            Text('${_currentSettings.count}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
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
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFF1A1D2E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ],
                    ),
                    Slider(
                      value: _currentSettings.count.toDouble(),
                      min: 2, max: 20,
                      activeColor: Colors.blue,
                      onChanged: (val) => _updateSettings(_currentSettings.copyWith(count: val.toInt())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Display Speed',
                desc: 'Duration each number is shown',
                child: Column(
                  children: GameSpeed.values.map((s) {
                    final isSelected = _currentSettings.speed == s;
                    final labels = {
                      GameSpeed.ultraFast: 'Ultra Fast', GameSpeed.fast: 'Fast',
                      GameSpeed.normal: 'Normal', GameSpeed.slow: 'Slow',
                      GameSpeed.ultraSlow: 'Ultra Slow'
                    };
                    final ms = {
                      GameSpeed.ultraFast: '0.5s', GameSpeed.fast: '1s',
                      GameSpeed.normal: '2s', GameSpeed.slow: '3s',
                      GameSpeed.ultraSlow: '4.5s'
                    };
                    return GestureDetector(
                      onTap: () => _updateSettings(_currentSettings.copyWith(speed: s)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.withOpacity(0.12) : const Color(0xFF1A1D2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.blue : const Color(0xFF2E3150)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? Colors.blue : const Color(0xFF2E3150),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(labels[s]!, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              children: [
                                Text(ms[s]!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(width: 8),
                                if (isSelected) const Icon(Icons.check, color: Colors.blue, size: 16),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right Column: Practice Modes & Voice
        Expanded(
          child: ListView(
            children: [
              _buildSectionTitle('PRACTICE MODES'),
              const SizedBox(height: 12),
              _Section(
                title: 'Mode',
                desc: 'How numbers are presented to you',
                child: Column(
                  children: GameMode.values.map((m) {
                    final isSelected = _currentSettings.mode == m;
                    final labels = {
                      GameMode.audio: 'Audio Only',
                      GameMode.display: 'Display Only',
                      GameMode.both: 'Audio + Display'
                    };

                    final icons = {
                      GameMode.audio: Icons.volume_up,
                      GameMode.display: Icons.desktop_windows,
                      GameMode.both: Icons.layers
                    };
                    return GestureDetector(
                      onTap: () => _updateSettings(_currentSettings.copyWith(mode: m)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.amber.withOpacity(0.1) : const Color(0xFF1A1D2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.amber : const Color(0xFF2E3150)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.amber.withOpacity(0.2) : const Color(0xFF252840),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icons[m], color: isSelected ? Colors.amber : Colors.grey, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(labels[m]!, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            if (isSelected) const Icon(Icons.check, color: Colors.amber, size: 16),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Voice Gender',
                desc: 'Choose male or female voice for audio',
                child: Column(
                  children: [TtsVoiceGender.male, TtsVoiceGender.female].map((v) {
                    final isSelected = _currentSettings.voiceGender == v;
                    final labels = {
                      TtsVoiceGender.female: 'Female',
                      TtsVoiceGender.male: 'Male'
                    };

                    final icons = {
                      TtsVoiceGender.female: Icons.face_3,
                      TtsVoiceGender.male: Icons.face
                    };
                    return GestureDetector(
                      onTap: () => _updateSettings(_currentSettings.copyWith(voiceGender: v)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.amber.withOpacity(0.1) : const Color(0xFF1A1D2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.amber : const Color(0xFF2E3150)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.amber.withOpacity(0.2) : const Color(0xFF252840),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icons[v], color: isSelected ? Colors.amber : Colors.grey, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(labels[v]!, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            if (isSelected) const Icon(Icons.check, color: Colors.amber, size: 16),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _handleSave,
                  icon: Icon(_saved ? Icons.check : null, color: Colors.white, size: _saved ? 20 : 0),
                  label: Text(_saved ? 'Saved!' : 'Save Settings', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _saved ? Colors.green : Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
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
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String desc;
  final Widget child;

  const _Section({required this.title, required this.desc, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E3150)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
