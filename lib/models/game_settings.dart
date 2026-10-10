enum GameMode { audio, display, both }
enum GameSpeed { ultraFast, fast, normal, slow, ultraSlow }
enum TtsVoiceGender { female, male }
enum CharacterGender { boy, girl }
enum DisplayFontSize { extraSmall, small, normal, large, extraLarge }

class GameSettings {
  final int digits;
  final int count;
  final GameSpeed speed;
  final GameMode mode;
  final TtsVoiceGender voiceGender;
  final CharacterGender character;
  final DisplayFontSize fontSize;

  const GameSettings({
    required this.digits,
    required this.count,
    required this.speed,
    required this.mode,
    required this.voiceGender,
    required this.character,
    required this.fontSize,
  });

  GameSettings copyWith({
    int? digits,
    int? count,
    GameSpeed? speed,
    GameMode? mode,
    TtsVoiceGender? voiceGender,
    CharacterGender? character,
    DisplayFontSize? fontSize,
  }) {
    return GameSettings(
      digits: digits ?? this.digits,
      count: count ?? this.count,
      speed: speed ?? this.speed,
      mode: mode ?? this.mode,
      voiceGender: voiceGender ?? this.voiceGender,
      character: character ?? this.character,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  static const defaultSettings = GameSettings(
    digits: 2,
    count: 5,
    speed: GameSpeed.normal,
    mode: GameMode.display,
    voiceGender: TtsVoiceGender.male,
    character: CharacterGender.boy,
    fontSize: DisplayFontSize.normal,
  );
}
