import 'game_settings.dart';

class HistoryRecord {
  final String id;
  final String datetime;
  final int digits;
  final int count;
  final String speed;
  final GameMode mode;
  final List<int> sequence;
  final int answer;
  final String username;

  const HistoryRecord({
    required this.id,
    required this.datetime,
    required this.digits,
    required this.count,
    required this.speed,
    required this.mode,
    required this.sequence,
    required this.answer,
    required this.username,
  });
}

// Sample Data
final sampleHistory = [
  HistoryRecord(
    id: "1",
    datetime: "2026-07-02 09:14",
    digits: 2,
    count: 5,
    speed: "Normal",
    mode: GameMode.both,
    sequence: [34, -12, 56, -9, 21],
    answer: 90,
    username: "Alex",
  ),
  HistoryRecord(
    id: "2",
    datetime: "2026-07-02 08:55",
    digits: 1,
    count: 7,
    speed: "Fast",
    mode: GameMode.display,
    sequence: [7, 3, -2, 8, 1, -4, 6],
    answer: 19,
    username: "Alex",
  ),
  HistoryRecord(
    id: "3",
    datetime: "2026-07-01 21:30",
    digits: 3,
    count: 4,
    speed: "Ultra Slow",
    mode: GameMode.audio,
    sequence: [423, -111, 305, -88],
    answer: 529,
    username: "Alex",
  ),
  HistoryRecord(
    id: "4",
    datetime: "2026-07-01 19:05",
    digits: 2,
    count: 6,
    speed: "Slow",
    mode: GameMode.display,
    sequence: [45, 32, -11, 67, -20, 13],
    answer: 126,
    username: "Alex",
  ),
  HistoryRecord(
    id: "5",
    datetime: "2026-07-01 14:22",
    digits: 1,
    count: 3,
    speed: "Ultra Fast",
    mode: GameMode.both,
    sequence: [9, 5, -3],
    answer: 11,
    username: "Alex",
  ),
];
