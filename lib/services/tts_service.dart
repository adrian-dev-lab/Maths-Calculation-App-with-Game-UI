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
  Future<void> _speechQueue = Future<void>.value();
  int _speechGeneration = 0;

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
      if (voices != null && voices is List) {
        String targetGender = gender == TtsVoiceGender.female ? "female" : "male";
        Map<dynamic, dynamic>? bestVoice;
        
        // First try to match by explicit gender attribute
        for (var v in voices) {
          if (v is Map) {
            final loc = v["locale"]?.toString() ?? "";
            final g = v["gender"]?.toString() ?? "";
            if (loc.startsWith("en") && g == targetGender) {
              bestVoice = v;
              break;
            }
          }
        }
        
        // Fallback: match by known voice names
        if (bestVoice == null) {
          for (var v in voices) {
            if (v is Map) {
              final loc = v["locale"]?.toString() ?? "";
              final name = v["name"]?.toString().toLowerCase() ?? "";
              if (loc.startsWith("en")) {
                if (gender == TtsVoiceGender.female && (name.contains("zira") || name.contains("samantha") || name.contains("female"))) {
                  bestVoice = v;
                  break;
                }
                if (gender == TtsVoiceGender.male && (name.contains("david") || name.contains("mark") || name.contains("alex") || name.contains("male"))) {
                  bestVoice = v;
                  break;
                }
              }
            }
          }
        }

        if (bestVoice != null) {
          await _tts.setVoice({
            "name": bestVoice["name"],
            "locale": bestVoice["locale"]
          });
          await _tts.setPitch(1.0); // Reset pitch for native voice
          return;
        }
      }

      // Final Fallback for platforms with unpredictable TTS engines (Android/Xiaomi)
      if (gender == TtsVoiceGender.female) {
        await _tts.setPitch(1.2);
      } else {
        await _tts.setPitch(0.65);
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

  /// Speak a game number with ordered speech-rate configuration.
  /// Does not block the game timer.
  void speakNumber(String text, GameSpeed speed) {
    final generation = _speechGeneration;

    _speechQueue = _speechQueue.then<void>((_) async {
      if (generation != _speechGeneration) return;

      await init();

      if (generation != _speechGeneration) return;

      await setSpeechRate(speed);

      if (generation != _speechGeneration) return;

      final result = await _tts.speak(text);

      debugPrint('[TtsService] speakNumber "$text" result=$result');
    }).catchError((Object error, StackTrace stackTrace) {
      debugPrint('[TtsService] speakNumber error: $error');
    });
  }
  /// Stop any ongoing speech. Fire-and-forget.
  void stop() {
    _speechGeneration++;
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
