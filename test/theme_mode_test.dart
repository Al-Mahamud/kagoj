import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kagoj/core/data/preferences.dart';
import 'package:kagoj/core/theme/app_colors.dart';
import 'package:kagoj/features/settings/application/theme_mode_controller.dart';
import 'package:kagoj/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('restores the saved theme on launch', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
    ]);
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('defaults to following the system', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
    ]);
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  testWidgets('choosing Dark in Settings applies and saves it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    // Plain themes carrying the palette; the real ones load Google Fonts.
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: ThemeData(extensions: const [AppColors.light]),
          darkTheme: ThemeData(
              brightness: Brightness.dark, extensions: const [AppColors.dark]),
          themeMode: ref.watch(themeModeProvider),
          home: const Scaffold(body: SettingsScreen()),
        ),
      ),
    ));

    BuildContext screen() => tester.element(find.byType(SettingsScreen));
    expect(Theme.of(screen()).brightness, Brightness.light); // test host is light

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(Theme.of(screen()).brightness, Brightness.dark);
    expect(screen().colors.background, AppColors.dark.background);
    expect(preferences.getString('theme_mode'), 'dark');
  });
}
