import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import 'play_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import '../services/storage_service.dart';
import '../utils/responsive.dart';

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

  void _onTabTapped(int index) {
    if (_isPlaying) return; // Block navigation during play
    setState(() {
      _currentIndex = index;
    });
  }

  void _onPlayingStateChanged(bool isPlaying) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isPlaying = isPlaying);
    });
  }

  void _updateSettings(GameSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    StorageService.saveSettings(newSettings);
  }

  List<Widget> _screens() {
    return [
      PlayScreen(settings: _settings, onPlayingStateChanged: _onPlayingStateChanged),
      SettingsScreen(settings: _settings, onSettingsChanged: _updateSettings),
      HistoryScreen(key: UniqueKey()),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              backgroundColor: const Color(0xFF1A1D2E),
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabTapped,
              selectedIconTheme: const IconThemeData(color: Colors.amber),
              unselectedIconTheme: IconThemeData(color: _isPlaying ? Colors.grey.withOpacity(0.3) : Colors.grey),
              selectedLabelTextStyle: const TextStyle(color: Colors.amber),
              unselectedLabelTextStyle: TextStyle(color: _isPlaying ? Colors.grey.withOpacity(0.3) : Colors.grey),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.play_circle_fill), label: Text('Play')),
                NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
                NavigationRailDestination(icon: Icon(Icons.history), label: Text('History')),
                NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profile')),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1, color: Color(0xFF2E3150)),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
