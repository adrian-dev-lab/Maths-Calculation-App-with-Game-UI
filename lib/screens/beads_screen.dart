import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

import '../widgets/beads_mystery_visual.dart';
import '../widgets/beads_settings_dialog.dart';
import '../services/storage_service.dart';
import '../models/game_settings.dart';
import '../services/database_service.dart';
import '../models/history_record.dart';

enum FlashState { idle, flashing, question, answer }

class BeadsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const BeadsScreen({super.key, required this.onBack});

  @override
  State<BeadsScreen> createState() => _BeadsScreenState();
}

class _BeadsScreenState extends State<BeadsScreen> {
  late int sequenceLength;
  late String speed;
  late int digitsCount;
  late String operation;

  FlashState currentState = FlashState.idle;
  List<int> numbers = [];
  int currentFlashIndex = 0;
  bool isFlashingVisible = false;
  int totalSum = 0;
  Timer? flashTimer;
  double baseFontSize = 24.0;

  String? _sessionId;
  int _questionsPlayed = 0;
  int _totalDurationSeconds = 0;
  String _lastSessionSettings = '';

  @override
  void initState() {
    super.initState();
    sequenceLength = StorageService.loadBeadsSequence();
    speed = StorageService.loadBeadsSpeed();
    digitsCount = StorageService.loadBeadsGroup();
    operation = StorageService.loadBeadsOperation();
    _loadFontSize();
  }

  void _loadFontSize() {
    final settings = StorageService.loadSettings();
    switch (settings.fontSize) {
      case DisplayFontSize.extraSmall:
        baseFontSize = 12.0;
        break;
      case DisplayFontSize.small:
        baseFontSize = 16.0;
        break;
      case DisplayFontSize.normal:
        baseFontSize = 24.0;
        break;
      case DisplayFontSize.large:
        baseFontSize = 32.0;
        break;
      case DisplayFontSize.extraLarge:
        baseFontSize = 48.0;
        break;
    }
  }

