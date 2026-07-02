import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_settings.dart';

class StorageService {
  static const String _keyDigits = 'settings_digits';
  static const String _keyCount = 'settings_count';
  static const String _keySpeed = 'settings_speed';
  static const String _keyMode = 'settings_mode';
  static const String _keyVoiceGender = 'settings_voice_gender';

  static const String _keyUsername = 'profile_username';
  static const String _keyAge = 'profile_age';
  static const String _keyEnrolledDate = 'profile_enrolled_date';
  static const String _keyInstalledDate = 'profile_installed_date';
  static const String _keyTotalPlayTime = 'profile_total_play_time';

  static late SharedPreferences _prefs;
  static int currentSessionSeconds = 0;
  static Timer? _sessionTimer;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Set installed date if it's the first time
    if (!_prefs.containsKey(_keyInstalledDate)) {
      final now = DateTime.now();
      await _prefs.setString(_keyInstalledDate, "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}");
    }

    _startSessionTimer();
  }

  static void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      currentSessionSeconds++;
      if (currentSessionSeconds % 10 == 0) { // Save total time every 10 seconds
        final total = loadTotalPlayTime();
        saveTotalPlayTime(total + 10);
      }
    });
  }

  static GameSettings loadSettings() {
    final digits = _prefs.getInt(_keyDigits) ?? GameSettings.defaultSettings.digits;
    final count = _prefs.getInt(_keyCount) ?? GameSettings.defaultSettings.count;
    final speedIndex = _prefs.getInt(_keySpeed) ?? GameSettings.defaultSettings.speed.index;
    final modeIndex = _prefs.getInt(_keyMode) ?? GameSettings.defaultSettings.mode.index;
    final voiceIndex = _prefs.getInt(_keyVoiceGender) ?? GameSettings.defaultSettings.voiceGender.index;

    return GameSettings(
      digits: digits,
      count: count,
      speed: GameSpeed.values[speedIndex],
      mode: GameMode.values[modeIndex],
      voiceGender: TtsVoiceGender.values[voiceIndex],
    );
  }

  static Future<void> saveSettings(GameSettings settings) async {
    await _prefs.setInt(_keyDigits, settings.digits);
    await _prefs.setInt(_keyCount, settings.count);
    await _prefs.setInt(_keySpeed, settings.speed.index);
    await _prefs.setInt(_keyMode, settings.mode.index);
    await _prefs.setInt(_keyVoiceGender, settings.voiceGender.index);
  }

  static String loadUsername() => _prefs.getString(_keyUsername) ?? "Alex";
  static Future<void> saveUsername(String name) => _prefs.setString(_keyUsername, name);

  static String loadAge() => _prefs.getString(_keyAge) ?? "25";
  static Future<void> saveAge(String age) => _prefs.setString(_keyAge, age);

  static String loadEnrolledDate() {
    final defaultDate = DateTime.now().toString().split(' ')[0];
    return _prefs.getString(_keyEnrolledDate) ?? defaultDate;
  }
  static Future<void> saveEnrolledDate(String date) => _prefs.setString(_keyEnrolledDate, date);

  static String loadInstalledDate() => _prefs.getString(_keyInstalledDate) ?? "";

  static int loadTotalPlayTime() => _prefs.getInt(_keyTotalPlayTime) ?? 0;
  static Future<void> saveTotalPlayTime(int seconds) => _prefs.setInt(_keyTotalPlayTime, seconds);
}
