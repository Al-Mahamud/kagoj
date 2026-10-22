import '../../../core/models/paper.dart';

class Sentence {
  const Sentence({
    required this.index,
    required this.paragraph,
    required this.text,
  });

  /// Position in the whole article; used by the listen controller.
  final int index;
  final int paragraph;
  final String text;
}

class Article {
  Article({
    required this.source,
    required this.url,
    required this.title,
    required this.paragraphs,
    this.byline,
  }) : sentences = _split(paragraphs);

  final Paper source;
  final String url;
  final String title;
  final String? byline;
  final List<String> paragraphs;
  final List<Sentence> sentences;

  PaperLanguage get language => source.language;

  /// Cheap identity used to tell whether the WebView now shows a different article.
  String get signature => '$url|$title|${paragraphs.length}';

  /// Splits on . ! ? and the Bangla dari (।), keeping closing quotes with the sentence.
  static final _sentencePattern =
      RegExp('[^.!?।]+(?:[.!?।]+["”’\')]*)?');

  static List<Sentence> _split(List<String> paragraphs) {
    final result = <Sentence>[];
    for (var p = 0; p < paragraphs.length; p++) {
      for (final match in _sentencePattern.allMatches(paragraphs[p])) {
        final text = match.group(0)!.trim();
        if (text.isEmpty) continue;
        result.add(Sentence(index: result.length, paragraph: p, text: text));
      }
    }
    return result;
  }
}
