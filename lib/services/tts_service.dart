import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/game_settings.dart';

/// A robust, fire-and-forget TTS wrapper that is safe across all platforms.
/// Game logic never depends on TTS completion — errors are caught silently.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  /// Initialize TTS. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      _initialized = true;
    } catch (e) {
      debugPrint("[TtsService] init error: $e");
    }
  }

  /// Set voice based on gender setting. Fire-and-forget, never throws.
  Future<void> setupVoice(TtsVoiceGender gender) async {
    try {
      // Android / Xiaomi TTS engines often don't have predictable 'male' or 'female' voice names.
      // The most reliable cross-platform way to simulate gender is by adjusting the pitch.
      if (gender == TtsVoiceGender.female) {
        await _tts.setPitch(1.2); // Higher pitch for female
      } else {
        await _tts.setPitch(0.65); // Lower pitch for male
      }
    } catch (e) {
      debugPrint("[TtsService] setupVoice error: $e");
    }
  }

  /// Set speech rate based on game speed. Fire-and-forget.
  Future<void> setSpeechRate(GameSpeed speed) async {
    try {
      double rate = 0.5;
      switch (speed) {
        case GameSpeed.ultraFast:
          rate = 1.0;
          break;
        case GameSpeed.fast:
          rate = 0.75;
          break;
        case GameSpeed.normal:
          rate = 0.5;
          break;
        case GameSpeed.slow:
          rate = 0.4;
          break;
        case GameSpeed.ultraSlow:
          rate = 0.3;
          break;
      }
      await _tts.setSpeechRate(rate);
    } catch (e) {
      debugPrint("[TtsService] setSpeechRate error: $e");
    }
  }

  /// Speak a number. Completely fire-and-forget — game flow never blocked.
  /// Errors are silently caught. Works on Windows, Android, iOS identically.
  void speak(String text) {
    _doSpeak(text);
  }

  void _doSpeak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint("[TtsService] speak error: $e");
    }
  }

  /// Stop any ongoing speech. Fire-and-forget.
  void stop() {
    _doStop();
  }

  void _doStop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint("[TtsService] stop error: $e");
    }
  }
}
