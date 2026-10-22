// Demo build used to take the README screenshots. It runs the real screens
// with sample data in place of the database, dictionary, translation and TTS,
// and opens the screen named in the URL:
//
//   flutter build web -t lib/demo/main_demo.dart
//   …/index.html?screen=meaning&theme=dark
//
// screen: home | meaning | translate | listen | words | settings | addpaper
// theme:  light | dark
//
// The papers and articles here are fictional sample content.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app.dart';
import '../core/data/preferences.dart';
import '../core/models/paper.dart';
import '../core/router/app_router.dart';
import '../features/dictionary/data/dictionary_repository.dart';
import '../features/dictionary/data/translation_repository.dart';
import '../features/dictionary/domain/word_entry.dart';
import '../features/listen/application/listen_controller.dart';
import '../features/listen/data/tts_service.dart';
import '../features/papers/data/papers_repository.dart';
import '../features/papers/presentation/paper_form_sheet.dart';
import '../features/reader/domain/article.dart';
import '../features/reader/presentation/widgets/meaning_sheet.dart';
import '../features/reader/presentation/widgets/translation_sheet.dart';
import '../features/words/data/words_repository.dart';
import '../features/words/domain/saved_word.dart';

const _englishPaper = Paper(
  id: 'demo-ledger',
  name: 'The Morning Ledger',
  url: 'https://epaper.example.com/',
  language: PaperLanguage.english,
);

const _banglaPaper = Paper(
  id: 'demo-nobodhara',
  name: 'Dainik Nobodhara',
  url: 'https://epaper.example.org/',
  language: PaperLanguage.bangla,
);

final _englishArticle = Article(
  source: _englishPaper,
  url: 'https://epaper.example.com/city/ferry',
  title: 'City adds new river ferry routes to ease weekday traffic',
  byline: 'Staff Correspondent · 4 min read',
  paragraphs: const [
    'Three new ferry routes will begin operating next month in a bid to reduce '
        'road congestion during peak hours, officials said yesterday.',
    'Commuters on the eastern corridor currently spend up to two hours on the '
        'road each morning. Planners expect the river service to cut that time '
        'by nearly half.',
    'The new boats will run every twenty minutes from early morning until late '
        'evening, with fares set close to bus tickets. Each terminal will also '
        'get covered waiting areas.',
    'Residents welcomed the plan but asked for safe walkways to the jetties and '
        'clear timetables at every stop.',
  ],
);

final _banglaArticle = Article(
  source: _banglaPaper,
  url: 'https://epaper.example.org/city/ferry',
  title: 'নদীপথে নতুন ফেরি চালু, কমবে সড়কের চাপ',
  byline: 'নিজস্ব প্রতিবেদক',
  paragraphs: const [
    'শহরের যানজট কমাতে আগামী মাস থেকে তিনটি নতুন নৌপথে ফেরি চলাচল শুরু হচ্ছে। '
        'কর্তৃপক্ষ বলছে, এতে প্রতিদিন হাজারো যাত্রীর সময় বাঁচবে।',
    'প্রতিটি ঘাটে যাত্রীদের জন্য ছাউনি ও বসার জায়গা তৈরি করা হবে।',
  ],
);

const _translations = {
  'কর্তৃপক্ষ বলছে, এতে প্রতিদিন হাজারো যাত্রীর সময় বাঁচবে।':
      'Authorities say this will save time for thousands of passengers every day.',
  'congestion': 'যানজট · ভিড়',
};

final _dictionary = {
  'congestion': const WordEntry(
    word: 'congestion',
    phonetic: '/kənˈdʒes.tʃən/',
    senses: [
      WordSense(
        partOfSpeech: 'noun',
        definition: 'A situation where a place is too crowded, especially with '
            'traffic, so movement becomes slow.',
        synonyms: ['traffic jam', 'overcrowding', 'gridlock'],
      ),
    ],
  ),
};

final _savedWords = [
  ('congestion', 'Overcrowding, especially traffic · যানজট', PaperLanguage.english, false),
  ('কর্তৃপক্ষ', 'authorities; the people in charge', PaperLanguage.bangla, false),
  ('resilient', 'Able to recover quickly · সহনশীল', PaperLanguage.english, false),
  ('corridor', 'A long route or passage · করিডোর', PaperLanguage.english, false),
  ('যাত্রী', 'passenger; traveller', PaperLanguage.bangla, false),
  (
    'প্রতিটি ঘাটে যাত্রীদের জন্য ছাউনি ও বসার জায়গা তৈরি করা হবে।',
    'Every jetty will get shelter and seating for passengers.',
    PaperLanguage.bangla,
    true,
  ),
];

