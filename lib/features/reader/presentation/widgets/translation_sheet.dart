import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/paper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dictionary/data/pronunciation_service.dart';
import '../../../dictionary/data/translation_repository.dart';
import '../../../words/data/words_repository.dart';
import '../../../words/domain/saved_word.dart';
import '../../domain/article.dart';

/// Bottom sheet for a selected sentence: original + translation, both playable.
class TranslationSheet extends ConsumerStatefulWidget {
  const TranslationSheet({super.key, required this.text, required this.article});

  final String text;
  final Article article;

  @override
  ConsumerState<TranslationSheet> createState() => _TranslationSheetState();
}

class _TranslationSheetState extends ConsumerState<TranslationSheet> {
  late final PaperLanguage _from = widget.article.language;
  late final PaperLanguage _to =
      _from == PaperLanguage.bangla ? PaperLanguage.english : PaperLanguage.bangla;
  late final Future<String> _future = ref
      .read(translationRepositoryProvider)
      .translate(widget.text, from: _from, to: _to);
  bool _saved = false;

  void _play(String text, PaperLanguage language) =>
      ref.read(pronunciationServiceProvider).play(text, language: language);

  Future<void> _save(String translation) async {
    await ref.read(wordsRepositoryProvider).save(SavedWord(
          text: widget.text,
          meaning: translation,
          language: _from,
          sourceName: widget.article.source.name,
          createdAt: DateTime.now(),
          isSentence: true,
        ));
    ref.invalidate(savedWordsProvider);
    if (mounted) setState(() => _saved = true);
  }

  Widget _block({
    required String label,
    required String text,
    required PaperLanguage language,
    required bool primary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: primary ? context.colors.accent : context.colors.muted,
                )),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _play(text, language),
              icon: const Icon(Icons.volume_up_rounded, size: 18),
              label: const Text('Listen'),
            ),
          ],
        ),
        Text(text, style: AppTheme.article(language, size: primary ? 19 : 17)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: FutureBuilder<String>(
          future: _future,
          builder: (context, snapshot) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TODO: "Explain" and "Word by word" tabs from the design.
                _block(
                  label: _from.label.toUpperCase(),
                  text: widget.text,
                  language: _from,
                  primary: false,
                ),
                const Divider(height: 28),
                if (snapshot.connectionState != ConnectionState.done)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError)
                  Text(snapshot.error.toString(),
                      style: TextStyle(color: context.colors.muted))
                else ...[
                  _block(
                    label: _to.label.toUpperCase(),
                    text: snapshot.data!,
                    language: _to,
                    primary: true,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: context.colors.ink,
                      foregroundColor: context.colors.surface,
                    ),
                    onPressed: _saved ? null : () => _save(snapshot.data!),
                    icon: Icon(_saved ? Icons.check : Icons.bookmark_add_outlined),
                    label: Text(_saved ? 'Saved' : 'Save sentence'),
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
