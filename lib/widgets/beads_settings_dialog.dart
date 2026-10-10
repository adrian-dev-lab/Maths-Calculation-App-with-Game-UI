import 'package:flutter/material.dart';
import '../widgets/shared_settings_ui.dart';

class BeadsSettingsScreen extends StatefulWidget {
  final int initialColumnCount;
  final String initialSpeed;
  final int initialGroup;
  final String initialOperation;
  final Function(int columnCount, String speed, int group, String operation) onSave;

  const BeadsSettingsScreen({
    super.key,
    required this.initialColumnCount,
    required this.initialSpeed,
    required this.initialGroup,
    required this.initialOperation,
    required this.onSave,
  });

  @override
  State<BeadsSettingsScreen> createState() => _BeadsSettingsScreenState();
}

class _BeadsSettingsScreenState extends State<BeadsSettingsScreen> {
  late int columnCount;
  late String speed;
  late int group;
  late String operation;

  @override
  void initState() {
    super.initState();
    columnCount = widget.initialColumnCount;
    speed = widget.initialSpeed;
    group = widget.initialGroup;
    operation = widget.initialOperation;
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'BEADS SETTING',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Customize your beads practice',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const Positioned(
                        right: 8,
                        child: Icon(Icons.settings_suggest, color: Color(0xFF8660EB), size: 40),
                      ),
                    ],
                  ),
                ),
              ),

              // Body
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SettingsSection(
                            title: 'BEADS CONFIGURATION',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SettingsInnerTitle(title: 'NUMBER OF DISPLAY', desc: 'How many times to show each pattern.', color: Colors.lightBlue),
                                const SizedBox(height: 12),
                                Row(
                                  children: [1, 2, 3, 4, 5].map((val) {
                                    final isSelected = columnCount == val;
                                    return Expanded(
                                      child: OptionChip(
                                        isSelected: isSelected,
                                        accentColor: Colors.lightBlue,
                                        onTap: () => setState(() => columnCount = val),
                                        child: Text(
                                          val.toString(),
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
                                const SizedBox(height: 24),
                                const SettingsInnerTitle(title: 'GROUP', desc: 'Number of beads per column.', color: Colors.pinkAccent),
                                const SizedBox(height: 12),
                                Row(
                                  children: [1, 2, 3, 4, 5].map((val) {
                                    final isSelected = group == val;
                                    return Expanded(
                                      child: OptionChip(
                                        isSelected: isSelected,
                                        accentColor: Colors.pinkAccent,
                                        onTap: () => setState(() => group = val),
                                        child: Text(
                                          '$val Bead${val > 1 ? 's' : ''}',
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.white70,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
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
                            title: 'SPEED & OPERATION',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SettingsInnerTitle(title: 'SPEED', desc: 'How fast to show the beads.', color: Colors.greenAccent),
                                const SizedBox(height: 12),
                                Row(
                                  children: ['Slow', 'Normal', 'Fast'].map((val) {
                                    final isSelected = speed == val;
                                    return Expanded(
                                      child: OptionChip(
                                        isSelected: isSelected,
                                        accentColor: Colors.greenAccent,
                                        onTap: () => setState(() => speed = val),
                                        child: Text(
                                          val.toUpperCase(),
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.white70,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 24),
                                const SettingsInnerTitle(title: 'OPERATION', desc: 'Type of calculation.', color: Colors.orangeAccent),
                                const SizedBox(height: 12),
                                Row(
                                  children: ['Addition', 'Subtraction', 'Mixed'].map((val) {
                                    final isSelected = operation == val;
                                    return Expanded(
                                      child: OptionChip(
                                        isSelected: isSelected,
                                        accentColor: Colors.orangeAccent,
                                        onTap: () => setState(() => operation = val),
                                        child: Text(
                                          val.toUpperCase(),
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.white70,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                          Center(
                            child: SizedBox(
                              width: 300,
                              child: NeonOutlineButton(
                                onTap: () {
                                  widget.onSave(columnCount, speed, group, operation);
                                  Navigator.pop(context);
                                },
                                text: 'SAVE SETTINGS',
                                icon: Icons.check_circle,
                                color: Colors.cyanAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              },
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
