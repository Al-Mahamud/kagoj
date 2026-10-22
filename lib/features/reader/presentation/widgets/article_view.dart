import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/article.dart';

typedef WordTapCallback = void Function(String word, Sentence sentence);

/// Article body where every word is tappable and the sentence being read
/// aloud is highlighted. Wrap it in a SelectionArea for sentence selection.
class ArticleView extends StatefulWidget {
  const ArticleView({
    super.key,
    required this.article,
    required this.onWordTap,
    required this.paragraphKeys,
    this.activeSentence,
  });

  final Article article;
  final WordTapCallback onWordTap;

  /// One key per paragraph so the reader can scroll to the active sentence.
  final List<GlobalKey> paragraphKeys;

  /// Index of the sentence being read aloud, or null when not listening.
  final int? activeSentence;

  @override
  State<ArticleView> createState() => _ArticleViewState();
}

class _ArticleViewState extends State<ArticleView> {
  static final _tokenPattern = RegExp(r'\S+|\s+');
  static final _edgePunctuation =
      RegExp(r'^[^\p{L}\p{M}\p{N}]+|[^\p{L}\p{M}\p{N}]+$', unicode: true);

  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  List<InlineSpan> _sentenceSpans(Sentence sentence) {
    final spans = <InlineSpan>[];
    for (final match in _tokenPattern.allMatches('${sentence.text} ')) {
      final token = match.group(0)!;
      final word = token.replaceAll(_edgePunctuation, '');
      if (token.trim().isEmpty || word.isEmpty) {
        spans.add(TextSpan(text: token));
        continue;
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onWordTap(word, sentence);
      _recognizers.add(recognizer);
      spans.add(TextSpan(text: token, recognizer: recognizer));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final article = widget.article;
    final active = widget.activeSentence;
    final base = AppTheme.article(article.language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var p = 0; p < article.paragraphs.length; p++)
          Padding(
            key: widget.paragraphKeys[p],
            padding: const EdgeInsets.only(bottom: 14),
            child: Text.rich(
              TextSpan(
                style: base,
                children: [
                  for (final s in article.sentences.where((s) => s.paragraph == p))
                    TextSpan(
                      style: active == null
                          ? null
                          : s.index < active
                              ? TextStyle(color: context.colors.faded)
                              : s.index == active
                                  ? TextStyle(
                                      color: context.colors.ink,
                                      backgroundColor: context.colors.sentenceHighlight,
                                    )
                                  : null,
                      children: _sentenceSpans(s),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
