import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../dictionary/data/pronunciation_service.dart';
import '../data/words_repository.dart';
import '../domain/saved_word.dart';

enum _Filter { all, english, bangla, sentences }

class WordsScreen extends ConsumerStatefulWidget {
  const WordsScreen({super.key});

  @override
  ConsumerState<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends ConsumerState<WordsScreen> {
  _Filter _filter = _Filter.all;
  String _query = '';

  bool _matches(SavedWord w) {
    final passesFilter = switch (_filter) {
      _Filter.all => true,
      _Filter.english => !w.isSentence && w.language == PaperLanguage.english,
      _Filter.bangla => !w.isSentence && w.language == PaperLanguage.bangla,
      _Filter.sentences => w.isSentence,
    };
    final q = _query.toLowerCase();
    return passesFilter &&
        (q.isEmpty ||
            w.text.toLowerCase().contains(q) ||
            w.meaning.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final words = ref.watch(savedWordsProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text('My words',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search saved words',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: context.colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.colors.line),
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final (filter, label) in [
                (_Filter.all, 'All'),
                (_Filter.english, 'English'),
                (_Filter.bangla, 'বাংলা'),
                (_Filter.sentences, 'Sentences'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // TODO: "Daily review" flashcards.
          words.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Could not load saved words: $e'),
            data: (all) {
              final visible = all.where(_matches).toList();
              if (visible.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Text(
                    'Tap any word while reading and press "Save" to keep it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.muted),
                  ),
                );
              }
              return Card(
                elevation: 0,
                color: context.colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(color: context.colors.line),
                ),
                child: Column(
                  children: [
                    for (final w in visible)
                      ListTile(
                        title: Text(w.text,
                            maxLines: w.isSentence ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.article(w.language, size: 16).copyWith(
                                fontWeight: FontWeight.w800, color: context.colors.ink)),
                        subtitle: Text(
                          '${w.meaning}\n${w.sourceName}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton.filledTonal(
                          tooltip: 'Play',
                          icon: const Icon(Icons.volume_up_rounded),
                          onPressed: () => ref
                              .read(pronunciationServiceProvider)
                              .play(w.text, language: w.language),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