  void _showSettings() {
    if (currentState != FlashState.idle) {
      return; // Prevent settings while playing
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BeadsSettingsScreen(
          initialColumnCount: sequenceLength,
          initialSpeed: speed,
          initialGroup: digitsCount,
          initialOperation: operation,
          onSave: (newSequence, newSpeed, newGroup, newOperation) {
            StorageService.saveBeadsSequence(newSequence);
            StorageService.saveBeadsSpeed(newSpeed);
            StorageService.saveBeadsGroup(newGroup);
            StorageService.saveBeadsOperation(newOperation);
            setState(() {
              sequenceLength = newSequence;
              speed = newSpeed;
              digitsCount = newGroup;
              operation = newOperation;
            });
          },
        ),
      ),
    );
  }

  void _startFlash() {
    // Generate random numbers
    final rand = math.Random();
    int minVal = digitsCount == 1 ? 1 : math.pow(10, digitsCount - 1).toInt();
    int maxVal = math.pow(10, digitsCount).toInt() - 1;

    numbers = [];
    int currentSum = 0;

    for (int i = 0; i < sequenceLength; i++) {
      int val = minVal + rand.nextInt(maxVal - minVal + 1);

      bool makeNegative = false;
      if (i > 0) {
        if (operation == 'Subtraction') {
          makeNegative = true;
        } else if (operation == 'Mixed') {
          makeNegative = rand.nextBool();
        }
      }

      if (makeNegative) {
        if (currentSum >= minVal) {
          int maxSub = math.min(currentSum, maxVal);
          val = -(minVal + rand.nextInt(maxSub - minVal + 1));
        } else {
          // If we can't subtract without going below 0 (and below minVal digits), just add
          val = val;
        }
      }

      numbers.add(val);
      currentSum += val;
    }
    totalSum = currentSum;

    setState(() {
      currentState = FlashState.flashing;
      currentFlashIndex = 0;
      isFlashingVisible = true;
    });

    int delayMs = speed == 'Fast' ? 600 : (speed == 'Slow' ? 1800 : 1200);
    int showMs = (delayMs * 0.7).toInt();
    int hideMs = delayMs - showMs;

    _runFlashLoop(showMs, hideMs);
  }

  Future<void> _saveHistory() async {
    final currentSettings = '$sequenceLength|$speed|$digitsCount|$operation';
    if (_sessionId == null || _lastSessionSettings != currentSettings) {
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _questionsPlayed = 0;
      _totalDurationSeconds = 0;
      _lastSessionSettings = currentSettings;
    }

    _questionsPlayed++;
    int delayMs = speed == 'Fast' ? 600 : (speed == 'Slow' ? 1800 : 1200);
    int currentDuration = ((sequenceLength * delayMs) + 300) ~/ 1000;
    if (currentDuration < 1) currentDuration = 1;
    _totalDurationSeconds += currentDuration;

    final now = DateTime.now();
    final dt = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final record = HistoryRecord(
      id: _sessionId!,
      datetime: dt,
      digits: digitsCount,
      count: sequenceLength,
      speed: speed,
      mode: GameMode.display,
      sequence: numbers,
      answer: totalSum,
      username: StorageService.loadUsername(),
      gameType: 'Beads',
      questionsPlayed: _questionsPlayed,
      durationInSeconds: _totalDurationSeconds,
      operation: operation,
    );
    await DatabaseService.insertRecord(record);
  }

  void _runFlashLoop(int showMs, int hideMs) {
    if (currentFlashIndex >= numbers.length) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            currentState = FlashState.question;
          });
          _saveHistory();
        }
      });
      return;
    }

    if (mounted) {
      setState(() {
        isFlashingVisible = true;
      });
    }

    flashTimer = Timer(Duration(milliseconds: showMs), () {
      if (mounted) {
        setState(() {
          isFlashingVisible = false;
        });

        flashTimer = Timer(Duration(milliseconds: hideMs), () {
          currentFlashIndex++;
          _runFlashLoop(showMs, hideMs);
        });
      }
    });
  }

  @override
  void dispose() {
    flashTimer?.cancel();
    super.dispose();
  }



  Widget _buildSettingItem(IconData icon, String title, String value, Color iconBgColor, Color iconColor) {
    return Expanded(
      child: GestureDetector(
        onTap: _showSettings,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E143B), // Dark card background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // Compact landscape phones have enough horizontal room, but not enough
  // vertical room for the tablet-style column of hero, settings, and Start.
  // Keep the settings and Start visible together without altering gameplay.
  Widget _buildLandscapePhoneIdle() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _ReadyFinalHero(maxHeight: 104),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: baseFontSize * 1.3,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          children: const [
                            TextSpan(text: 'Ready to '),
                            TextSpan(
                              text: 'start?',
                              style: TextStyle(color: Color(0xFFA155FF)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _buildSettingItem(
                          Icons.desktop_windows_rounded,
                          'Display',
                          '$sequenceLength',
                          const Color(0xFF332066),
                          const Color(0xFF8660EB),
                        ),
                        const SizedBox(width: 10),
                        _buildSettingItem(
                          Icons.speed_rounded,
                          'Speed',
                          speed,
                          const Color(0xFF1C423E),
                          const Color(0xFF49DCA4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSettingItem(
                          Icons.calculate_rounded,
                          'Operation',
                          operation,
                          const Color(0xFF4C2A24),
                          const Color(0xFFE28B36),
                        ),
                        const SizedBox(width: 10),
                        _buildSettingItem(
                          Icons.view_stream_rounded,
                          'Group',
                          '$digitsCount Beads',
                          const Color(0xFF45193B),
                          const Color(0xFFE954B5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA155FF), Color(0xFF6B20FF)],
                          ),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _startFlash,
                          icon: const Icon(Icons.play_arrow_rounded, size: 25),
                          label: const Text(
                            'Start',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
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

  Widget _buildContent({double? availableHeight}) {
    if (currentState == FlashState.idle) {
      final bool compact =
          availableHeight != null && availableHeight < 850;
      final bool veryCompact =
          availableHeight != null && availableHeight < 540;
      // Only change the short, wide phone layout. Tablets retain the
      // previously verified v2 layout; portrait/small widths stay scrollable.
      final viewWidth = MediaQuery.sizeOf(context).width;
      if (availableHeight != null && availableHeight < 540 &&
          viewWidth > availableHeight && viewWidth >= 560) {
        return _buildLandscapePhoneIdle();
      }
      final double? heroMaxHeight = compact
          ? (veryCompact
              ? 105.0
              : (availableHeight * 0.28).clamp(160.0, 220.0).toDouble())
          : null;
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: compact ? 8 : 20),
                // Decorative Abacus Icon Area
                _ReadyFinalHero(maxHeight: heroMaxHeight),
                SizedBox(height: compact ? 12 : 22),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: baseFontSize * 1.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      children: const [
                        TextSpan(text: 'Ready to '),
                        TextSpan(
                          text: 'start?',
                          style: TextStyle(color: Color(0xFFA155FF)), // Bright purple
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: compact ? 10 : 16),
                if (!veryCompact) const Text(
                  'Watch the bead patterns and\ncalculate mentally.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white60,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: compact ? 14 : 40),
                
                // Settings Grid
                // Settings Grid
                Column(
                  children: [
                    Row(
                      children: [
                        _buildSettingItem(
                          Icons.desktop_windows_rounded, 
                          'Display', 
                          '$sequenceLength', 
                          const Color(0xFF332066), 
                          const Color(0xFF8660EB)
                        ),
                        const SizedBox(width: 16),
                        _buildSettingItem(
                          Icons.speed_rounded, 
                          'Speed', 
                          speed, 
                          const Color(0xFF1C423E), 
                          const Color(0xFF49DCA4)
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 10 : 16),
                    Row(
                      children: [
                        _buildSettingItem(
                          Icons.calculate_rounded, 
                          'Operation', 
                          operation, 
                          const Color(0xFF4C2A24), 
                          const Color(0xFFE28B36)
                        ),
                        const SizedBox(width: 16),
                        _buildSettingItem(
                          Icons.view_stream_rounded, 
                          'Group', 
                          '$digitsCount Beads', 
                          const Color(0xFF45193B), 
                          const Color(0xFFE954B5)
                        ),
                      ],
                    ),
                  ],
                ),
                
                SizedBox(height: compact ? 14 : 40),
                
                // Start Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFA155FF), Color(0xFF6B20FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B20FF).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _startFlash,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, // Transparent to show gradient
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.play_arrow_rounded, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Start',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 10 : 24),
              ],
            ),
          ),
        ),
      );
    } else if (currentState == FlashState.flashing) {
      if (!isFlashingVisible) {
        return const Center(child: SizedBox()); // Empty screen when hidden
      }
      int currentNum = numbers[currentFlashIndex];
      return _BeadsFlashVisual(
        value: currentNum.abs(),
        columnCount: digitsCount,
        isNegative: currentNum < 0,
      );
    } else if (currentState == FlashState.question) {
      return _BeadsQuestionView(
        onShowAnswer: () {
          setState(() {
            currentState = FlashState.answer;
          });
        },
      );
    } else if (currentState == FlashState.answer) {
      return _BeadsAnswerResult(
        answer: totalSum,
        onPlayAgain: () {
          setState(() {
            currentState = FlashState.idle;
          });
        },
      );
    }
    return const SizedBox();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100520), // Darker purple reference palette
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: widget.onBack,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        title: const Text(
          'Beads Flash',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (currentState == FlashState.idle)
            Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
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
                  onPressed: _showSettings,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6B20FF).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF9E63FF).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Dark Clouds at the bottom (as seen in mockup)
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1E0A3C),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF220D42),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            left: 50,
            right: 0,
            child: Container(
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A0835),
              ),
            ),
          ),
          // Main Body
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                // The body extends behind the AppBar, so give the idle
                // controls a safe top offset. Other play states are unchanged.
                padding: currentState == FlashState.idle
                    ? const EdgeInsets.only(top: 64, bottom: 12)
                    : EdgeInsets.zero,
                child: _buildContent(
                  availableHeight: MediaQuery.sizeOf(context).height,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// Beads Question View
// ============================================================

class _BeadsQuestionView extends StatelessWidget {
  final VoidCallback onShowAnswer;

  const _BeadsQuestionView({
    required this.onShowAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final viewSize = MediaQuery.sizeOf(context);
    // Keep the question and its action visible on short landscape phones.
    // Tablet and portrait layouts remain unchanged.
    if (viewSize.height < 540 &&
        viewSize.width > viewSize.height &&
        viewSize.width >= 560) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 12),
            child: Row(
              children: [
                const Expanded(
                  flex: 4,
                  child: AspectRatio(
                    aspectRatio: 584 / 398,
                    child: BeadsMysteryVisual(),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'What is the answer?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF8F5FF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Calculate in your head.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFC9BDD9),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFAA4BFF),
                                Color(0xFF8731FF),
                                Color(0xFF5E28FF),
                              ],
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(25),
                              onTap: onShowAnswer,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.visibility_outlined,
                                      color: Colors.white, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Show Answer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
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
              ],
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = MediaQuery.sizeOf(context);

        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screenSize.width;

        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : screenSize.height;

        // Match the idle screen constraint: maxWidth 500, with 24 horizontal padding
        final contentWidth = (availableWidth > 500 ? 500.0 : availableWidth) - 48.0;

        final titleSize = (contentWidth * 0.08).clamp(34.0, 58.0);
        final subtitleSize = (contentWidth * 0.039).clamp(17.0, 26.0);

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: availableHeight < 700 ? 20 : 30,
            ),
            child: SizedBox(
              width: contentWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: const AspectRatio(
                      aspectRatio: 584 / 398,
                      child: BeadsMysteryVisual(),
                    ),
                  ),

                  SizedBox(
                    height: (contentWidth * 0.02).clamp(0.0, 16.0),
                  ),

                  Text(
                    'What is the answer?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleSize,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF8F5FF),
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: (contentWidth * 0.02)
                        .clamp(8.0, 16.0),
                  ),

                  Text(
                    'Calculate in your head.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFC9BDD9),
                    ),
                  ),

                  SizedBox(
                    height: (contentWidth * 0.085)
                        .clamp(34.0, 58.0),
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 56.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(28.0),

                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFFAA4BFF),
                            Color(0xFF8731FF),
                            Color(0xFF5E28FF),
                          ],
                        ),

                        border: Border.all(
                          color: const Color(0xFFC58AFF)
                              .withValues(alpha: 0.65),
                          width: 1.4,
                        ),

                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x667D35FF),
                            blurRadius: 26,
                            spreadRadius: 1,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),

                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(28.0),
                          onTap: onShowAnswer,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_outlined,
                                  color: Colors.white,
                                  size: 26,
                                ),

                                const SizedBox(width: 8),

                                Text(
                                  'Show Answer',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
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
      },
    );
  }
}



