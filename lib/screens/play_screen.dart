import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/game_settings.dart';
import '../models/history_record.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

class PlayScreen extends StatefulWidget {
  final GameSettings settings;
  final ValueChanged<bool>? onPlayingStateChanged;

  const PlayScreen({super.key, required this.settings, this.onPlayingStateChanged});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

enum PlayPhase { idle, playing, answer }

class _PlayScreenState extends State<PlayScreen> {
  PlayPhase _phase = PlayPhase.idle;
  List<int> _sequence = [];
  int _currentIndex = 0;
  bool _showNumber = false;
  int _answer = 0;
  bool _isAnswerRevealed = false;
  Timer? _timer;
  final FlutterTts _tts = FlutterTts();

  final Map<GameSpeed, int> _speedMs = {
    GameSpeed.ultraFast: 500,
    GameSpeed.fast: 1000,
    GameSpeed.normal: 2000,
    GameSpeed.slow: 3000,
    GameSpeed.ultraSlow: 4500,
  };

  void _clearTimers() {
    _timer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _setupVoice();
    // default normal rate
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
  }

  Future<void> _setupVoice() async {
    try {
      final voices = await _tts.getVoices;
      if (voices != null) {
        for (var v in voices) {
          final name = (v['name'] as String).toLowerCase();
          if (widget.settings.voiceGender == TtsVoiceGender.female) {
            if (name.contains('zira') || name.contains('samantha') || name.contains('female')) {
              await _tts.setVoice({"name": v["name"], "locale": v["locale"]});
              break;
            }
          } else {
            if (!name.contains('female') && !name.contains('zira') && !name.contains('samantha')) {
              if (name.contains('david') || name.contains('alex') || name.contains('male')) {
                await _tts.setVoice({"name": v["name"], "locale": v["locale"]});
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error setting TTS voice: $e");
    }
  }

  @override
  void dispose() {
    _clearTimers();
    _tts.stop();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PlayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      if (oldWidget.settings.voiceGender != widget.settings.voiceGender) {
        _setupVoice();
      }
      _reset();
    }
  }

  int _generateNumber(int digits, bool canBeNegative) {
    final minVal = pow(10, digits - 1).toInt();
    final maxVal = pow(10, digits).toInt() - 1;
    var num = Random().nextInt(maxVal - minVal + 1) + minVal;
    if (canBeNegative && Random().nextDouble() < 0.4) {
      num = -num;
    }
    return num;
  }

  List<int> _buildSequence(int digits, int count) {
    final seq = <int>[];
    seq.add(_generateNumber(digits, false));
    int running = seq[0];

    for (int i = 1; i < count; i++) {
      int attempts = 0;
      int num;
      do {
        num = _generateNumber(digits, true);
        attempts++;
      } while (running + num < 0 && attempts < 100);

      if (running + num < 0) num = num.abs();
      seq.add(num);
      running += num;
    }
    return seq;
  }

  void _startGame() {
    _clearTimers();
    final seq = _buildSequence(widget.settings.digits, widget.settings.count);
    final ans = seq.fold(0, (prev, element) => prev + element);

    setState(() {
      _sequence = seq;
      _answer = ans;
      _currentIndex = 0;
      _showNumber = false;
      _isAnswerRevealed = false;
      _phase = PlayPhase.playing;
    });
    widget.onPlayingStateChanged?.call(true);

    _startSequence();
  }

  Future<void> _saveHistory() async {
    final now = DateTime.now();
    final dt = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final record = HistoryRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      datetime: dt,
      digits: widget.settings.digits,
      count: widget.settings.count,
      speed: widget.settings.speed.name,
      mode: widget.settings.mode,
      sequence: _sequence,
      answer: _answer,
      username: StorageService.loadUsername(),
    );
    await DatabaseService.insertRecord(record);
  }

  void _startSequence() {
    final delayMs = _speedMs[widget.settings.speed] ?? 2000;

    _timer = Timer(const Duration(milliseconds: 500), () {
      _showNextNumber(delayMs);
    });
  }

  void _showNextNumber(int delayMs) async {
    if (!mounted) return;
    
    final currentNum = _sequence[_currentIndex];
    
    setState(() {
      _showNumber = true;
    });

    if (widget.settings.mode == GameMode.audio || widget.settings.mode == GameMode.both) {
      double rate = 0.5;
      switch (widget.settings.speed) {
        case GameSpeed.ultraFast: rate = 1.0; break;
        case GameSpeed.fast: rate = 0.75; break;
        case GameSpeed.normal: rate = 0.5; break;
        case GameSpeed.slow: rate = 0.4; break;
        case GameSpeed.ultraSlow: rate = 0.3; break;
      }
      await _tts.setSpeechRate(rate);
      await _tts.stop(); // Stop any currently playing audio to prevent overlap/skipping
      await _tts.speak(currentNum.toString());
    }

    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      setState(() {
        _showNumber = false;
        _currentIndex++;
      });

      if (_currentIndex < _sequence.length) {
        _timer = Timer(const Duration(milliseconds: 400), () {
          _showNextNumber(delayMs);
        });
      } else {
        setState(() {
          _phase = PlayPhase.answer;
        });
        widget.onPlayingStateChanged?.call(false);
        _saveHistory();
      }
    });
  }

  void _reset() {
    _clearTimers();
    setState(() {
      _phase = PlayPhase.idle;
      _showNumber = false;
      _currentIndex = 0;
      _isAnswerRevealed = false;
    });
    widget.onPlayingStateChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MGA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text('Maths Genius Academy', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2E3150)),
            ),
            child: Row(
              children: [
                Icon(
                  widget.settings.mode == GameMode.audio ? Icons.volume_up :
                  widget.settings.mode == GameMode.display ? Icons.desktop_windows : Icons.layers,
                  size: 16, color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.settings.mode.name.toUpperCase(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Settings pill row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildSettingPill('Digits', widget.settings.digits.toString()),
                const SizedBox(width: 8),
                _buildSettingPill('Count', widget.settings.count.toString()),
                const SizedBox(width: 8),
                _buildSettingPill('Speed', widget.settings.speed.name.toUpperCase()),
              ],
            ),
          ),
          
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Center(child: _buildFlashCardArea()),
                    ),
                    const SizedBox(height: 32),
                    Center(child: _buildButtons()),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSettingPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E3150)),
      ),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFlashCardArea() {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2E3150)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 60,
            spreadRadius: 0,
          )
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_phase == PlayPhase.idle)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.blue, size: 32),
                ),
                const SizedBox(height: 12),
                const Text('Ready to test your math skills?', style: TextStyle(color: Colors.grey)),
              ],
            ),
          if (_phase == PlayPhase.playing && !_showNumber)
            const CircularProgressIndicator(),
          if (_phase == PlayPhase.playing && _showNumber)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.settings.mode == GameMode.audio)
                  const Icon(Icons.volume_up, size: 80, color: Colors.amber)
                else
                  Text(
                    _sequence[_currentIndex].toString(),
                    style: TextStyle(
                      fontSize: widget.settings.digits >= 3 ? 80 : 110,
                      fontWeight: FontWeight.w900,
                      color: _sequence[_currentIndex] < 0 ? Colors.red : Colors.white,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_sequence.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < _currentIndex ? Colors.blue : 
                               index == _currentIndex ? Colors.white : const Color(0xFF2E3150),
                      ),
                    );
                  }),
                )
              ],
            ),
          if (_phase == PlayPhase.answer)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('= ?', style: TextStyle(color: Colors.grey, fontSize: 16, letterSpacing: 2)),
                const SizedBox(height: 16),
                if (!_isAnswerRevealed)
                  const Text('?', style: TextStyle(color: Colors.amber, fontSize: 40, fontWeight: FontWeight.w900))
                else
                  Column(
                    children: [
                      Text('$_answer', style: const TextStyle(color: Colors.green, fontSize: 80, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(
                        '${_sequence.map((n) => n > 0 && _sequence.indexOf(n) > 0 ? '+$n' : n).join(' ')} = $_answer',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      )
                    ],
                  )
              ],
            )
        ],
      ),
      ),
    );
  }

  Widget _buildButtons() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        children: [
          if (_phase == PlayPhase.idle)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text('Start', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          if (_phase == PlayPhase.playing)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh, color: Colors.grey),
                label: const Text('Reset', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2E3150)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          if (_phase == PlayPhase.answer)
            if (!_isAnswerRevealed)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isAnswerRevealed = true),
                  icon: const Icon(Icons.visibility, color: Color(0xFF0F1117)),
                  label: const Text('Show Answer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F1117))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _startGame,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2E3150)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}


