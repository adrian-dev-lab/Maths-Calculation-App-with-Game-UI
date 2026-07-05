import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import '../models/history_record.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';

class PlayScreen extends StatefulWidget {
  final GameSettings settings;
  final ValueChanged<bool>? onPlayingStateChanged;
  final VoidCallback onBack;

  const PlayScreen({super.key, required this.settings, this.onPlayingStateChanged, required this.onBack});

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
  final _tts = TtsService();

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
    await _tts.init();
    await _tts.setupVoice(widget.settings.voiceGender);
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
        _tts.setupVoice(widget.settings.voiceGender);
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

  void _showNextNumber(int delayMs) {
    if (!mounted) return;
    
    final currentNum = _sequence[_currentIndex];
    
    setState(() {
      _showNumber = true;
    });

    if (widget.settings.mode == GameMode.audio || widget.settings.mode == GameMode.both) {
      _tts.setSpeechRate(widget.settings.speed);
      _tts.speak(currentNum.toString());
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
          onPressed: () {
            if (_phase == PlayPhase.playing) {
              widget.onPlayingStateChanged?.call(false);
            }
            widget.onBack();
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MGA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text('Maths Genius Academy', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Settings pill row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSettingPill('Digits', widget.settings.digits.toString(), Icons.numbers, Colors.cyanAccent),
                    const SizedBox(width: 8),
                    _buildSettingPill('Count', widget.settings.count.toString(), Icons.repeat, Colors.orangeAccent),
                    const SizedBox(width: 8),
                    _buildSettingPill('Speed', widget.settings.speed.name.toUpperCase(), Icons.speed, Colors.pinkAccent),
                    const SizedBox(width: 8),
                    _buildSettingPill(
                      'Mode', 
                      widget.settings.mode.name.toUpperCase(), 
                      widget.settings.mode == GameMode.audio ? Icons.volume_up :
                      widget.settings.mode == GameMode.display ? Icons.desktop_windows : Icons.layers, 
                      Colors.purpleAccent
                    ),
                  ],
                ),
              ),
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
      ),
    );
  }

  Widget _buildSettingPill(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 0,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
        ],
      ),
    );
  }

  Widget _buildFlashCardArea() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0B2E), // Solid deep purple color to match the mask
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.1),
              blurRadius: 30,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.purpleAccent.withValues(alpha: 0.15),
              blurRadius: 60,
              spreadRadius: 5,
            ),
          ],
        ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // HUD Corner Accents
            Positioned(top: 16, left: 16, child: _buildHudCorner(true, true)),
            Positioned(top: 16, right: 16, child: _buildHudCorner(true, false)),
            Positioned(bottom: 16, left: 16, child: _buildHudCorner(false, true)),
            Positioned(bottom: 16, right: 16, child: _buildHudCorner(false, false)),
            // Top and Bottom HUD scanlines
            Positioned(
              top: 0,
              child: Container(width: 200, height: 3, decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, Colors.cyanAccent, Colors.transparent]),
                boxShadow: [BoxShadow(color: Colors.cyanAccent, blurRadius: 10)],
              )),
            ),
            Positioned(
              bottom: 0,
              child: Container(width: 200, height: 3, decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, Colors.pinkAccent, Colors.transparent]),
                boxShadow: [BoxShadow(color: Colors.pinkAccent, blurRadius: 10)],
              )),
            ),
            if (_phase == PlayPhase.idle)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/mascot_home.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
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
      ),
    );
  }

  Widget _buildHudCorner(bool isTop, bool isLeft) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.cyanAccent, width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.cyanAccent, width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.cyanAccent, width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.cyanAccent, width: 3) : BorderSide.none,
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
            _PlayGameButton(
              onPressed: _startGame,
              label: 'Start',
              icon: Icons.rocket_launch,
              colors: const [Colors.pinkAccent, Colors.deepOrangeAccent],
            ),
          if (_phase == PlayPhase.playing)
            _PlayGameButton(
              onPressed: _reset,
              label: 'Reset',
              icon: Icons.refresh,
              colors: const [Colors.purpleAccent, Colors.deepPurpleAccent],
            ),
          if (_phase == PlayPhase.answer)
            if (!_isAnswerRevealed)
              _PlayGameButton(
                onPressed: () => setState(() => _isAnswerRevealed = true),
                label: 'Show Answer',
                icon: Icons.visibility,
                colors: const [Colors.orangeAccent, Colors.deepOrangeAccent],
              )
            else
              _PlayGameButton(
                onPressed: _startGame,
                label: 'Next',
                icon: Icons.skip_next,
                colors: const [Colors.greenAccent, Colors.green],
              ),
        ],
      ),
    );
  }
}

class _PlayGameButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final List<Color> colors;

  const _PlayGameButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.colors,
  });

  @override
  State<_PlayGameButton> createState() => _PlayGameButtonState();
}

class _PlayGameButtonState extends State<_PlayGameButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Transform(
        transform: Matrix4.skewX(-0.1),
        child: SizedBox(
          height: 64,
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                top: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.colors.last.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 100),
                bottom: _isPressed ? 0 : 8,
                left: 0,
                right: 0,
                top: _isPressed ? 8 : 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: widget.colors.first.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: widget.colors.first.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Transform(
                      transform: Matrix4.skewX(0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.icon, color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            widget.label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


