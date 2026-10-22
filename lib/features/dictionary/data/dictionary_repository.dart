import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/word_entry.dart';

final dioProvider = Provider((ref) => Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 8),
    )));

final dictionaryRepositoryProvider =
    Provider((ref) => DictionaryRepository(ref.watch(dioProvider)));

/// English dictionary. Tries https://dictionaryapi.dev first (it has recorded
/// pronunciations), then falls back to https://www.datamuse.com/api/ when that
/// service is down or doesn't know the word. Both are free and need no key.
class DictionaryRepository {
  DictionaryRepository(this._dio);

  final Dio _dio;

  /// Returns null when neither dictionary knows the word; throws only when
  /// both dictionaries are unreachable.
  Future<WordEntry?> lookup(String word) async {
    final query = word.toLowerCase();
    Object? primaryError;

    try {
      final entry = await _lookupFreeDictionary(query);
      if (entry != null) return entry;
    } catch (e) {
      primaryError = e;
    }

    try {
      return await _lookupDatamuse(query);
    } catch (_) {
      if (primaryError != null) throw primaryError;
      rethrow;
    }
  }

  Future<WordEntry?> _lookupFreeDictionary(String word) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        'https://api.dictionaryapi.dev/api/v2/entries/en/${Uri.encodeComponent(word)}',
      );
      final data = response.data;
      if (data == null || data.isEmpty) return null;
      return _parseFreeDictionary(data.first as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  WordEntry _parseFreeDictionary(Map<String, dynamic> json) {
    final phonetics = (json['phonetics'] as List? ?? const [])
        .cast<Map<String, dynamic>>();

    String? audioUrl;
    String? phonetic = json['phonetic'] as String?;
    for (final p in phonetics) {
      final audio = p['audio'] as String?;
      if (audioUrl == null && audio != null && audio.isNotEmpty) audioUrl = audio;
      phonetic ??= p['text'] as String?;
    }

    final senses = <WordSense>[];
    for (final m in (json['meanings'] as List? ?? const [])
        .cast<Map<String, dynamic>>()) {
      final definitions =
          (m['definitions'] as List? ?? const []).cast<Map<String, dynamic>>();
      if (definitions.isEmpty) continue;
      senses.add(WordSense(
        partOfSpeech: m['partOfSpeech'] as String? ?? '',
        definition: definitions.first['definition'] as String? ?? '',
        example: definitions.first['example'] as String?,
        synonyms: (m['synonyms'] as List? ?? const []).cast<String>(),
      ));
    }

    return WordEntry(
      word: json['word'] as String,
      phonetic: phonetic,
      audioUrl: audioUrl,
      senses: senses,
    );
  }

  static const _datamusePartsOfSpeech = {
    'n': 'noun',
    'v': 'verb',
    'adj': 'adjective',
    'adv': 'adverb',
  };

  Future<WordEntry?> _lookupDatamuse(String word) async {
    final response = await _dio.get<List<dynamic>>(
      'https://api.datamuse.com/words',
      queryParameters: {'sp': word, 'md': 'dp', 'ipa': '1', 'max': '1'},
    );
    final data = response.data;
    if (data == null || data.isEmpty) return null;

    final json = data.first as Map<String, dynamic>;
    // "sp" also matches similar spellings; only accept the word itself.
    if ((json['word'] as String?)?.toLowerCase() != word) return null;

    final defs = (json['defs'] as List? ?? const []).cast<String>();
    if (defs.isEmpty) return null;

    final tags = (json['tags'] as List? ?? const []).cast<String>();
    final ipa = tags
        .where((t) => t.startsWith('ipa_pron:'))
        .map((t) => t.substring('ipa_pron:'.length).trim())
        .firstOrNull;

    // Each def is "<pos>\t<definition>"; keep the first one per part of speech.
    final senses = <String, WordSense>{};
    for (final def in defs) {
      final tab = def.indexOf('\t');
      if (tab < 0) continue;
      final pos = _datamusePartsOfSpeech[def.substring(0, tab)] ?? '';
      senses.putIfAbsent(
        pos,
        () => WordSense(partOfSpeech: pos, definition: def.substring(tab + 1).trim()),
      );
    }

    return WordEntry(
      word: json['word'] as String,
      phonetic: ipa == null || ipa.isEmpty ? null : '/$ipa/',
      senses: senses.values.toList(),
    );
  }
}
