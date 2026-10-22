import 'package:flutter_test/flutter_test.dart';
import 'package:kagoj/core/models/paper.dart';
import 'package:kagoj/features/reader/domain/article.dart';

void main() {
  test('splits English paragraphs into sentences', () {
    final article = Article(
      source: dailyStar,
      url: 'https://example.com',
      title: 'Title',
      paragraphs: [
        'First sentence. Second one? Third!',
        'Next paragraph "quoted." Done',
      ],
    );

    expect(article.sentences.map((s) => s.text), [
      'First sentence.',
      'Second one?',
      'Third!',
      'Next paragraph "quoted."',
      'Done',
    ]);
    expect(article.sentences.map((s) => s.paragraph), [0, 0, 0, 1, 1]);
    expect(article.sentences.map((s) => s.index), [0, 1, 2, 3, 4]);
  });

  test('splits Bangla sentences on the dari', () {
    final article = Article(
      source: prothomAlo,
      url: 'https://example.com',
      title: 'শিরোনাম',
      paragraphs: ['প্রথম বাক্য। দ্বিতীয় বাক্য।'],
    );

    expect(article.sentences.map((s) => s.text), ['প্রথম বাক্য।', 'দ্বিতীয় বাক্য।']);
  });
}