class _DemoDictionary extends DictionaryRepository {
  _DemoDictionary() : super(Dio());

  @override
  Future<WordEntry?> lookup(String word) async => _dictionary[word.toLowerCase()];
}

class _DemoTranslation implements TranslationRepository {
  @override
  Future<String> translate(String text,
          {required PaperLanguage from, required PaperLanguage to, String? context}) async =>
      _translations[text] ?? _translations[text.toLowerCase()] ?? text;
}

/// Silent TTS that reports both voices as installed.
class _DemoTts extends TtsService {
  @override
  Future<void> configure(String locale, double rate) async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<bool> isLanguageAvailable(String locale) async => true;
}

/// Frozen mid-article: reading the fourth sentence.
class _DemoListenController extends ListenController {
  @override
  ListenState build() => ListenState(article: _englishArticle, index: 3, playing: true);

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final params = Uri.base.queryParameters;
  final screen = params['screen'] ?? 'home';

  final preferences = await SharedPreferences.getInstance();
  await preferences.setString('theme_mode', params['theme'] ?? 'light');

  final router = switch (screen) {
    'meaning' || 'listen' => createRouter(initialLocation: '/reader', initialExtra: _englishArticle),
    'translate' => createRouter(initialLocation: '/reader', initialExtra: _banglaArticle),
    'words' => createRouter(initialLocation: '/words'),
    'settings' => createRouter(initialLocation: '/settings'),
    _ => createRouter(),
  };

  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      papersProvider.overrideWith((ref) async => [...builtInPapers, _englishPaper, _banglaPaper]),
      savedWordsProvider.overrideWith((ref) async => [
            for (final (i, (text, meaning, language, isSentence)) in _savedWords.indexed)
              SavedWord(
                id: i,
                text: text,
                meaning: meaning,
                language: language,
                sourceName: language == PaperLanguage.english
                    ? _englishPaper.name
                    : _banglaPaper.name,
                createdAt: DateTime(2026, 10, 22),
                isSentence: isSentence,
              ),
          ]),
      dictionaryRepositoryProvider.overrideWithValue(_DemoDictionary()),
      translationRepositoryProvider.overrideWithValue(_DemoTranslation()),
      ttsServiceProvider.overrideWithValue(_DemoTts()),
      if (screen == 'listen') listenControllerProvider.overrideWith(_DemoListenController.new),
    ],
    child: KagojApp(
      router: router,
      builder: (context, child) =>
          _PhoneInsets(child: _DemoSheet(screen: screen, router: router, child: child!)),
    ),
  ));
}

/// Gives SafeArea a phone's top and bottom insets without drawing a fake status bar.
class _PhoneInsets extends StatelessWidget {
  const _PhoneInsets({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    const insets = EdgeInsets.only(top: 28, bottom: 12);
    return MediaQuery(
      data: media.copyWith(padding: insets, viewPadding: insets),
      child: child,
    );
  }
}

/// Opens the bottom sheet a screenshot needs once the screen has rendered.
class _DemoSheet extends StatefulWidget {
  const _DemoSheet({required this.screen, required this.router, required this.child});

  final String screen;
  final dynamic router;
  final Widget child;

  @override
  State<_DemoSheet> createState() => _DemoSheetState();
}

class _DemoSheetState extends State<_DemoSheet> {
  @override
  void initState() {
    super.initState();
    final sheet = switch (widget.screen) {
      'meaning' => MeaningSheet(
          word: 'congestion',
          sentence: _englishArticle.sentences.first.text,
          article: _englishArticle,
        ),
      'translate' => TranslationSheet(
          text: _banglaArticle.sentences[1].text,
          article: _banglaArticle,
        ),
      'addpaper' => const PaperFormSheet(),
      _ => null,
    };
    if (sheet == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final context = widget.router.routerDelegate.navigatorKey.currentContext as BuildContext?;
      if (context == null || !context.mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => sheet,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
