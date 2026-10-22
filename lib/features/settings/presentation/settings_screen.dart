import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paper.dart';
import '../../../core/theme/app_colors.dart';
import '../../listen/data/tts_service.dart';
import '../application/theme_mode_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(ttsServiceProvider);
    final themeMode = ref.watch(themeModeProvider);
    final colors = context.colors;

    Widget sectionLabel(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colors.muted)),
        );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text('Settings',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          sectionLabel('APPEARANCE'),
          const Text('Theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            themeMode == ThemeMode.system
                ? 'Follows your phone\'s light or dark setting.'
                : 'Always ${themeMode.name}, whatever the phone is set to.',
            style: TextStyle(fontSize: 13, color: colors.muted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {themeMode},
              showSelectedIcon: false,
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).set(s.first),
            ),
          ),
          const SizedBox(height: 32),
          sectionLabel('VOICES'),
          for (final language in PaperLanguage.values)
            FutureBuilder<bool>(
              future: tts.isLanguageAvailable(language.ttsLocale),
              builder: (context, snapshot) {
                final available = snapshot.data;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${language.label} voice'),
                  subtitle: Text(available == false
                      ? 'Not installed — Android Settings → Text-to-speech → Google → Install voice data'
                      : language.ttsLocale),
                  trailing: available == null
                      ? null
                      : Icon(
                          available ? Icons.check_circle : Icons.error_outline,
                          color: available ? colors.accent : Colors.orange,
                        ),
                );
              },
            ),
          // TODO: reader text size, offline downloads.
        ],
      ),
    );
  }
}
