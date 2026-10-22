import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/paper.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        brightness: brightness,
        primary: c.accent,
        onPrimary: c.onAccent,
        surface: c.surface,
        onSurface: c.ink,
      ),
      scaffoldBackgroundColor: c.background,
      dividerColor: c.line,
      extensions: [c],
    );

    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(
        bodyColor: c.ink,
        displayColor: c.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.accentSoft,
      ),
    );
  }

  /// Body text of an article: Newsreader for English, Hind Siliguri for Bangla.
  /// Colour is left unset so it follows the current theme.
  static TextStyle article(PaperLanguage language, {double size = 18}) {
    return language == PaperLanguage.bangla
        ? GoogleFonts.getFont('Hind Siliguri', fontSize: size, height: 1.7)
        : GoogleFonts.getFont('Newsreader', fontSize: size, height: 1.6);
  }

  static TextStyle headline(PaperLanguage language) {
    return article(language, size: 27).copyWith(
      fontWeight: FontWeight.w600,
      height: language == PaperLanguage.bangla ? 1.35 : 1.18,
    );
  }
}
