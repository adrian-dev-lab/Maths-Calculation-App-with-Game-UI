with open('lib/screens/settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "import 'package:flutter/material.dart';",
    "import 'dart:math';\nimport 'package:flutter/material.dart';"
)

content = content.replace(
"""class SettingsScreen extends StatefulWidget {
  final GameSettings settings;
  final ValueChanged<GameSettings> onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });""",
"""class SettingsScreen extends StatefulWidget {
  final GameSettings settings;
  final ValueChanged<GameSettings> onSettingsChanged;
  final VoidCallback onBack;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onBack,
  });"""
)

content = content.replace(
"""      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),""",
"""      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),"""
)

# Digits
content = content.replace(
"""                                return Expanded(
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
                                );""",
"""                                return Expanded(
                                  child: _Premium3DButton(
                                    isSelected: isSelected,
                                    label: d.toString(),
                                    accentColor: Colors.blueAccent,
                                    onTap: () => _updateSettings(_currentSettings.copyWith(digits: d)),
                                  ),
                                );"""
)

# Speed
content = content.replace(
"""                    return GestureDetector(
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
                    );""",
"""                    return _Premium3DButton(
                      isSelected: isSelected,
                      label: '${labels[s]!}  (${ms[s]!})',
                      accentColor: Colors.blueAccent,
                      onTap: () => _updateSettings(_currentSettings.copyWith(speed: s)),
                    );"""
)

# Modes
content = content.replace(
"""                    return GestureDetector(
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
                    );""",
"""                    return _Premium3DButton(
                      isSelected: isSelected,
                      label: labels[m]!,
                      icon: icons[m]!,
                      accentColor: Colors.amber,
                      onTap: () => _updateSettings(_currentSettings.copyWith(mode: m)),
                    );"""
)

# Voice
content = content.replace(
"""                    return GestureDetector(
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
                    );""",
"""                    return _Premium3DButton(
                      isSelected: isSelected,
                      label: labels[v]!,
                      icon: icons[v]!,
                      accentColor: Colors.amber,
                      onTap: () => _updateSettings(_currentSettings.copyWith(voiceGender: v)),
                    );"""
)

# Section Box
content = content.replace(
"""    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E3150)),
      ),""",
"""    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252840),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black26, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF151725),
            offset: Offset(0, 6),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.black38,
            offset: Offset(0, 8),
            blurRadius: 10,
          )
        ],
      ),"""
)

with open('scratch_premium_button.dart', 'r', encoding='utf-8') as f:
    btn = f.read()

with open('scratch_particles.dart', 'r', encoding='utf-8') as f:
    ptc = f.read()

content = content + "\n\n" + btn + "\n\n" + ptc

with open('lib/screens/settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
