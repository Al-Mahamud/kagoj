import 'package:flutter/material.dart';

/// Kagoj's palette. Instance colours change with light/dark mode and are read
/// through `context.colors`; the static constants are the same in both modes.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.ink,
    required this.body,
    required this.muted,
    required this.faded,
    required this.line,
    required this.background,
    required this.surface,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.emphasis,
    required this.sentenceHighlight,
  });

  /// Headings and primary text.
  final Color ink;

  /// Article body text.
  final Color body;
  final Color muted;

  /// Sentences already read aloud.
  final Color faded;
  final Color line;
  final Color background;
  final Color surface;

  /// Buttons, links, active states.
  final Color accent;

  /// Text and icons on [accent].
  final Color onAccent;
  final Color accentSoft;

  /// Translations shown under a word's meaning.
  final Color emphasis;

  /// Sentence currently being read aloud.
  final Color sentenceHighlight;

  static const light = AppColors(
    ink: Color(0xFF0B1220),
    body: Color(0xFF1F2937),
    muted: Color(0xFF5B6474),
    faded: Color(0xFF8A93A3),
    line: Color(0xFFE4E7EC),
    background: Color(0xFFF5F6F8),
    surface: Colors.white,
    accent: teal,
    onAccent: Colors.white,
    accentSoft: Color(0xFFE6F4F1),
    emphasis: navy,
    sentenceHighlight: Color(0xFFCDEBE7),
  );

  static const dark = AppColors(
    ink: Color(0xFFE6E9EE),
    body: Color(0xFFCDD3DB),
    muted: Color(0xFF9AA4B2),
    faded: Color(0xFF677184),
    line: Color(0xFF2A313C),
    background: Color(0xFF0E1218),
    surface: Color(0xFF161B23),
    accent: Color(0xFF2DD4BF),
    onAccent: Color(0xFF04201C),
    accentSoft: Color(0xFF123A36),
    emphasis: Color(0xFF9CC3F5),
    sentenceHighlight: Color(0xFF1C4A45),
  );

  // Fixed brand colours (logo, edition cards).
  static const teal = Color(0xFF0F766E);
  static const navy = Color(0xFF13233A);

  // The audio player is dark in both modes.
  static const player = Color(0xFF0B1220);
  static const playerRaised = Color(0xFF1A2333);
  static const playerLine = Color(0xFF3A4456);
  static const playerAccent = Color(0xFF2DD4BF);
  static const playerMuted = Color(0xFFA8B1C0);

  @override
  AppColors copyWith({
    Color? ink,
    Color? body,
    Color? muted,
    Color? faded,
    Color? line,
    Color? background,
    Color? surface,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? emphasis,
    Color? sentenceHighlight,
  }) =>
      AppColors(
        ink: ink ?? this.ink,
        body: body ?? this.body,
        muted: muted ?? this.muted,
        faded: faded ?? this.faded,
        line: line ?? this.line,
        background: background ?? this.background,
        surface: surface ?? this.surface,
        accent: accent ?? this.accent,
        onAccent: onAccent ?? this.onAccent,
        accentSoft: accentSoft ?? this.accentSoft,
        emphasis: emphasis ?? this.emphasis,
        sentenceHighlight: sentenceHighlight ?? this.sentenceHighlight,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      ink: Color.lerp(ink, other.ink, t)!,
      body: Color.lerp(body, other.body, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faded: Color.lerp(faded, other.faded, t)!,
      line: Color.lerp(line, other.line, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      emphasis: Color.lerp(emphasis, other.emphasis, t)!,
      sentenceHighlight: Color.lerp(sentenceHighlight, other.sentenceHighlight, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
