class WordSense {
  const WordSense({
    required this.partOfSpeech,
    required this.definition,
    this.example,
    this.synonyms = const [],
  });

  final String partOfSpeech;
  final String definition;
  final String? example;
  final List<String> synonyms;
}

class WordEntry {
  const WordEntry({
    required this.word,
    required this.senses,
    this.phonetic,
    this.audioUrl,
  });

  final String word;
  final String? phonetic;

  /// Recorded pronunciation, when the dictionary has one.
  final String? audioUrl;
  final List<WordSense> senses;
}
