import 'dart:convert';
import 'dart:io' show Platform;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/history_record.dart';
import '../models/game_settings.dart';

class DatabaseService {
  static late Database _db;

  static Future<void> init() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'flash_anzan_history.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE history (
            id TEXT PRIMARY KEY,
            datetime TEXT,
            digits INTEGER,
            count INTEGER,
            speed TEXT,
            mode TEXT,
            sequence TEXT,
            answer INTEGER,
            username TEXT
          )
        ''');
      },
    );
  }

  static Future<void> insertRecord(HistoryRecord record) async {
    await _db.insert(
      'history',
      {
        'id': record.id,
        'datetime': record.datetime,
        'digits': record.digits,
        'count': record.count,
        'speed': record.speed,
        'mode': record.mode.name,
        'sequence': jsonEncode(record.sequence),
        'answer': record.answer,
        'username': record.username,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<HistoryRecord>> getAllRecords() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'history',
      orderBy: 'datetime DESC',
    );

    return List.generate(maps.length, (i) {
      final modeStr = maps[i]['mode'] as String;
      final mode = GameMode.values.firstWhere((e) => e.name == modeStr, orElse: () => GameMode.both);
      final sequenceList = List<int>.from(jsonDecode(maps[i]['sequence'] as String));

      return HistoryRecord(
        id: maps[i]['id'] as String,
        datetime: maps[i]['datetime'] as String,
        digits: maps[i]['digits'] as int,
        count: maps[i]['count'] as int,
        speed: maps[i]['speed'] as String,
        mode: mode,
        sequence: sequenceList,
        answer: maps[i]['answer'] as int,
        username: maps[i]['username'] as String,
      );
    });
  }

  static Future<int> getRecordsCount() async {
    final count = Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM history'));
    return count ?? 0;
  }

  static Future<ProfileStats> getProfileStats() async {
    final records = await getAllRecords();
    
    int gamesPlayed = records.length;
    GameMode favoriteMode = GameMode.display;
    int currentStreak = 0;

    if (records.isNotEmpty) {
      // Calculate favorite mode
      final modeCounts = <GameMode, int>{
        GameMode.audio: 0,
        GameMode.display: 0,
        GameMode.both: 0,
      };
      for (var r in records) {
        modeCounts[r.mode] = (modeCounts[r.mode] ?? 0) + 1;
      }
      favoriteMode = modeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      // Calculate streak
      final dates = records.map((r) => r.datetime.split(' ')[0]).toSet().toList();
      dates.sort((a, b) => b.compareTo(a)); // Descending

      final today = DateTime.now();
      final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

      if (dates.isNotEmpty && (dates[0] == todayStr || dates[0] == yesterdayStr)) {
        currentStreak = 1;
        DateTime currentDate = DateTime.parse(dates[0]);
        for (int i = 1; i < dates.length; i++) {
          final nextExpected = currentDate.subtract(const Duration(days: 1));
          final nextExpectedStr = "${nextExpected.year}-${nextExpected.month.toString().padLeft(2, '0')}-${nextExpected.day.toString().padLeft(2, '0')}";
          if (dates[i] == nextExpectedStr) {
            currentStreak++;
            currentDate = nextExpected;
          } else {
            break;
          }
        }
      }
    }

    return ProfileStats(
      gamesPlayed: gamesPlayed,
      favoriteMode: favoriteMode,
      currentStreak: currentStreak,
    );
  }
}

class ProfileStats {
  final int gamesPlayed;
  final GameMode favoriteMode;
  final int currentStreak;

  ProfileStats({
    required this.gamesPlayed,
    required this.favoriteMode,
    required this.currentStreak,
  });
}
