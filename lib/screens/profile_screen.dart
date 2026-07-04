import 'dart:async';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  Timer? _timer;
  ProfileStats? _stats;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: StorageService.loadUsername());
    _ageController = TextEditingController(text: StorageService.loadAge());
    
    _loadStats();
    _timer = Timer.periodic(const Duration(seconds: 3), (t) {
      if (mounted) _loadStats();
    });
  }

  Future<void> _loadStats() async {
    final s = await DatabaseService.getProfileStats();
    if (mounted) {
      setState(() {
        _stats = s;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        StorageService.saveUsername(_nameController.text);
        StorageService.saveAge(_ageController.text);
      }
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final enrolledDate = StorageService.loadInstalledDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.lock_open : Icons.lock, color: Colors.grey),
            onPressed: _toggleEdit,
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: User Profile Info
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D2E),
                    border: Border.all(color: const Color(0xFF2E3150)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF252840),
                        ),
                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      if (_isEditing) ...[
                        TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Username',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: UnderlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _ageController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Age',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ] else ...[
                        Text(_nameController.text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('${_ageController.text} years old', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatItem(label: 'Enrolled', value: enrolledDate),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Right Column: Player Stats
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PLAYER STATS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.8,
                children: [
                  _DashboardCard(
                    icon: Icons.access_time_filled, iconColor: Colors.amber,
                    title: 'Total Play Time',
                    value: _formatTime(StorageService.loadTotalPlayTime()),
                  ),
                  _DashboardCard(
                    icon: Icons.games, iconColor: Colors.purple,
                    title: 'Games Played',
                    value: '${_stats?.gamesPlayed ?? 0}',
                  ),
                  _DashboardCard(
                    icon: Icons.local_fire_department, iconColor: Colors.orange,
                    title: 'Current Streak',
                    value: '${_stats?.currentStreak ?? 0} Days',
                  ),
                  _DashboardCard(
                    icon: Icons.favorite, iconColor: Colors.pink,
                    title: 'Favorite Mode',
                    value: _stats != null ? _stats!.favoriteMode.name.toUpperCase() : '-',
                  ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds < 60) return '< 1m';
    final m = totalSeconds ~/ 60;
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final m2 = m % 60;
    return '${h}h ${m2}m';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _DashboardCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        border: Border.all(color: const Color(0xFF2E3150)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
