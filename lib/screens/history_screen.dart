import 'dart:io';
import 'package:flutter/material.dart';
import '../models/history_record.dart';
import '../models/game_settings.dart';

import '../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback onBack;

  const HistoryScreen({super.key, required this.onBack});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _exportMsg = false;

  void _handleExport() async {
    debugPrint('Export button clicked!');
    try {
      final records = await DatabaseService.getAllRecords();
      debugPrint('Fetched ${records.length} records.');
      if (records.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No records to export')));
        return;
      }
      
      final String path = Directory.current.path;
      final File file = File('$path\\flash_calc_history.csv');
      debugPrint('Saving to ${file.path}');
      
      final buffer = StringBuffer();
      buffer.writeln('ID,Username,Date,Mode,Speed,Digits,Count,Answer,Sequence');
      
      for (var r in records) {
        final mode = r.mode == GameMode.audio ? 'Audio' : r.mode == GameMode.display ? 'Display' : 'Mixed';
        final seq = r.sequence.join('|');
        buffer.writeln('${r.id},${r.username},${r.datetime},$mode,${r.speed},${r.digits},${r.count},${r.answer},"$seq"');
      }
      
      await file.writeAsString(buffer.toString());
      debugPrint('File saved successfully!');
      
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E213A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF2E3150))),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('Export Successful', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text('Your history has been exported to:\n\n${file.path}', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Awesome', style: TextStyle(color: Colors.blueAccent)),
            )
          ],
        )
      );
      
      setState(() {
        _exportMsg = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _exportMsg = false);
      });
    } catch (e) {
      debugPrint('Export error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    }
  }

  Map<String, List<HistoryRecord>> _groupRecords(List<HistoryRecord> records) {
    final Map<String, List<HistoryRecord>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWeek = today.subtract(const Duration(days: 7));

    for (var rec in records) {
      DateTime recDate;
      try {
        recDate = DateTime.parse(rec.datetime);
      } catch (e) {
        recDate = DateTime.now();
      }
      final dateOnly = DateTime(recDate.year, recDate.month, recDate.day);
      
      String groupName;
      if (dateOnly == today) {
        groupName = 'Today';
      } else if (dateOnly == yesterday) {
        groupName = 'Yesterday';
      } else if (dateOnly.isAfter(lastWeek)) {
        groupName = 'Last 7 Days';
      } else {
        groupName = 'Older';
      }

      grouped.putIfAbsent(groupName, () => []).add(rec);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B0B3F), Color(0xFF0D021A)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            FutureBuilder<int>(
              future: DatabaseService.getRecordsCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Text('$count sessions recorded', style: const TextStyle(color: Colors.grey, fontSize: 12));
              }
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FutureBuilder<int>(
              future: DatabaseService.getRecordsCount(),
              builder: (context, snapshot) {
                return TextButton.icon(
                  onPressed: _handleExport,
                  icon: const Icon(Icons.download, size: 16, color: Colors.grey),
                  label: const Text('Export', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1D2E),
                    side: const BorderSide(color: Color(0xFF2E3150)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Panel: Stats and Actions
            Container(
              width: 250,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D2E),
                border: Border.all(color: const Color(0xFF2E3150)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('OVERVIEW', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.analytics, color: Colors.blue),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<int>(
                              future: DatabaseService.getRecordsCount(),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                return Text('$count', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold));
                              }
                            ),
                            const Text('Sessions', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleExport,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Export Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.withValues(alpha: 0.2),
                        foregroundColor: Colors.blue,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (_exportMsg)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text('Export ready!', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right Panel: History List
            Expanded(
              child: FutureBuilder<List<HistoryRecord>>(
              future: DatabaseService.getAllRecords(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }
                final records = snapshot.data ?? [];
                if (records.isEmpty) {
                  return const Center(child: Text('No sessions recorded yet.', style: TextStyle(color: Colors.grey)));
                }
                final grouped = _groupRecords(records);
                final listItems = <Widget>[];
                int currentSerial = records.length;
                for (var entry in grouped.entries) {
                  listItems.add(
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
                      child: Text(entry.key, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                    )
                  );
                  for (var rec in entry.value) {
                    listItems.add(_buildHistoryItem(rec, currentSerial));
                    currentSerial--;
                  }
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: listItems,
                );
              }
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }

  Widget _buildHistoryItem(HistoryRecord rec, int serialNumber) {
    Color modeColorDark;
    Color modeColorLight;
    
    if (rec.mode == GameMode.audio) {
      modeColorLight = const Color(0xFFF4D03F); // Soft Sun Yellow
      modeColorDark = const Color(0xFFD4AC0D);
    } else if (rec.mode == GameMode.display) {
      modeColorLight = const Color(0xFF5DADE2); // Soft Sky Blue
      modeColorDark = const Color(0xFF2874A6);
    } else {
      modeColorLight = const Color(0xFFEC7063); // Soft Watermelon Pink
      modeColorDark = const Color(0xFFC0392B);
    }

    final modeIcon = rec.mode == GameMode.audio ? Icons.volume_up :
                     rec.mode == GameMode.display ? Icons.desktop_windows : Icons.layers;

    Color speedColor = Colors.grey;
    if (rec.speed.toLowerCase().contains('ultrafast')) { speedColor = Colors.redAccent; }
    else if (rec.speed.toLowerCase().contains('fast')) { speedColor = Colors.orange; }
    else if (rec.speed.toLowerCase().contains('normal')) { speedColor = Colors.green; }
    else if (rec.speed.toLowerCase().contains('slow')) { speedColor = Colors.lightBlue; }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E213A), // Slightly lighter dark background
        border: Border.all(color: const Color(0xFF2E3150), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          // Subtle dark 3D bottom edge for the card itself
          BoxShadow(
            color: Color(0xFF0D0F1C),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
          iconColor: Colors.grey,
          collapsedIconColor: Colors.grey,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            children: [
              // 3D Bubblegum Icon Box
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(Colors.white, modeColorLight, 0.4)!,
                      modeColorLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black26, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: modeColorDark, offset: const Offset(0, 4), blurRadius: 0),
                  ],
                ),
                child: Center(
                  child: Icon(modeIcon, color: Colors.white, size: 24, shadows: const [Shadow(color: Colors.black26, offset: Offset(0, 2))]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('#$serialNumber', style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: speedColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: speedColor.withValues(alpha: 0.3)),
                          ),
                          child: Text('${rec.speed.toUpperCase()} SPEED', style: TextStyle(color: speedColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(rec.datetime, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF2E3150))),
                color: Color(0x66252840),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('FLASH SEQUENCE', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '${rec.sequence.map((n) => n > 0 && rec.sequence.indexOf(n) > 0 ? ' + $n' : n < 0 ? ' - ${n.abs()}' : n).join()} = '),
                              TextSpan(
                                text: '${rec.answer}',
                                style: TextStyle(color: modeColorLight, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D2E),
                          border: Border.all(color: const Color(0xFF2E3150)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text('User: ', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            Text(rec.username, style: const TextStyle(color: Colors.white, fontSize: 10)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D2E),
                          border: Border.all(color: const Color(0xFF2E3150)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(rec.datetime, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
        ),
      ),
    );
  }
}