// ============================================================
// Beads Answer Result
// ============================================================

class _BeadsAnswerResult extends StatelessWidget {
  final int answer;
  final VoidCallback onPlayAgain;

  const _BeadsAnswerResult({
    required this.answer,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = MediaQuery.sizeOf(context);

        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screenSize.width;

        // Match the idle screen constraint: maxWidth 500, with 24 horizontal padding
        final contentWidth = (availableWidth > 500 ? 500.0 : availableWidth) - 48.0;

        final cardHeight = (contentWidth * 0.45).clamp(170.0, 220.0);
        final titleSize = (contentWidth * 0.1).clamp(36.0, 54.0);
        final answerFontSize = (contentWidth * 0.28).clamp(96.0, 150.0);

        final formattedAnswer = answer.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );

        // On short landscape phones, fit the result and Play Again action
        // side by side rather than hiding them below a tall hero.
        if (screenSize.height < 540 &&
            screenSize.width > screenSize.height &&
            screenSize.width >= 560) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 12),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 4,
                      child: _ResultHero(),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Answer',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF6F1FF),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _AnswerCard(
                            formattedAnswer: formattedAnswer,
                            height: 130,
                            answerFontSize: 76,
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: _PrimaryGradientButton(
                              height: 50,
                              onPressed: onPlayAgain,
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

        // Empty hero area for the exact trophy asset we will add later.

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SizedBox(
              width: contentWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _ResultHero(),

                  Text(
                    'Answer',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleSize,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF6F1FF),
                      shadows: const [
                        Shadow(
                          color: Color(0x33000000),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: (contentWidth * 0.055).clamp(18.0, 30.0),
                  ),

                  _AnswerCard(
                    formattedAnswer: formattedAnswer,
                    height: cardHeight,
                    answerFontSize: answerFontSize,
                  ),

                  SizedBox(
                    height: (contentWidth * 0.08).clamp(28.0, 44.0),
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: _PrimaryGradientButton(
                      height: 56.0,
                      onPressed: onPlayAgain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


// ============================================================
// Answer Card
// ============================================================

class _AnswerCard extends StatelessWidget {
  final String formattedAnswer;
  final double height;
  final double answerFontSize;

  const _AnswerCard({
    required this.formattedAnswer,
    required this.height,
    required this.answerFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),

        // Dark purple dimensional surface like the reference.
        gradient: const RadialGradient(
          center: Alignment(0, -0.05),
          radius: 1.25,
          colors: [
            Color(0xFF24103F),
            Color(0xFF160729),
            Color(0xFF0B0214),
          ],
          stops: [0.0, 0.58, 1.0],
        ),

        border: Border.all(
          width: 1.7,
          color: const Color(0xFF8A30E5),
        ),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF762BFF).withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFA155FF).withValues(alpha: 0.10),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),

      child: Row(
        children: [
          const SizedBox(width: 30),

          const _ResultRays(),

          const SizedBox(width: 20),

          Expanded(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFF06A),
                        Color(0xFFFFC51D),
                        Color(0xFFFFA000),
                      ],
                      stops: [0.0, 0.48, 1.0],
                    ).createShader(bounds);
                  },
                  child: Text(
                    formattedAnswer,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: answerFontSize,
                      height: 0.92,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: const Color(0xFFFFB000)
                              .withValues(alpha: 0.34),
                          blurRadius: 13,
                          offset: const Offset(0, 4),
                        ),
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ),
          ),

          const SizedBox(width: 20),

          const _ResultRays(mirrored: true),

          const SizedBox(width: 30),
        ],
      ),
    );
  }
}

// ============================================================
// Result Hero
// Exact trophy + halo + decorative effects
// ============================================================

class _ResultHero extends StatelessWidget {
  const _ResultHero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        final heroSize =
            (availableWidth * 0.60).clamp(250.0, 350.0);

