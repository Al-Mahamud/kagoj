import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kagoj/core/data/preferences.dart';
import 'package:kagoj/core/models/paper.dart';
import 'package:kagoj/core/router/app_router.dart';
import 'package:kagoj/core/theme/app_colors.dart';
import 'package:kagoj/features/listen/data/tts_service.dart';
import 'package:kagoj/features/reader/application/current_article_controller.dart';
import 'package:kagoj/features/reader/domain/article.dart';
import 'package:kagoj/features/words/data/words_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// No TTS engine exists in widget tests.
class _SilentTts extends TtsService {
  @override
  Future<void> stop() async {}

  @override
  Future<bool> isLanguageAvailable(String locale) async => true;
}

Article _article(String title) => Article(
      source: dailyStar,
      url: 'https://example.com/$title',
      title: title,
      paragraphs: const ['One sentence. Another one.'],
    );

void main() {
  late ProviderContainer container;

  Future<void> pumpShell(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
      savedWordsProvider.overrideWith((ref) async => []),
      ttsServiceProvider.overrideWithValue(_SilentTts()),
    ]);
    addTearDown(container.dispose);

    // Start on Settings: it needs no network fonts or database.
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: ThemeData(extensions: const [AppColors.light]),
        routerConfig: createRouter(initialLocation: '/settings'),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the open article stays docked across tabs until closed', (tester) async {
    await pumpShell(tester);
    expect(find.textContaining('Now reading'), findsNothing);

    container.read(currentArticleProvider.notifier).open(_article('Ferry routes'));
    await tester.pumpAndSettle();
    expect(find.text('Ferry routes'), findsOneWidget);
    expect(find.text('Now reading · The Daily Star'), findsOneWidget);

    // Switching tabs keeps it.
    await tester.tap(find.text('Words'));
    await tester.pumpAndSettle();
    expect(find.text('Ferry routes'), findsOneWidget);

    // ✕ closes it.
    await tester.tap(find.byTooltip('Close article'));
    await tester.pumpAndSettle();
    expect(find.text('Ferry routes'), findsNothing);
    expect(container.read(currentArticleProvider), isNull);
  });

  testWidgets('opening another article replaces the docked one', (tester) async {
    await pumpShell(tester);

    container.read(currentArticleProvider.notifier).open(_article('First story'));
    await tester.pumpAndSettle();
    container.read(currentArticleProvider.notifier).open(_article('Second story'));
    await tester.pumpAndSettle();

    expect(find.text('First story'), findsNothing);
    expect(find.text('Second story'), findsOneWidget);
  });
}
