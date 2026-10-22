import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/paper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dictionary/data/dictionary_repository.dart';
import '../../../dictionary/data/pronunciation_service.dart';
import '../../../dictionary/data/translation_repository.dart';
import '../../../dictionary/domain/word_entry.dart';
import '../../../words/data/words_repository.dart';
import '../../../words/domain/saved_word.dart';
import '../../domain/article.dart';

class _Meaning {
  const _Meaning({
    this.entry,
    this.dictionaryError = false,
    this.translation,
    this.translationError,
  });

  final WordEntry? entry;

  /// True when no dictionary could be reached (as opposed to word not found).
  final bool dictionaryError;

  /// Bangla meaning of an English word, or English meaning of a Bangla word.
  final String? translation;
  final String? translationError;

  String get summary => [
        if (entry != null && entry!.senses.isNotEmpty) entry!.senses.first.definition,
        if (translation != null) translation!,
      ].join(' · ');
}

/// Bottom sheet shown when a word is tapped in the reader.
class MeaningSheet extends ConsumerStatefulWidget {
  const MeaningSheet({
    super.key,
    required this.word,
    required this.sentence,
    required this.article,
  });

  final String word;
  final String sentence;
  final Article article;

  @override
  ConsumerState<MeaningSheet> createState() => _MeaningSheetState();
}

class _MeaningSheetState extends ConsumerState<MeaningSheet> {
  late final Future<_Meaning> _future = _load();
  bool _saved = false;

  PaperLanguage get _language => widget.article.language;

  Future<_Meaning> _load() async {
    final translator = ref.read(translationRepositoryProvider);
    final isEnglish = _language == PaperLanguage.english;

    // A failing dictionary must not hide the translation, example sentence
    // or pronunciation, so each lookup fails on its own.
    WordEntry? entry;
    var dictionaryError = false;
    if (isEnglish) {
      try {
        entry = await ref.read(dictionaryRepositoryProvider).lookup(widget.word);
      } catch (e) {
        debugPrint('Dictionary lookup failed: $e');
        dictionaryError = true;
      }
    }

    try {
      final translation = await translator.translate(
        widget.word,
        from: _language,
        to: isEnglish ? PaperLanguage.bangla : PaperLanguage.english,
        context: widget.sentence,
      );
      return _Meaning(
          entry: entry, dictionaryError: dictionaryError, translation: translation);
    } catch (e) {
      return _Meaning(
          entry: entry, dictionaryError: dictionaryError, translationError: e.toString());
    }
  }

  void _play({String? audioUrl, bool slow = false}) {
    ref.read(pronunciationServiceProvider).play(
          widget.word,
          language: _language,
          audioUrl: audioUrl,
          slow: slow,
        );
  }

  Future<void> _save(_Meaning meaning) async {
    await ref.read(wordsRepositoryProvider).save(SavedWord(
          text: widget.word,
          meaning: meaning.summary,
          language: _language,
          sourceName: widget.article.source.name,
          createdAt: DateTime.now(),
        ));
    ref.invalidate(savedWordsProvider);
    if (mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: FutureBuilder<_Meaning>(
          future: _future,
          builder: (context, snapshot) {
            final meaning = snapshot.data;
            final entry = meaning?.entry;
            final sense = entry != null && entry.senses.isNotEmpty ? entry.senses.first : null;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Text(widget.word,
                                  style: AppTheme.article(_language, size: 28).copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: context.colors.ink,
                                    height: 1.2,
                                  )),
                              if (sense != null && sense.partOfSpeech.isNotEmpty)
                                Chip(
                                  label: Text(sense.partOfSpeech),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: context.colors.accentSoft,
                                  side: BorderSide.none,
                                  labelStyle: TextStyle(
                                      color: context.colors.accent, fontWeight: FontWeight.w700),
                                ),
                            ],
                          ),
                          if (entry?.phonetic != null)
                            Text(entry!.phonetic!,
                                style: TextStyle(color: context.colors.muted, fontSize: 14)),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _play(slow: true),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(56, 44)),
                      child: const Text('0.5×'),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Play pronunciation',
                      style: IconButton.styleFrom(
                        backgroundColor: context.colors.accent,
                        foregroundColor: context.colors.onAccent,
                        fixedSize: const Size(52, 52),
                      ),
                      onPressed: () => _play(audioUrl: entry?.audioUrl),
                      icon: const Icon(Icons.volume_up_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (snapshot.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  Text('Could not load the meaning. Check your connection.',
                      style: TextStyle(color: Theme.of(context).colorScheme.error))
                else ...[
                  if (sense != null)
                    Text(sense.definition, style: const TextStyle(fontSize: 15, height: 1.5)),
                  if (meaning?.translation != null) ...[
                    const SizedBox(height: 6),
                    Text(meaning!.translation!,
                        style: AppTheme.article(PaperLanguage.bangla, size: 17)
                            .copyWith(fontWeight: FontWeight.w600, color: context.colors.emphasis)),
                  ],
                  if (sense == null && meaning?.translation == null)
                    Text(
                      meaning?.dictionaryError == true
                          ? 'The dictionary is unreachable right now. '
                              'You can still hear the word below; try again in a moment.'
                          : _language == PaperLanguage.english
                              ? 'No dictionary entry for "${widget.word}".'
                              : meaning?.translationError ?? 'No meaning found.',
                      style: TextStyle(color: context.colors.muted),
                    ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.colors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('IN THIS ARTICLE',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: context.colors.muted)),
                        const SizedBox(height: 4),
                        Text(widget.sentence, style: AppTheme.article(_language, size: 15)),
                      ],
                    ),
                  ),
                  if (sense != null && sense.synonyms.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final s in sense.synonyms.take(4))
                          Chip(label: Text(s), visualDensity: VisualDensity.compact),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: context.colors.ink,
                      foregroundColor: context.colors.surface,
                    ),
                    onPressed: _saved || meaning == null ? null : () => _save(meaning),
                    icon: Icon(_saved ? Icons.check : Icons.bookmark_add_outlined),
                    label: Text(_saved ? 'Saved' : 'Save to My words'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