        return SizedBox(
          width: double.infinity,
          height: heroSize,
          child: Center(
            child: SizedBox(
              width: heroSize,
              height: heroSize,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // ============================================
                  // Purple halo
                  // ============================================
                  Positioned(
                    top: heroSize * 0.025,
                    child: Container(
                      width: heroSize * 1.02,
                      height: heroSize * 1.02,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF7A2EFF)
                                .withValues(alpha: 0.52),
                            const Color(0xFF5420B8)
                                .withValues(alpha: 0.34),
                            const Color(0xFF321264)
                                .withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                          stops: const [
                            0.0,
                            0.45,
                            0.75,
                            1.0,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ============================================
                  // Top celebration rays
                  // ============================================
                  Positioned(
                    top: heroSize * 0.05,
                    child: _CelebrationStroke(
                      length: heroSize * 0.10,
                      thickness: heroSize * 0.026,
                      color: const Color(0xFFFFC52E),
                    ),
                  ),

                  Positioned(
                    top: heroSize * 0.09,
                    left: heroSize * 0.30,
                    child: Transform.rotate(
                      angle: -0.48,
                      child: _CelebrationStroke(
                        length: heroSize * 0.095,
                        thickness: heroSize * 0.026,
                        color: const Color(0xFFFFB82A),
                      ),
                    ),
                  ),

                  Positioned(
                    top: heroSize * 0.09,
                    right: heroSize * 0.30,
                    child: Transform.rotate(
                      angle: 0.48,
                      child: _CelebrationStroke(
                        length: heroSize * 0.095,
                        thickness: heroSize * 0.026,
                        color: const Color(0xFFFFB82A),
                      ),
                    ),
                  ),

                  // ============================================
                  // Left decorations
                  // ============================================
                  Positioned(
                    top: heroSize * 0.20,
                    left: heroSize * 0.10,
                    child: _FourPointSparkle(
                      size: heroSize * 0.065,
                      color: const Color(0xFFFFD43B),
                    ),
                  ),

                  Positioned(
                    top: heroSize * 0.45,
                    left: heroSize * 0.04,
                    child: Transform.rotate(
                      angle: 1.15,
                      child: _CelebrationStroke(
                        length: heroSize * 0.085,
                        thickness: heroSize * 0.026,
                        color: const Color(0xFFFF40C8),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: heroSize * 0.22,
                    left: heroSize * 0.08,
                    child: _FourPointSparkle(
                      size: heroSize * 0.080,
                      color: const Color(0xFFFFCC32),
                    ),
                  ),

                  Positioned(
                    bottom: heroSize * 0.10,
                    left: heroSize * 0.15,
                    child: _FourPointSparkle(
                      size: heroSize * 0.050,
                      color: const Color(0xFF914AFF),
                    ),
                  ),

                  // ============================================
                  // Right decorations
                  // ============================================
                  Positioned(
                    top: heroSize * 0.18,
                    right: heroSize * 0.10,
                    child: _FourPointSparkle(
                      size: heroSize * 0.070,
                      color: const Color(0xFFFFD43B),
                    ),
                  ),

                  Positioned(
                    top: heroSize * 0.43,
                    right: heroSize * 0.04,
                    child: Transform.rotate(
                      angle: -1.05,
                      child: _CelebrationStroke(
                        length: heroSize * 0.095,
                        thickness: heroSize * 0.027,
                        color: const Color(0xFFFF46CF),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: heroSize * 0.24,
                    right: heroSize * 0.08,
                    child: _FourPointSparkle(
                      size: heroSize * 0.065,
                      color: const Color(0xFFFFD038),
                    ),
                  ),

                  Positioned(
                    bottom: heroSize * 0.11,
                    right: heroSize * 0.15,
                    child: Transform.rotate(
                      angle: -0.78,
                      child: _CelebrationStroke(
                        length: heroSize * 0.080,
                        thickness: heroSize * 0.026,
                        color: const Color(0xFFCDB7FF),
                      ),
                    ),
                  ),

                  // ============================================
                  // Trophy
                  // ============================================
                  Positioned(
                    top: heroSize * 0.15,
                    child: SizedBox(
                      width: heroSize * 0.62,
                      height: heroSize * 0.77,
                      child: const _ResultTrophy(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


// ============================================================
// Trophy
// ============================================================

class _ResultTrophy extends StatelessWidget {
  const _ResultTrophy();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 220,
        height: 250,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // --------------------------------------------------
            // Ground shadow
            // --------------------------------------------------
            Positioned(
              bottom: 8,
              child: Container(
                width: 132,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: Colors.black.withValues(alpha: 0.28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFAA00)
                          .withValues(alpha: 0.18),
                      blurRadius: 22,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ),

            // --------------------------------------------------
            // LEFT HANDLE - back layer
            // --------------------------------------------------
            Positioned(
              top: 62,
              left: 10,
              child: Container(
                width: 82,
                height: 94,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(48),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFE36A),
                      Color(0xFFFFB51E),
                      Color(0xFFFF8C00),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB000)
                          .withValues(alpha: 0.38),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 50,
                    height: 62,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      color: const Color(0xFF3B155F)
                          .withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // RIGHT HANDLE
            // --------------------------------------------------
            Positioned(
              top: 62,
              right: 10,
              child: Container(
                width: 82,
                height: 94,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(48),
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFFFFE36A),
                      Color(0xFFFFB51E),
                      Color(0xFFFF8C00),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB000)
                          .withValues(alpha: 0.38),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 50,
                    height: 62,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      color: const Color(0xFF3B155F)
                          .withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // MAIN CUP BODY
            // --------------------------------------------------
            Positioned(
              top: 52,
              child: ClipPath(
                clipper: _TrophyCupClipper(),
                child: Container(
                  width: 154,
                  height: 142,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFF7A0),
                        Color(0xFFFFDF56),
                        Color(0xFFFFBE22),
                        Color(0xFFFF9607),
                      ],
                      stops: [
                        0.00,
                        0.25,
                        0.62,
                        1.00,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB000)
                            .withValues(alpha: 0.52),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // CUP SHADOW / RIGHT DEPTH
            // --------------------------------------------------
            Positioned(
              top: 66,
              right: 47,
              child: Container(
                width: 25,
                height: 104,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFFFF9D00)
                          .withValues(alpha: 0.00),
                      const Color(0xFFEB7800)
                          .withValues(alpha: 0.42),
                    ],
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // MAIN GLOSSY HIGHLIGHT
            // --------------------------------------------------
            Positioned(
              top: 70,
              left: 67,
              child: Container(
                width: 18,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.78),
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.00),
                    ],
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // TOP RIM
            // --------------------------------------------------
            Positioned(
              top: 38,
              child: Container(
                width: 170,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFFBE),
                      Color(0xFFFFE365),
                      Color(0xFFFFB315),
                      Color(0xFFFF9200),
                    ],
                    stops: [
                      0.0,
                      0.30,
                      0.70,
                      1.0,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC52B)
                          .withValues(alpha: 0.45),
                      blurRadius: 11,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Align(
                  alignment: const Alignment(0, -0.35),
                  child: Container(
                    width: 120,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withValues(alpha: 0.34),
                    ),
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // STAR EMBLEM
            // --------------------------------------------------
            Positioned(
              top: 84,
              child: CustomPaint(
                size: const Size(68, 68),
                painter: _GlossyTrophyStarPainter(),
              ),
            ),

            // --------------------------------------------------
            // STEM
            // --------------------------------------------------
            Positioned(
              bottom: 61,
              child: Container(
                width: 44,
                height: 52,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFDE55),
                      Color(0xFFFFBA18),
                      Color(0xFFFF8B00),
                    ],
                  ),
                ),
              ),
            ),

            // stem flare
            Positioned(
              bottom: 54,
              child: Container(
                width: 76,
                height: 27,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFE66B),
                      Color(0xFFFFAA0D),
                    ],
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // UPPER BASE
            // --------------------------------------------------
            Positioned(
              bottom: 34,
              child: Container(
                width: 106,
                height: 31,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFEB7A),
                      Color(0xFFFFBD1B),
                      Color(0xFFFF9502),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFA000)
                          .withValues(alpha: 0.25),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),

            // --------------------------------------------------
            // LOWER BASE
            // --------------------------------------------------
            Positioned(
              bottom: 13,
              child: Container(
                width: 136,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFD13D),
                      Color(0xFFFFA009),
                      Color(0xFFFF8100),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 7,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// Trophy cup silhouette
// ============================================================

class _TrophyCupClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(5, 0);

    // top left
    path.quadraticBezierTo(
      2,
      size.height * 0.10,
      7,
      size.height * 0.25,
    );

    // left body taper
    path.cubicTo(
      size.width * 0.08,
      size.height * 0.58,
      size.width * 0.24,
      size.height * 0.88,
      size.width * 0.50,
      size.height,
    );

    // right mirrored curve
    path.cubicTo(
      size.width * 0.76,
      size.height * 0.88,
      size.width * 0.92,
      size.height * 0.58,
      size.width - 7,
      size.height * 0.25,
    );

    path.quadraticBezierTo(
      size.width - 2,
      size.height * 0.10,
      size.width - 5,
      0,
    );

    path.close();

    return path;
  }

  @override
  bool shouldReclip(
    covariant CustomClipper<Path> oldClipper,
  ) =>
      false;
}


// ============================================================
// Trophy star
// ============================================================

class _GlossyTrophyStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const points = 5;

    final center =
        Offset(size.width / 2, size.height / 2);

    final outerRadius = size.width * 0.44;
    final innerRadius = outerRadius * 0.45;

    final path = Path();

    for (int i = 0; i < points * 2; i++) {
      final radius =
          i.isEven ? outerRadius : innerRadius;

      final angle =
          -math.pi / 2 +
          i * math.pi / points;

      final p = Offset(
        center.dx +
            math.cos(angle) * radius,
        center.dy +
            math.sin(angle) * radius,
      );

      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    path.close();

    final rect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );

    final starPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF178),
          Color(0xFFFFC320),
          Color(0xFFFF8E00),
        ],
      ).createShader(rect);

    canvas.drawShadow(
      path,
      const Color(0xFFB15A00),
      6,
      false,
    );

    canvas.drawPath(
      path,
      starPaint,
    );

    // Small glossy upper highlight
    canvas.save();
    canvas.clipPath(path);

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.48),
          Colors.white.withValues(alpha: 0.00),
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height * 0.55,
        ),
      );

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height * 0.55,
      ),
      highlightPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) =>
      false;
}


// ============================================================
// Four-point sparkle
// ============================================================

class _FourPointSparkle extends StatelessWidget {
  final double size;
  final Color color;

