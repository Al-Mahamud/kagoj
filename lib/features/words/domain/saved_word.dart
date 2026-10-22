import '../../../core/models/paper.dart';

class SavedWord {
  const SavedWord({
    this.id,
    required this.text,
    required this.meaning,
    required this.language,
    required this.sourceName,
    required this.createdAt,
    this.isSentence = false,
  });

  final int? id;
  final String text;
  final String meaning;
  final PaperLanguage language;

  /// Name of the paper it came from; kept as text so deleting a paper
  /// doesn't orphan saved words.
  final String sourceName;
  final DateTime createdAt;
  final bool isSentence;

  Map<String, Object?> toMap() => {
        'id': id,
        'text': text,
        'meaning': meaning,
        'language': language.name,
        'source': sourceName,
        'created_at': createdAt.millisecondsSinceEpoch,
        'is_sentence': isSentence ? 1 : 0,
      };

  factory SavedWord.fromMap(Map<String, Object?> map) => SavedWord(
        id: map['id'] as int,
        text: map['text'] as String,
        meaning: map['meaning'] as String,
        language: PaperLanguage.values.byName(map['language'] as String),
        sourceName: map['source'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        isSentence: map['is_sentence'] == 1,
      );
}
