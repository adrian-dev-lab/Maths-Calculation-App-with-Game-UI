import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import 'home_screen.dart';
import 'play_screen.dart';
import 'settings_screen.dart';
import '../services/storage_service.dart';
import 'history_screen.dart';
import 'beads_screen.dart';
import 'adventure_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  late GameSettings _settings;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _settings = StorageService.loadSettings();
  }

  void _updateSettings(GameSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    StorageService.saveSettings(newSettings);
  }

  void _onPlayingStateChanged(bool isPlaying) {
    setState(() {
      _isPlaying = isPlaying;
    });
  }

  void _navigate(int index) {
    if (_isPlaying) return;
    setState(() {
      _currentIndex = index;
    });
  }

  void _goHome() {
    _navigate(0);
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(
          settings: _settings,
          onAdventureTap: () => _navigate(4),
          onCalculationTap: () => _navigate(1),
          onBeadsTap: () => _navigate(5),
          onHistoryTap: () => _navigate(3),
          onSettingsTap: () => _navigate(2),
        );
      case 1:
        return PlayScreen(
          settings: _settings,
          onPlayingStateChanged: _onPlayingStateChanged,
          onBack: _goHome,
        );
      case 2:
        return SettingsScreen(
          settings: _settings,
          onSettingsChanged: _updateSettings,
          onBack: _goHome,
        );
      case 3:
        return HistoryScreen(
          onBack: _goHome,
        );
      case 4:
        return AdventureScreen(
          onBack: _goHome,
        );
      case 5:
        return BeadsScreen(
          onBack: _goHome,
        );
      default:
        return HomeScreen(
          settings: _settings,
          onAdventureTap: () => _navigate(4),
          onCalculationTap: () => _navigate(1),
          onBeadsTap: () => _navigate(5),
          onHistoryTap: () => _navigate(3),
          onSettingsTap: () => _navigate(2),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: _buildCurrentScreen(),
    );
  }
}