  const _FourPointSparkle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _FourPointSparklePainter(color),
    );
  }
}


class _FourPointSparklePainter
    extends CustomPainter {
  final Color color;

  _FourPointSparklePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final path = Path()
      ..moveTo(cx, 0)
      ..quadraticBezierTo(
        cx + size.width * 0.09,
        cy - size.height * 0.09,
        size.width,
        cy,
      )
      ..quadraticBezierTo(
        cx + size.width * 0.09,
        cy + size.height * 0.09,
        cx,
        size.height,
      )
      ..quadraticBezierTo(
        cx - size.width * 0.09,
        cy + size.height * 0.09,
        0,
        cy,
      )
      ..quadraticBezierTo(
        cx - size.width * 0.09,
        cy - size.height * 0.09,
        cx,
        0,
      )
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawShadow(
      path,
      color.withValues(alpha: 0.35),
      6,
      false,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) =>
      false;
}


// ============================================================
// Celebration stroke
// ============================================================

class _CelebrationStroke extends StatelessWidget {
  final double length;
  final double thickness;
  final Color color;

  const _CelebrationStroke({
    required this.length,
    required this.thickness,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: thickness,
      height: length,
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            BorderRadius.circular(thickness),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 5,
          ),
        ],
      ),
    );
  }
}
// ============================================================
// Decorative Rays
// ============================================================

class _ResultRays extends StatelessWidget {
  final bool mirrored;

  const _ResultRays({
    this.mirrored = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget ray(double angle, double width) {
      final child = Transform.rotate(
        angle: angle,
        child: Container(
          width: width,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE59419),
                Color(0xFFFFC107),
              ],
            ),
          ),
        ),
      );

      return child;
    }

    final content = SizedBox(
      width: 34,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 7,
            child: ray(-0.58, 28),
          ),
          Positioned(
            top: 35,
            child: ray(0, 25),
          ),
          Positioned(
            bottom: 7,
            child: ray(0.58, 28),
          ),
        ],
      ),
    );

    if (!mirrored) return content;

    return Transform.flip(
      flipX: true,
      child: content,
    );
  }
}


// ============================================================
// Play Again Button
// ============================================================

class _PrimaryGradientButton extends StatelessWidget {
  final double height;
  final VoidCallback onPressed;

  const _PrimaryGradientButton({
    required this.height,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),

          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFB43DFF),
              Color(0xFF8530FF),
              Color(0xFF5A29FF),
            ],
          ),

          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8734FF).withValues(alpha: 0.30),
              blurRadius: 26,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),

        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(height / 2),
            onTap: onPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Play Again',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Beads Flash Visual
// Premium / accessible Soroban display
// ============================================================

class _BeadsFlashVisual extends StatelessWidget {
  final int value;
  final int columnCount;
  final bool isNegative;

