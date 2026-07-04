enum GameMode { audio, display, both }
enum GameSpeed { ultraFast, fast, normal, slow, ultraSlow }
enum TtsVoiceGender { female, male }
enum CharacterGender { boy, girl }

class GameSettings {
  final int digits;
  final int count;
  final GameSpeed speed;
  final GameMode mode;
  final TtsVoiceGender voiceGender;
  final CharacterGender character;

  const GameSettings({
    required this.digits,
    required this.count,
    required this.speed,
    required this.mode,
    required this.voiceGender,
    required this.character,
  });

  GameSettings copyWith({
    int? digits,
    int? count,
    GameSpeed? speed,
    GameMode? mode,
    TtsVoiceGender? voiceGender,
    CharacterGender? character,
  }) {
    return GameSettings(
      digits: digits ?? this.digits,
      count: count ?? this.count,
      speed: speed ?? this.speed,
      mode: mode ?? this.mode,
      voiceGender: voiceGender ?? this.voiceGender,
      character: character ?? this.character,
    );
  }

  static const defaultSettings = GameSettings(
    digits: 2,
    count: 5,
    speed: GameSpeed.normal,
    mode: GameMode.display,
    voiceGender: TtsVoiceGender.male,
    character: CharacterGender.boy,
  );
}
