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
      final voices = await _tts.getVoices;
      if (voices == null) return;
      for (var v in voices) {
        final name = (v['name'] as String).toLowerCase();
        if (gender == TtsVoiceGender.female) {
          if (name.contains('zira') ||
              name.contains('samantha') ||
              name.contains('female')) {
            await _tts.setVoice({"name": v["name"], "locale": v["locale"]});
            break;
          }
        } else {
          if (!name.contains('female') &&
              !name.contains('zira') &&
              !name.contains('samantha')) {
            if (name.contains('david') ||
                name.contains('alex') ||
                name.contains('male')) {
              await _tts.setVoice({"name": v["name"], "locale": v["locale"]});
              break;
            }
          }
        }
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