  const _BeadsFlashVisual({
    required this.value,
    required this.columnCount,
    required this.isNegative,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = MediaQuery.sizeOf(context);

        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screenSize.width;

        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : screenSize.height;

        // Allow it to take up most of the screen on mobile, but stay compact on desktop
        final maxContentWidth =
            (availableWidth * 0.95).clamp(320.0, 980.0);

        final abacusHeight =
            (availableHeight * 0.62).clamp(360.0, 650.0);

        final signSize =
            (abacusHeight * 0.15).clamp(58.0, 92.0);

        return Center(
          child: SizedBox(
            width: maxContentWidth,
            height: abacusHeight,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ------------------------------------------------
                    // Operation sign (Attached to left of abacus)
                    // ------------------------------------------------
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 120),
                      opacity: isNegative ? 1 : 0,
                      child: _OperationBadge(
                        size: signSize,
                        symbol: '−',
                      ),
                    ),
                    
                    const SizedBox(width: 24),

                    // ------------------------------------------------
                    // Abacus (Fills Center)
                    // ------------------------------------------------
                    _PremiumSoroban(
                      value: value,
                      columnCount: columnCount,
                    ),

                    // ------------------------------------------------
                    // Dummy spacer to keep abacus perfectly centered
                    // ------------------------------------------------
                    SizedBox(width: signSize + 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


// ============================================================
// Operation badge
// Color is decorative; symbol conveys meaning.
// ============================================================

class _OperationBadge extends StatelessWidget {
  final double size;
  final String symbol;

  const _OperationBadge({
    required this.size,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF667F),
            Color(0xFFF02A69),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF02A69)
                .withValues(alpha: 0.28),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: symbol == '−' || symbol == '-'
            ? Container(
                width: size * 0.45,
                height: size * 0.08,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(size * 0.04),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: 4,
                    )
                  ],
                ),
              )
            : Text(
                symbol,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.58,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}


// ============================================================
// Premium Soroban
// ============================================================

class _PremiumSoroban extends StatelessWidget {
  final int value;
  final int columnCount;

  const _PremiumSoroban({
    required this.value,
    required this.columnCount,
  });

  List<int> _digits() {
    final text =
        value.toString().padLeft(columnCount, '0');

    final chars = text
        .substring(
          text.length > columnCount
              ? text.length - columnCount
              : 0,
        )
        .split('');

    return chars
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final digits = _digits();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // If wrapped in FittedBox (infinite width), base the width on column count
        // so it doesn't create huge blank margins that force it to scale down too much.
        final idealWidth = (digits.length * 110.0) + ((digits.length - 1) * 20.0);
        final safeWidth = width.isFinite ? width : idealWidth;

        final usableWidth = safeWidth.clamp(120.0, 850.0);

        final columnGap = (usableWidth * 0.045).clamp(8.0, 34.0);

        final columnWidth = (
          (usableWidth - (columnGap * (digits.length - 1))) / digits.length
        ).clamp(40.0, 150.0);

        final beadWidth = (columnWidth * 0.82).clamp(34.0, 128.0);

        final beadHeight = (beadWidth * 0.48).clamp(18.0, 62.0);

        final rodWidth =
            (columnWidth * 0.10).clamp(8.0, 14.0);

        final totalHeight =
            (beadHeight * 8.75).clamp(360.0, 610.0);

        final beamHeight =
            (beadHeight * 0.26).clamp(10.0, 17.0);

        return SizedBox(
          width: usableWidth,
          height: totalHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ----------------------------------------------
              // Soft background halo
              // ----------------------------------------------
              Container(
                width: usableWidth * 0.78,
                height: totalHeight * 0.90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF742CFF)
                          .withValues(alpha: 0.14),
                      const Color(0xFF45148A)
                          .withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // ----------------------------------------------
              // Rod columns
              // ----------------------------------------------
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  for (int i = 0;
                      i < digits.length;
                      i++) ...[
                    SizedBox(
                      width: columnWidth,
                      height: totalHeight,
                      child: _SorobanColumn(
                        digit: digits[i],
                        beadWidth: beadWidth,
                        beadHeight: beadHeight,
                        rodWidth: rodWidth,
                        totalHeight: totalHeight,
                        beamHeight: beamHeight,
                      ),
                    ),

                    if (i != digits.length - 1)
                      SizedBox(width: columnGap),
                  ],
                ],
              ),

              // ----------------------------------------------
              // Main horizontal beam
              // ----------------------------------------------
              Positioned(
                left: 0,
                right: 0,
                top: beadHeight * 2.6, // Matches topMargin (0.5) + upperRodLength (2.1)
                child: Container(
                  height: beamHeight,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(100),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFF8B55C),
                        Color(0xFFC36822),
                        Color(0xFF8C3E14),
                      ],
                      stops: [
                        0.0,
                        0.52,
                        1.0,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset:
                            const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(0xFFFFB54C)
                            .withValues(alpha: 0.15),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Align(
                    alignment:
                        const Alignment(0, -0.55),
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(99),
                        color: Colors.white
                            .withValues(alpha: 0.20),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


// ============================================================
// Single Soroban column
//
// IMPORTANT FOR COLOR-BLIND ACCESSIBILITY:
// Value is communicated by POSITION.
// Colors are decorative only.
//
// Digit rule:
// 0–4 => upper bead away from beam
// 5–9 => upper bead touches beam
//
// lower bead count touching beam = digit % 5
// ============================================================

class _SorobanColumn extends StatelessWidget {
  final int digit;
  final double beadWidth;
  final double beadHeight;
  final double rodWidth;
  final double totalHeight;
  final double beamHeight;

  const _SorobanColumn({
    required this.digit,
    required this.beadWidth,
    required this.beadHeight,
    required this.rodWidth,
    required this.totalHeight,
    required this.beamHeight,
  });

  @override
  Widget build(BuildContext context) {
    final upperActive = digit >= 5;
    final lowerActive = digit % 5;

    final beadGap = beadHeight * 0.10;
    final beadStep = beadHeight + beadGap;

    final topMargin = beadHeight * 0.5;
    
    // Beam Y is below the upper rod (holds 1 bead + 1 sliding space)
    final upperRodLength = beadHeight * 2.1;
    final beamY = topMargin + upperRodLength;

    // Upper Bead (Active = touches beam. Inactive = touches top of rod)
    final upperActiveTop = beamY - beadHeight - 2.0; 
    final upperInactiveTop = topMargin;

    // Lower Beads (Active = against beam. Inactive = against bottom of rod)
    final lowerActiveStart = beamY + beamHeight + 2.0;
    final bottomMargin = beadHeight * 0.5;
    final lowerInactiveBottomEdge = totalHeight - bottomMargin;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // ------------------------------------------------------
        // Vertical rod
        // ------------------------------------------------------
        Positioned(
          top: topMargin,
          bottom: bottomMargin,
          child: Container(
            width: rodWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFFFFD58A),
                  Color(0xFFE58B3B),
                  Color(0xFF9D4A1B),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
        ),

        // ------------------------------------------------------
        // Upper bead (worth 5)
        // Gold is decorative.
        // Position tells whether the bead is active.
        // ------------------------------------------------------
        AnimatedPositioned(
          duration:
              const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          top: upperActive
              ? upperActiveTop
              : upperInactiveTop,
          child: _GoldUpperBead(
            width: beadWidth,
            height: beadHeight,
          ),
        ),

        // ------------------------------------------------------
        // Lower beads
        // 4 beads worth 1 each.
        // Active beads move toward beam.
        // Inactive beads remain stacked at the bottom.
        // ------------------------------------------------------
        for (int i = 0; i < 4; i++)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            top: i < lowerActive
                ? lowerActiveStart + (i * beadStep) // Active stack
                : lowerInactiveBottomEdge - beadHeight - ((3 - i) * beadStep), // Inactive stack
            child: _PurpleLowerBead(
              width: beadWidth,
              height: beadHeight,
            ),
          ),
      ],
    );
  }
}


// ============================================================
// GOLD upper bead
// Faceted / glossy / distinct silhouette
// ============================================================

class _GoldUpperBead extends StatelessWidget {
  final double width;
  final double height;

  const _GoldUpperBead({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _FacetedBeadPainter(
        topColor: const Color(0xFFFFF083),
        middleColor:
            const Color(0xFFFFC627),
        bottomColor:
            const Color(0xFFFF9400),
        outlineColor:
            const Color(0xFFE28700),
        strongOutline: false,
      ),
    );
  }
}


// ============================================================
// PURPLE lower bead
//
// Position conveys value.
// Purple helps visually separate lower beads.
// ============================================================

class _PurpleLowerBead
    extends StatelessWidget {
  final double width;
  final double height;

  const _PurpleLowerBead({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _FacetedBeadPainter(
        topColor:
            const Color(0xFFD7ADFF),
        middleColor:
            const Color(0xFF9552FF),
        bottomColor:
            const Color(0xFF5423D3),
        outlineColor:
            const Color(0xFF3B168E),
        strongOutline: true,
      ),
    );
  }
}


// ============================================================
// Faceted bead painter
// ============================================================

class _FacetedBeadPainter
    extends CustomPainter {
  final Color topColor;
  final Color middleColor;
  final Color bottomColor;
  final Color outlineColor;
  final bool strongOutline;

  _FacetedBeadPainter({
    required this.topColor,
    required this.middleColor,
    required this.bottomColor,
    required this.outlineColor,
    required this.strongOutline,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.22, 0)
      ..lineTo(w * 0.78, 0)
      ..quadraticBezierTo(
        w * 0.88,
        h * 0.03,
        w,
        h * 0.44,
      )
      ..quadraticBezierTo(
        w * 0.96,
        h * 0.70,
        w * 0.77,
        h,
      )
      ..lineTo(w * 0.23, h)
      ..quadraticBezierTo(
        w * 0.04,
        h * 0.70,
        0,
        h * 0.44,
      )
      ..quadraticBezierTo(
        w * 0.12,
        h * 0.03,
        w * 0.22,
        0,
      )
      ..close();

    final rect =
        Rect.fromLTWH(0, 0, w, h);

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          topColor,
          middleColor,
          bottomColor,
        ],
        stops: const [
          0.0,
          0.48,
          1.0,
        ],
      ).createShader(rect);

    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: 0.40),
      8,
      false,
    );

    canvas.drawPath(path, fill);

    // --------------------------------------------------------
    // Top-left faceted highlight
    // --------------------------------------------------------
    final highlight = Path()
      ..moveTo(w * 0.22, h * 0.06)
      ..lineTo(w * 0.51, h * 0.06)
      ..lineTo(w * 0.39, h * 0.45)
      ..lineTo(w * 0.10, h * 0.45)
      ..close();

    final highlightPaint = Paint()
      ..color =
          Colors.white.withValues(alpha: 0.22);

    canvas.drawPath(
      highlight,
      highlightPaint,
    );

    // --------------------------------------------------------
    // Bottom facet
    // --------------------------------------------------------
    final bottomFacet = Path()
      ..moveTo(0, h * 0.50)
      ..lineTo(w, h * 0.50)
      ..lineTo(w * 0.77, h)
      ..lineTo(w * 0.23, h)
      ..close();

    final bottomPaint = Paint()
      ..color = Colors.black.withValues(
        alpha: 0.08,
      );

    canvas.drawPath(
      bottomFacet,
      bottomPaint,
    );

    // --------------------------------------------------------
    // Accessibility outline
    // --------------------------------------------------------
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          strongOutline ? 2.0 : 1.2
      ..color = outlineColor.withValues(
        alpha: strongOutline ? 0.75 : 0.35,
      );

    canvas.drawPath(
      path,
      outline,
    );
  }

  @override
  bool shouldRepaint(
    covariant _FacetedBeadPainter
        oldDelegate,
  ) {
    return oldDelegate.topColor != topColor ||
        oldDelegate.middleColor !=
            middleColor ||
        oldDelegate.bottomColor !=
            bottomColor ||
        oldDelegate.outlineColor !=
            outlineColor ||
        oldDelegate.strongOutline !=
            strongOutline;
  }
}


