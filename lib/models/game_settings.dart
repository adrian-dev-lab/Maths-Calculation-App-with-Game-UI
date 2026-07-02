enum GameMode { audio, display, both }
enum GameSpeed { ultraFast, fast, normal, slow, ultraSlow }
enum TtsVoiceGender { female, male }

class GameSettings {
  final int digits;
  final int count;
  final GameSpeed speed;
  final GameMode mode;
  final TtsVoiceGender voiceGender;

  const GameSettings({
    required this.digits,
    required this.count,
    required this.speed,
    required this.mode,
    required this.voiceGender,
  });

  GameSettings copyWith({
    int? digits,
    int? count,
    GameSpeed? speed,
    GameMode? mode,
    TtsVoiceGender? voiceGender,
  }) {
    return GameSettings(
      digits: digits ?? this.digits,
      count: count ?? this.count,
      speed: speed ?? this.speed,
      mode: mode ?? this.mode,
      voiceGender: voiceGender ?? this.voiceGender,
    );
  }

  static const defaultSettings = GameSettings(
    digits: 2,
    count: 5,
    speed: GameSpeed.normal,
    mode: GameMode.display,
    voiceGender: TtsVoiceGender.male,
  );
}
