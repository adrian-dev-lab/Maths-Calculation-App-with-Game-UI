import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import '../models/history_record.dart';
import '../models/game_settings.dart';
import '../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onNumberPracticeTap;
  final VoidCallback? onBeadsPracticeTap;

  const HistoryScreen({
    super.key, 
    required this.onBack, 
    this.onNumberPracticeTap, 
    this.onBeadsPracticeTap,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All'; // 'All', 'Number', 'Beads'
  String _sortOption = 'Newest First';
  late Future<List<HistoryRecord>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _recordsFuture = DatabaseService.getAllRecords();
  }

  // Colors based on the provided UI
  final Color bgColor = const Color(0xFF131127);
  final Color cardColor = const Color(0xFF1E1C38);
  final Color primaryPurple = const Color(0xFF7A40F2);
  final Color textGrey = const Color(0xFFA5A3B8);

  Future<void> _saveOrShareFile(String fileName, List<int> bytes, String shareText) async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final FileSaveLocation? result = await getSaveLocation(
        suggestedName: fileName,
      );
      if (result != null) {
        final file = File(result.path);
        await file.writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to ${result.path}', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        }
      }
    } else {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: shareText);
    }
  }

  void _handleCsvExport() async {
    try {
      final records = await DatabaseService.getAllRecords();
      if (records.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No records to export')));
        return;
      }
      
      final now = DateTime.now();
      final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final fileName = 'MGA_flash_calculation_history_$timestamp.csv';
      
      final buffer = StringBuffer();
      buffer.writeln('ID,Username,Date,Game Type,Mode,Speed,Digits,Count,Answer,Sequence');
      
      for (var r in records) {
        final mode = r.mode == GameMode.audio ? 'Audio' : r.mode == GameMode.display ? 'Display' : 'Mixed';
        final seq = r.sequence.join('|');
        buffer.writeln('${r.id},${r.username},${r.datetime},${r.gameType},$mode,${r.speed},${r.digits},${r.count},${r.answer},"$seq"');
      }
      
      final bytes = utf8.encode(buffer.toString());
      await _saveOrShareFile(fileName, bytes, 'Flash Calculation History (CSV)');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    }
  }

  void _handleExcelExport() async {
    try {
      final records = await DatabaseService.getAllRecords();
      if (records.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No records to export')));
        return;
      }
      
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];
      sheetObject.appendRow([
        TextCellValue('ID'), TextCellValue('Username'), TextCellValue('Date'), TextCellValue('Game Type'), TextCellValue('Mode'), 
        TextCellValue('Speed'), TextCellValue('Digits'), TextCellValue('Count'), TextCellValue('Answer'), TextCellValue('Sequence')
      ]);

      for (var r in records) {
        final mode = r.mode == GameMode.audio ? 'Audio' : r.mode == GameMode.display ? 'Display' : 'Mixed';
        final seq = r.sequence.join('|');
        sheetObject.appendRow([
          TextCellValue(r.id), TextCellValue(r.username), TextCellValue(r.datetime), TextCellValue(r.gameType), TextCellValue(mode),
          TextCellValue(r.speed), IntCellValue(r.digits), IntCellValue(r.count), IntCellValue(r.answer), TextCellValue(seq)
        ]);
      }

      final now = DateTime.now();
      final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final fileName = 'MGA_flash_calculation_history_$timestamp.xlsx';
      final fileBytes = excel.save();
      if (fileBytes != null) {
        await _saveOrShareFile(fileName, fileBytes, 'Flash Calculation History (Excel)');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    }
  }

  void _handlePdfExport() async {
    try {
      final records = await DatabaseService.getAllRecords();
      if (records.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No records to export')));
        return;
      }

      final font = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      final myanmarFont = await PdfGoogleFonts.notoSansMyanmarRegular();
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
          fontFallback: [myanmarFont],
        ),
      );
      
      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) {
            return [
              pw.Header(level: 0, child: pw.Text('Flash Calculation History')),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Date', 'User', 'Game Type', 'Mode', 'Speed', 'Ans', 'Seq'],
                  ...records.map((r) {
                    final mode = r.mode == GameMode.audio ? 'Audio' : r.mode == GameMode.display ? 'Display' : 'Mixed';
                    return [r.datetime, r.username, r.gameType, mode, r.speed, r.answer.toString(), r.sequence.join('|')];
                  })
                ],
              ),
            ];
          },
        ),
      );

      final now = DateTime.now();
      final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final fileName = 'MGA_flash_calculation_history_$timestamp.pdf';
      final bytes = await pdf.save();
      
      await _saveOrShareFile(fileName, bytes.toList(), 'Flash Calculation History (PDF)');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    }
  }

  int _getSpeedMs(String speed) {
    final s = speed.toLowerCase().replaceAll(' ', '');
    if (s == 'ultraslow') return 3000;
    if (s == 'slow') return 2000;
    if (s == 'normal') return 1000;
    if (s == 'fast') return 500;
    if (s == 'ultrafast') return 300;
    return 1000;
  }
  
  int _getRecordDurationSeconds(HistoryRecord rec) {
    if (rec.durationInSeconds > 0) return rec.durationInSeconds;
    if (rec.count <= 0) return 0;
    final speedMs = _getSpeedMs(rec.speed);
    final totalMs = (rec.count * speedMs) + ((rec.count - 1) * 400) + 500;
    return (totalMs / 1000).round();
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Map<String, List<HistoryRecord>> _groupRecords(List<HistoryRecord> records) {
    final Map<String, List<HistoryRecord>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
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
        groupName = 'Today   ${_formatDate(today)}';
      } else {
        groupName = _formatDate(dateOnly);
      }

      grouped.putIfAbsent(groupName, () => []).add(rec);
    }
    return grouped;
  }

  String _formatTime(String datetime) {
    try {
      final date = DateTime.parse(datetime);
      int hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }
      return '$hour:$minute $period';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FutureBuilder<List<HistoryRecord>>(
          future: _recordsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            List<HistoryRecord> allRecords = snapshot.data ?? [];
            
            // Filter
            List<HistoryRecord> filteredRecords = allRecords.where((r) {
              if (_selectedFilter == 'All') return true;
              if (_selectedFilter == 'Number') return r.gameType == 'Number';
              if (_selectedFilter == 'Beads') return r.gameType == 'Beads';
              return true;
            }).toList();

            final numRecords = allRecords.where((r) => r.gameType == 'Number').length;
            final beadsRecords = allRecords.length - numRecords;

            return Column(
              children: [
                _buildHeader(isMobile, allRecords.length),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
                    children: [
                      _buildStatsRow(isMobile, filteredRecords),
                      const SizedBox(height: 24),
                      _buildFilters(isMobile, allRecords.length, numRecords, beadsRecords),
                      const SizedBox(height: 24),
                      _buildList(filteredRecords, isMobile),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile, int totalSessions) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 20, isMobile ? 16 : 24, 10),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: widget.onBack,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('History', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('$totalSessions practice sessions', style: TextStyle(color: textGrey, fontSize: 14)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: const Color(0xFF1E1C38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF383561)),
            ),
            offset: const Offset(0, 50),
            onSelected: (value) {
              if (value == 'csv') {
                _handleCsvExport();
              } else if (value == 'xlsx') {
                _handleExcelExport();
              } else if (value == 'pdf') {
                _handlePdfExport();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'xlsx',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.table_chart, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    const Text('Export as Excel (.xlsx)', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.data_object, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    const Text('Export as CSV (.csv)', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    const Text('Export as PDF (.pdf)', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 10),
              decoration: BoxDecoration(
                color: primaryPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primaryPurple, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.download, color: Colors.white, size: 18),
                  if (!isMobile) ...[
                    const SizedBox(width: 8),
                    const Text('Export', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(width: 12),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isMobile, List<HistoryRecord> records) {
    final totalQuestions = records.fold(0, (sum, r) => sum + r.questionsPlayed);
    final totalSeconds = records.fold(0, (sum, r) => sum + _getRecordDurationSeconds(r));

    final items = [
      _StatItemData(
        title: 'Sessions',
        value: records.length,
        subtitle: 'Total Played',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFF0EA5E9),
      ),
      _StatItemData(
        title: 'Questions',
        value: totalQuestions,
        subtitle: 'Total Answered',
        icon: Icons.track_changes_rounded,
        color: const Color(0xFF22C55E),
      ),
      _StatItemData(
        title: 'Time',
        value: totalSeconds,
        subtitle: 'Practice Time',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFF97316),
        isTime: true,
      ),
    ];

    return _StatsRowAnimated(isMobile: isMobile, items: items);
  }

  Widget _buildFilters(bool isMobile, int total, int numbers, int beads) {
    final chips = [
      _FilterChipData('All ($total)', 'All', null),
      _FilterChipData(
        'Number ($numbers)', 
        'Number', 
        _buildIconBox(const Color(0xFF3B82F6), true, size: 24, scale: 0.35)
      ),
      _FilterChipData(
        'Beads ($beads)', 
        'Beads', 
        _buildIconBox(const Color(0xFF10B981), false, size: 24, scale: 0.4)
      ),
    ];

    Widget chipRow = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: chips.map((c) {
        final isSelected = _selectedFilter == c.value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => setState(() => _selectedFilter = c.value),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? primaryPurple : cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isSelected ? primaryPurple : Colors.white10),
              ),
              child: Row(
                children: [
                  if (c.icon != null) ...[
                    c.icon!,
                    const SizedBox(width: 6),
                  ],
                  Text(c.label, style: TextStyle(color: isSelected ? Colors.white : textGrey, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );

    final dropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isDense: true,
          value: _sortOption,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFA5A3B8), size: 20),
          dropdownColor: cardColor,
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(color: Color(0xFFA5A3B8)),
          items: ['Newest First', 'Oldest First', 'Most Questions', 'Longest Time'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _sortOption = newValue;
              });
            }
          },
        ),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: chipRow,
          ),
          const SizedBox(height: 16),
          dropdown,
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          chipRow,
          dropdown,
        ],
      );
    }
  }

  Widget _buildList(List<HistoryRecord> records, bool isMobile) {
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/empty_history.png',
                width: isMobile ? 240 : 300,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.history_toggle_off, size: 120, color: textGrey.withValues(alpha: 0.5));
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'No practice history yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start a practice session to see your history here.',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 280,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showPracticeDialog(context);
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                  label: const Text(
                    'Start Practice',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                    shadowColor: primaryPurple.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final listItems = <Widget>[];

    List<HistoryRecord> sortedRecords = List.from(records);

    if (_sortOption == 'Newest First' || _sortOption == 'Oldest First') {
      sortedRecords.sort((a, b) {
        final dateA = DateTime.tryParse(a.datetime) ?? DateTime.now();
        final dateB = DateTime.tryParse(b.datetime) ?? DateTime.now();
        return _sortOption == 'Newest First' ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
      });
      
      final grouped = _groupRecords(sortedRecords);
      for (var entry in grouped.entries) {
        listItems.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 12),
            child: Text(
              entry.key,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
        for (var rec in entry.value) {
          listItems.add(_buildHistoryItem(rec, isMobile));
        }
      }
    } else {
      if (_sortOption == 'Most Questions') {
        sortedRecords.sort((a, b) => b.questionsPlayed.compareTo(a.questionsPlayed));
      } else if (_sortOption == 'Longest Time') {
        sortedRecords.sort((a, b) => _getRecordDurationSeconds(b).compareTo(_getRecordDurationSeconds(a)));
      }
      
      listItems.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Text(
            'Sorted by $_sortOption',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      );
      for (var rec in sortedRecords) {
        listItems.add(_buildHistoryItem(rec, isMobile));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: listItems,
    );
  }

  Widget _buildHistoryItem(HistoryRecord rec, bool isMobile) {
    final isNumber = rec.gameType == 'Number'; 
    final title = rec.gameType;
    final iconBgColor = isNumber ? const Color(0xFF3B82F6) : const Color(0xFF10B981);
    
    List<Widget> tags = [];
    if (isNumber) {
      final modeText = rec.mode == GameMode.audio ? 'Audio Only' : rec.mode == GameMode.display ? 'Display Only' : 'Audio + Display';
      tags.add(_buildTag(modeText, primaryPurple, true));
      tags.add(_buildTag('${rec.digits} digits', Colors.white12, false));
      if (!isMobile) tags.add(_buildTag('${rec.count} numbers', Colors.white12, false));
      tags.add(_buildTag(rec.operation, Colors.white12, false));
      if (!isMobile) tags.add(_buildTag(rec.speed, Colors.white12, false));
    } else {
      tags.add(_buildTag('${rec.digits}-Bead Group', primaryPurple, true));
      tags.add(_buildTag('${rec.count} Flashes', Colors.white12, false));
      tags.add(_buildTag(rec.operation, Colors.white12, false));
      if (!isMobile) tags.add(_buildTag(rec.speed, Colors.white12, false));
    }

    // Real played data
    final questionsText = rec.questionsPlayed > 1 ? '${rec.questionsPlayed} questions' : '1 question';
    final durationSec = _getRecordDurationSeconds(rec);
    final durationText = durationSec >= 60 ? '${durationSec ~/ 60}m ${durationSec % 60}s' : '${durationSec}s';
    final timeStr = _formatTime(rec.datetime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: isMobile 
          ? _buildHistoryItemMobile(rec, title, iconBgColor, tags, questionsText, durationText, timeStr)
          : _buildHistoryItemDesktop(rec, title, iconBgColor, tags, questionsText, durationText, timeStr),
    );
  }

  Widget _buildHistoryItemDesktop(HistoryRecord rec, String title, Color iconBg, List<Widget> tags, String qText, String durText, String timeStr) {
    final isNumber = rec.gameType == 'Number';
    return Row(
      children: [
        _buildIconBox(iconBg, isNumber, size: 52, scale: 0.85),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description_outlined, color: textGrey, size: 16),
                  const SizedBox(width: 6),
                  Text(qText, style: TextStyle(color: textGrey, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, color: textGrey, size: 16),
                  const SizedBox(width: 6),
                  Text(durText, style: TextStyle(color: textGrey, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
        Text(timeStr, style: TextStyle(color: textGrey, fontSize: 14)),
      ],
    );
  }

  Widget _buildHistoryItemMobile(HistoryRecord rec, String title, Color iconBg, List<Widget> tags, String qText, String durText, String timeStr) {
    final isNumber = rec.gameType == 'Number';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconBox(iconBg, isNumber, size: 40, scale: 0.65),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title, 
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(timeStr, style: TextStyle(color: textGrey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.description_outlined, color: textGrey, size: 14),
                  const SizedBox(width: 4),
                  Text(qText, style: TextStyle(color: textGrey, fontSize: 12)),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, color: textGrey, size: 14),
                  const SizedBox(width: 4),
                  Text(durText, style: TextStyle(color: textGrey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconBox(Color bgColor, bool isNumber, {double size = 60, double scale = 1.0}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * (16/60)),
      ),
      child: Center(
        child: isNumber ? _buildNumberIcon(scale) : _buildAbacusIcon(scale),
      ),
    );
  }

  Widget _buildNumberIcon([double scale = 1.0]) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('1', style: TextStyle(color: Colors.white, fontSize: 18 * scale, fontWeight: FontWeight.w900, height: 1)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('2', style: TextStyle(color: Colors.white, fontSize: 18 * scale, fontWeight: FontWeight.w900, height: 1)),
            SizedBox(width: 4 * scale),
            Text('3', style: TextStyle(color: Colors.white, fontSize: 18 * scale, fontWeight: FontWeight.w900, height: 1)),
          ],
        )
      ],
    );
  }

  Widget _buildAbacusIcon([double scale = 1.0]) {
    Widget bead = Container(
      width: 8 * scale,
      height: 4 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2 * scale),
      ),
    );

    Widget wireWithBeads(int topBeads, int bottomBeads) {
      return SizedBox(
        width: 8 * scale,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(width: 2 * scale, height: 26 * scale, color: Colors.white54),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 7 * scale,
                  child: topBeads > 0 ? Center(child: bead) : null,
                ),
                SizedBox(
                  height: 18 * scale,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: List.generate(bottomBeads, (_) => Padding(padding: EdgeInsets.only(top: 1.5 * scale), child: bead)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      width: 36 * scale,
      height: 32 * scale,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2.5 * scale),
        borderRadius: BorderRadius.circular(4 * scale),
      ),
      child: Stack(
        children: [
          Positioned(top: 7 * scale, left: 0, right: 0, child: Container(height: 2.5 * scale, color: Colors.white)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              wireWithBeads(1, 2),
              wireWithBeads(0, 1),
              wireWithBeads(1, 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text, 
        style: TextStyle(
          color: isPrimary ? Colors.white : textGrey, 
          fontSize: 12, 
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal
        )
      ),
    );
  }

  void _showPracticeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1A34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    const Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Choose Your Practice', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('What would you like to do?', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildPracticeOptionCard(
                  context,
                  title: 'Number Calculation',
                  subtitle: 'Practice mental maths\nwith numbers',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  textColor: Colors.white,
                  iconBox: _buildIconBox(const Color(0xFF60A5FA), true, size: 64, scale: 1.1),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (widget.onNumberPracticeTap != null) {
                      widget.onNumberPracticeTap!();
                    } else {
                      widget.onBack();
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildPracticeOptionCard(
                  context,
                  title: 'Beads Calculation',
                  subtitle: 'Practice with abacus\n(beads)',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  textColor: Colors.white,
                  iconBox: _buildIconBox(const Color(0xFFA78BFA), false, size: 64, scale: 1.1),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (widget.onBeadsPracticeTap != null) {
                      widget.onBeadsPracticeTap!();
                    } else {
                      widget.onBack();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPracticeOptionCard(BuildContext context, {
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required Color textColor,
    required Widget iconBox,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            iconBox,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right_rounded, size: 24, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItemData {
  final String title;
  final int value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isTime;

  _StatItemData({
    required this.title, 
    required this.value, 
    required this.subtitle, 
    required this.icon, 
    required this.color,
    this.isTime = false,
  });
}

class _StatsRowAnimated extends StatefulWidget {
  final bool isMobile;
  final List<_StatItemData> items;

  const _StatsRowAnimated({required this.isMobile, required this.items});

  @override
  State<_StatsRowAnimated> createState() => _StatsRowAnimatedState();
}

class _StatsRowAnimatedState extends State<_StatsRowAnimated> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Row(
      children: widget.items.map((e) => Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 4 : 8),
          child: _buildStatCard(e, widget.isMobile),
        ),
      )).toList(),
    );
  }

  Widget _buildAnimatedNumber(int targetValue, bool isTime, Color color, bool isMobile) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: targetValue.toDouble()),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        final value = val.toInt();
        String display;
        if (isTime) {
          final hours = value ~/ 3600;
          final minutes = (value % 3600) ~/ 60;
          final seconds = value % 60;
          if (hours > 0) {
            display = '${hours}h ${minutes}m';
          } else if (minutes > 0) {
            display = '${minutes}m ${seconds}s';
          } else {
            display = '${seconds}s';
          }
        } else {
          display = value.toString();
        }
        return Text(
          display, 
          style: TextStyle(
            color: Colors.white, 
            fontSize: isMobile ? 32 : 52, 
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.8),
                blurRadius: 15,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(_StatItemData data, bool isMobile) {
    return Container(
      height: isMobile ? 115 : 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.color, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              data.icon,
              size: isMobile ? 80 : 140,
              color: data.color.withValues(alpha: 0.2),
            ),
          ),
          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 8 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          data.title.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 10 : 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: isMobile ? 0 : 1.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(isMobile ? 4 : 10),
                        decoration: BoxDecoration(
                          color: data.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(data.icon, color: data.color, size: isMobile ? 16 : 32),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 12 : 24),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _buildAnimatedNumber(data.value, data.isTime, data.color, isMobile),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    style: TextStyle(color: Colors.white70, fontSize: isMobile ? 9 : 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipData {
  final String label;
  final String value;
  final Widget? icon;
  _FilterChipData(this.label, this.value, this.icon);
}