// ============================================================

// ============================================================
// EXACT FINAL HERO CODE
class _ReadyFinalHero extends StatelessWidget {
  final double? maxHeight;

  const _ReadyFinalHero({this.maxHeight});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final double normalHeroWidth =
            (availableWidth * 0.88).clamp(260.0, 600.0).toDouble();
        final double heroWidth = maxHeight == null
            ? normalHeroWidth
            : math.min(normalHeroWidth, maxHeight! / 0.57);

        final heroHeight = heroWidth * 0.57;

        return SizedBox(
          width: heroWidth,
          height: heroHeight,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // -----------------------------------------------
              // stronger but still soft purple ambient glow
              // -----------------------------------------------
              Positioned(
                top: heroHeight * 0.035,
                child: Container(
                  width: heroWidth * 0.86,
                  height: heroHeight * 0.84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7F39FF)
                            .withValues(alpha: 0.24),
                        const Color(0xFF5A20B5)
                            .withValues(alpha: 0.12),
                        const Color(0xFF32105F)
                            .withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [
                        0.0,
                        0.46,
                        0.72,
                        1.0,
                      ],
                    ),
                  ),
                ),
              ),

              // -----------------------------------------------
              // LEFT DECORATIONS
              // -----------------------------------------------
              Positioned(
                left: heroWidth * 0.048,
                top: heroHeight * 0.22,
                child: _FinalHeroSparkle(
                  size: heroWidth * 0.066,
                  color: const Color(0xFF00E5FF),
                ),
              ),

              Positioned(
                left: heroWidth * 0.003,
                top: heroHeight * 0.50,
                child: _FinalHeroDot(
                  size: heroWidth * 0.022,
                ),
              ),

              Positioned(
                left: heroWidth * 0.09,
                bottom: heroHeight * 0.065,
                child: _FinalHeroSparkle(
                  size: heroWidth * 0.039,
                  color: const Color(0xFFB066FF),
                ),
              ),

              // -----------------------------------------------
              // RIGHT DECORATIONS
              // -----------------------------------------------
              Positioned(
                right: heroWidth * 0.048,
                top: heroHeight * 0.30,
                child: _FinalHeroSparkle(
                  size: heroWidth * 0.072,
                  color: const Color(0xFF00E5FF),
                ),
              ),

              Positioned(
                right: heroWidth * 0.003,
                top: heroHeight * 0.56,
                child: _FinalHeroDot(
                  size: heroWidth * 0.021,
                ),
              ),

              Positioned(
                right: heroWidth * 0.105,
                top: heroHeight * 0.035,
                child: _FinalHeroDot(
                  size: heroWidth * 0.016,
                ),
              ),

              Positioned(
                right: heroWidth * 0.11,
                bottom: heroHeight * 0.055,
                child: _FinalHeroSparkle(
                  size: heroWidth * 0.034,
                  color: const Color(0xFFB066FF),
                ),
              ),

              // -----------------------------------------------
              // MAIN ABACUS — slightly larger
              // -----------------------------------------------
              Center(
                child: SizedBox(
                  width: heroWidth * 0.74,
                  height: heroHeight * 0.75,
                  child: const _FinalReadyAbacus(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


// ============================================================
// FINAL READY ABACUS
// ============================================================

class _FinalReadyAbacus extends StatelessWidget {
  const _FinalReadyAbacus();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final radius = w * 0.081;
        final frameDepth = w * 0.032;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // -----------------------------------------------
            // 3D back depth
            // -----------------------------------------------
            Positioned(
              left: w * 0.026,
              top: h * 0.030,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4A23B2),
                      Color(0xFF2E1077),
                      Color(0xFF150442),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.32),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),

            // -----------------------------------------------
            // front chunky frame
            // -----------------------------------------------
            Positioned(
              left: 0,
              top: 0,
              right: w * 0.026,
              bottom: h * 0.030,
              child: Container(
                padding: EdgeInsets.all(frameDepth),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF503598),
                      Color(0xFF381F75),
                      Color(0xFF220E50),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  border: Border.all(
                    color: const Color(0xFF8E62FF).withValues(alpha: 0.8),
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF8E62FF).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),

                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(radius * 0.68),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF13092A),
                        Color(0xFF0C051D),
                        Color(0xFF04010A),
                      ],
                      stops: [0.0, 0.48, 1.0],
                    ),
                    border: Border.all(
                      color: const Color(0xFF351A68),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 8,
                        blurStyle: BlurStyle.inner,
                      ),
                    ],
                  ),

                  child: Stack(
                    children: [
                      // ---------------------------------------
                      // top inner highlight
                      // ---------------------------------------
                      Positioned(
                        top: 4,
                        left: 12,
                        right: 12,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.25),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ---------------------------------------
                      // center beam
                      // ---------------------------------------
                      Positioned(
                        left: w * 0.040,
                        right: w * 0.040,
                        top: h * 0.365,
                        child: Container(
                          height: h * 0.082,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF503598),
                                Color(0xFF381F75),
                                Color(0xFF220E50),
                              ],
                              stops: [0.0, 0.50, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8E62FF).withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ---------------------------------------
                      // 4 columns
                      // ---------------------------------------
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.070,
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: const [
                            Expanded(child: _FinalReadyColumn()),
                            Expanded(child: _FinalReadyColumn()),
                            Expanded(child: _FinalReadyColumn()),
                            Expanded(child: _FinalReadyColumn()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


// ============================================================
// FINAL COLUMN
// ============================================================

class _FinalReadyColumn extends StatelessWidget {
  const _FinalReadyColumn();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final columnWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 46.0;

        final beadWidth =
            (columnWidth * 0.87).clamp(30.0, 44.0);

        final beadHeight =
            (beadWidth * 0.62).clamp(17.5, 26.0);

        final rodWidth =
            (columnWidth * 0.105).clamp(3.4, 5.6);

        return SizedBox(
          width: columnWidth,
          height: h,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // rod shadow
              Positioned(
                top: h * 0.025,
                bottom: h * 0.035,
                child: Container(
                  width: rodWidth + 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: Colors.black.withValues(alpha: 0.16),
                  ),
                ),
              ),

              // rod
              Positioned(
                top: h * 0.025,
                bottom: h * 0.035,
                child: Container(
                  width: rodWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF392570),
                        Color(0xFF201248),
                        Color(0xFF100729),
                      ],
                    ),
                  ),
                ),
              ),

              // upper bead
              Positioned(
                top: h * 0.068,
                child: _FinalReadyBead(
                  width: beadWidth,
                  height: beadHeight,
                ),
              ),

              // lower bead 1
              Positioned(
                top: h * 0.525,
                child: _FinalReadyBead(
                  width: beadWidth,
                  height: beadHeight,
                ),
              ),

              // lower bead 2
              Positioned(
                top: h * 0.685,
                child: _FinalReadyBead(
                  width: beadWidth,
                  height: beadHeight,
                ),
              ),

              // lower bead 3
              Positioned(
                top: h * 0.845,
                child: _FinalReadyBead(
                  width: beadWidth,
                  height: beadHeight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


// ============================================================
// FINAL ROUNDER / THICKER BEAD
// ============================================================

class _FinalReadyBead extends StatelessWidget {
  final double width;
  final double height;

  const _FinalReadyBead({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height * 0.80),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6CFFFA),
            Color(0xFF00E5FF),
            Color(0xFF00B8D4),
            Color(0xFF008BA3),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
        border: Border.all(
          width: 1.2,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
            blurRadius: 10,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Stack(
        children: [
          Positioned(
            left: width * 0.16,
            top: height * 0.10,
            child: Container(
              width: width * 0.34,
              height: height * 0.18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: Colors.white.withValues(alpha: 0.36),
              ),
            ),
          ),

          Positioned(
            left: width * 0.10,
            right: width * 0.10,
            bottom: height * 0.07,
            child: Container(
              height: height * 0.18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: const Color(0xFFB85605)
                    .withValues(alpha: 0.16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// SPARKLE
// ============================================================

class _FinalHeroSparkle extends StatelessWidget {
  final double size;
  final Color color;

  const _FinalHeroSparkle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _FinalHeroSparklePainter(color),
    );
  }
}


class _FinalHeroSparklePainter extends CustomPainter {
  final Color color;

  _FinalHeroSparklePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final path = Path()
      ..moveTo(cx, 0)
      ..quadraticBezierTo(
        cx + size.width * 0.09,
        cy - size.height * 0.09,
        size.width,
        cy,
      )
      ..quadraticBezierTo(
        cx + size.width * 0.09,
        cy + size.height * 0.09,
        cx,
        size.height,
      )
      ..quadraticBezierTo(
        cx - size.width * 0.09,
        cy + size.height * 0.09,
        0,
        cy,
      )
      ..quadraticBezierTo(
        cx - size.width * 0.09,
        cy - size.height * 0.09,
        cx,
        0,
      )
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawShadow(
      path,
      color.withValues(alpha: 0.40),
      6,
      false,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(
    covariant _FinalHeroSparklePainter oldDelegate,
  ) {
    return oldDelegate.color != color;
  }
}


// ============================================================
// PURPLE DOT
// ============================================================

class _FinalHeroDot extends StatelessWidget {
  final double size;

  const _FinalHeroDot({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF8A44FF),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A44FF)
                .withValues(alpha: 0.26),
            blurRadius: 5,
          ),
        ],
      ),
    );
  }
}