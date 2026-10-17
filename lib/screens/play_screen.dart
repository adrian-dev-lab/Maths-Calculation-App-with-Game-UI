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
  final VoidCallback onSettingsTap;

  const PlayScreen({
    super.key,
    required this.settings,
    this.onPlayingStateChanged,
    required this.onBack,
    required this.onSettingsTap,
  });

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

  String? _sessionId;
  int _questionsPlayed = 0;
  int _totalDurationSeconds = 0;
  String _lastSessionSettings = '';

  final Map<GameSpeed, int> _speedMs = {
    GameSpeed.ultraFast: 500,
    GameSpeed.fast: 1000,
    GameSpeed.normal: 2000,
    GameSpeed.slow: 3000,
    GameSpeed.ultraSlow: 4500,
  };

  double get _baseFontSize {
    return switch (widget.settings.fontSize) {
      DisplayFontSize.extraSmall => 60.0,
      DisplayFontSize.small => 80.0,
      DisplayFontSize.normal => 110.0,
      DisplayFontSize.large => 140.0,
      DisplayFontSize.extraLarge => 170.0,
    };
  }

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
    final currentSettings =
        '${widget.settings.digits}|${widget.settings.count}|${widget.settings.speed.name}|${widget.settings.mode.name}';
    if (_sessionId == null || _lastSessionSettings != currentSettings) {
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _questionsPlayed = 0;
      _totalDurationSeconds = 0;
      _lastSessionSettings = currentSettings;
    }

    _questionsPlayed++;

    final delayMs = _speedMs[widget.settings.speed] ?? 2000;
    int currentDuration =
        ((widget.settings.count * delayMs) +
            (widget.settings.count - 1) * 400 +
            500) ~/
        1000;
    if (currentDuration < 1) currentDuration = 1;
    _totalDurationSeconds += currentDuration;

    final now = DateTime.now();
    final dt =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final record = HistoryRecord(
      id: _sessionId!,
      datetime: dt,
      digits: widget.settings.digits,
      count: widget.settings.count,
      speed: widget.settings.speed.name,
      mode: widget.settings.mode,
      sequence: _sequence,
      answer: _answer,
      username: StorageService.loadUsername(),
      gameType: 'Number',
      questionsPlayed: _questionsPlayed,
      durationInSeconds: _totalDurationSeconds,
      operation: 'Mixed',
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

    if (widget.settings.mode == GameMode.audio ||
        widget.settings.mode == GameMode.both) {
      _tts.speakNumber(currentNum.toString(), widget.settings.speed);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPlayingStateChanged?.call(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    // Small landscape phones have very little logical height, especially
    // at higher display densities. Keep game settings to one accessible row
    // instead of squeezing the number card below a two-row settings grid.
    final shortPhoneLandscape =
        viewport.width > viewport.height &&
        viewport.shortestSide < 600 &&
        viewport.height < 350;

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
          toolbarHeight: shortPhoneLandscape ? 48.0 : null,
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
              Text(
                'MGA',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                'Maths Genius Academy',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            if (_phase != PlayPhase.playing)
              Padding(
                padding: const EdgeInsets.only(
                  right: 16.0,
                  top: 8.0,
                  bottom: 8.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: widget.onSettingsTap,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Keep all four settings readable and accessible on tiny
            // landscape displays without consuming two rows of game space.
            if (shortPhoneLandscape)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
                child: Semantics(
                  button: true,
                  label:
                      'Calculation settings: '
                      '${widget.settings.digits} digits, '
                      '${widget.settings.count} numbers, '
                      '${widget.settings.speed.name} speed, '
                      '${widget.settings.mode.name} mode',
                  child: GestureDetector(
                    onTap: widget.onSettingsTap,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.09),
                        border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.28),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tune,
                            size: 18,
                            color: Colors.cyanAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'DIGITS ${widget.settings.digits}  ·  '
                                'COUNT ${widget.settings.count}  ·  '
                                '${widget.settings.speed.name.toUpperCase()}  ·  '
                                '${widget.settings.mode.name.toUpperCase()}',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.cyanAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width > 600
                        ? 500
                        : 320,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildSettingPill(
                            context,
                            'Digits',
                            widget.settings.digits.toString(),
                            Icons.numbers,
                            Colors.cyanAccent,
                          ),
                          const SizedBox(width: 8),
                          _buildSettingPill(
                            context,
                            'Count',
                            widget.settings.count.toString(),
                            Icons.repeat,
                            Colors.orangeAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildSettingPill(
                            context,
                            'Speed',
                            widget.settings.speed.name.toUpperCase(),
                            Icons.speed,
                            Colors.pinkAccent,
                          ),
                          const SizedBox(width: 8),
                          _buildSettingPill(
                            context,
                            'Mode',
                            widget.settings.mode.name.toUpperCase(),
                            widget.settings.mode == GameMode.audio
                                ? Icons.volume_up
                                : widget.settings.mode == GameMode.display
                                ? Icons.desktop_windows
                                : Icons.layers,
                            Colors.purpleAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, space) {
                  // Use the short side to detect compact landscape phones.
                  // Width-only checks wrongly classify some phones as desktop.
                  final viewport = MediaQuery.sizeOf(context);
                  final compactPhoneLandscape =
                      viewport.width > viewport.height &&
                      viewport.shortestSide < 600;

                  if (compactPhoneLandscape) {
                    // Keep the flash card and primary action side-by-side.
                    // Stacking both vertically on short landscape screens
                    // compresses the flash card until numbers are unreadable.
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        shortPhoneLandscape ? 8 : 12,
                        shortPhoneLandscape ? 2 : 4,
                        shortPhoneLandscape ? 8 : 12,
                        shortPhoneLandscape ? 6 : 12,
                      ),
                      child: LayoutBuilder(
                        builder: (context, rowSpace) {
                          final gap = shortPhoneLandscape ? 8.0 : 10.0;
                          // The card and action rail share the SAME measured
                          // height, so the button tracks the card's lower edge
                          // instead of floating near the top of the screen.
                          final cardWidthBudget =
                              (rowSpace.maxWidth - gap) * 0.72;
                          final cardHeight = min(
                            rowSpace.maxHeight,
                            cardWidthBudget / (16 / 9),
                          );

                          return Center(
                            child: SizedBox(
                              width: rowSpace.maxWidth,
                              height: cardHeight,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 72,
                                    child: Center(
                                      child: _buildFlashCardArea(context),
                                    ),
                                  ),
                                  SizedBox(width: gap),
                                  Expanded(
                                    flex: 28,
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: _buildButtons(
                                        compact: true,
                                        compactSmall: shortPhoneLandscape,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }

                  final mobile = viewport.width <= 600;
                  if (!mobile) {
                    // Keep the existing Windows / large-screen composition.
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 80,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Center(
                                child: _buildFlashCardArea(context),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Center(child: _buildButtons()),
                          ],
                        ),
                      ),
                    );
                  }

                  // The phone layout scrolls instead of compressing the card
                  // into a few pixels on short / landscape viewports.
                  final cardWidth = (space.maxWidth - 32).clamp(0.0, 420.0);
                  final cardHeight = (cardWidth * 0.75).clamp(220.0, 315.0);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            height: cardHeight,
                            child: _buildFlashCardArea(context),
                          ),
                          const SizedBox(height: 16),
                          _buildButtons(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingPill(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isLarge = MediaQuery.of(context).size.width > 600;
    return Expanded(
      child: GestureDetector(
        onTap: widget.onSettingsTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: isLarge
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: isLarge ? 18 : 14),
              const SizedBox(width: 6),
              Text(
                '$label: ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isLarge ? 14 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: isLarge ? 16 : 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: color.withValues(alpha: 0.7),
                size: isLarge ? 20 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlashCardArea(BuildContext context) {
    final isLarge = MediaQuery.of(context).size.width > 600;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: AspectRatio(
        aspectRatio: isLarge ? 16 / 9 : 4 / 3,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(
              0xFF1A0B2E,
            ), // Solid deep purple color to match the mask
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.cyanAccent.withValues(alpha: 0.3),
              width: 2,
            ),
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
                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildHudCorner(true, true),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildHudCorner(true, false),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: _buildHudCorner(false, true),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: _buildHudCorner(false, false),
                ),
                // Top and Bottom HUD scanlines
                Positioned(
                  top: 0,
                  child: Container(
                    width: 200,
                    height: 3,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.cyanAccent,
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.cyanAccent, blurRadius: 10),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 200,
                    height: 3,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.pinkAccent,
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.pinkAccent, blurRadius: 10),
                      ],
                    ),
                  ),
                ),
                if (_phase == PlayPhase.idle)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final availableHeight = constraints.maxHeight;
                      final availableWidth = constraints.maxWidth;
                      final isMobile = MediaQuery.of(context).size.width <= 600;

                      final mascotSize = isMobile
                          ? (availableHeight * 0.55).clamp(0.0, 150.0)
                          : (availableHeight * 0.65).clamp(0.0, 280.0);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (availableHeight > 65)
                            Flexible(
                              child: Image.asset(
                                'assets/images/mascot_home.png',
                                width: mascotSize,
                                height: mascotSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                          if (availableHeight > 90) const SizedBox(height: 8),
                          if (availableHeight > 45 && availableWidth > 100)
                            Text(
                              'Ready to test your math skills?',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: isMobile ? 12 : 18,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                if (_phase == PlayPhase.playing && !_showNumber)
                  const CircularProgressIndicator(),
                if (_phase == PlayPhase.playing && _showNumber)
                  _fitFlashContent(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.settings.mode == GameMode.audio)
                          const Icon(
                            Icons.volume_up,
                            size: 80,
                            color: Colors.amber,
                          )
                        else
                          Text(
                            _sequence[_currentIndex].toString(),
                            style: TextStyle(
                              fontSize: _baseFontSize,
                              fontWeight: FontWeight.w900,
                              color: _sequence[_currentIndex] < 0
                                  ? Colors.red
                                  : Colors.white,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_sequence.length, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index < _currentIndex
                                    ? Colors.blue
                                    : index == _currentIndex
                                    ? Colors.white
                                    : const Color(0xFF2E3150),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                if (_phase == PlayPhase.answer)
                  _fitFlashContent(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '= ?',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: _baseFontSize * 0.25,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!_isAnswerRevealed)
                          Text(
                            '?',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: _baseFontSize * 0.5,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        else
                          Column(
                            children: [
                              Text(
                                '$_answer',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: _baseFontSize * 0.8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  '${_sequence.map((n) => n > 0 && _sequence.indexOf(n) > 0 ? '+$n' : n).join(' ')} = $_answer',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Scale down oversized number, answer and progress content without
  // modifying the user's selected font size or changing desktop styling.
  Widget _fitFlashContent(Widget child) {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: child,
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
          top: isTop
              ? const BorderSide(color: Colors.cyanAccent, width: 3)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Colors.cyanAccent, width: 3)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Colors.cyanAccent, width: 3)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Colors.cyanAccent, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildButtons({bool compact = false, bool compactSmall = false}) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: compact ? (compactSmall ? 112.0 : 140.0) : 280.0,
      ),
      child: Column(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (_phase == PlayPhase.idle)
            _PlayGameButton(
              onPressed: _startGame,
              label: 'Start',
              compact: compact,
              compactSmall: compactSmall,
              icon: Icons.rocket_launch,
              colors: const [Colors.pinkAccent, Colors.deepOrangeAccent],
            ),
          if (_phase == PlayPhase.playing)
            _PlayGameButton(
              onPressed: _reset,
              label: 'Reset',
              compact: compact,
              compactSmall: compactSmall,
              icon: Icons.refresh,
              colors: const [Colors.purpleAccent, Colors.deepPurpleAccent],
            ),
          if (_phase == PlayPhase.answer)
            if (!_isAnswerRevealed)
              _PlayGameButton(
                onPressed: () => setState(() => _isAnswerRevealed = true),
                label: 'Show Answer',
                compact: compact,
                compactSmall: compactSmall,
                icon: Icons.visibility,
                colors: const [Colors.orangeAccent, Colors.deepOrangeAccent],
              )
            else
              _PlayGameButton(
                onPressed: _startGame,
                label: 'Next',
                compact: compact,
                compactSmall: compactSmall,
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
  final bool compact;
  final bool compactSmall;

  const _PlayGameButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.colors,
    this.compact = false,
    this.compactSmall = false,
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
          height: widget.compact
              ? (widget.compactSmall ? 44.0 : 46.0)
              : 64.0,
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
                    border: Border.all(
                      color: widget.colors.first.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
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
                          Icon(
                            widget.icon,
                            color: Colors.white,
                            size: widget.compact
                                ? (widget.compactSmall ? 16.0 : 17.0)
                                : 24.0,
                          ),
                          SizedBox(width: widget.compact ? 5.0 : 8.0),
                          if (widget.compact)
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.label.toUpperCase(),
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: widget.compactSmall ? 11.0 : 12.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          else
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
