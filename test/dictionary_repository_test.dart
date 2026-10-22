import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kagoj/features/dictionary/data/dictionary_repository.dart';

/// Answers each request by host, without touching the network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responses);

  final Map<String, (int, String)> responses;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final (status, body) = responses[options.uri.host]!;
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

DictionaryRepository _repository(Map<String, (int, String)> responses) =>
    DictionaryRepository(Dio()..httpClientAdapter = _FakeAdapter(responses));

const _datamuseCongestion = [
  {
    'word': 'congestion',
    'tags': ['n', 'ipa_pron:kʌndʒˈɛstʃʌn'],
    'defs': [
      'n\tAn excess of traffic.',
      'n\tA second noun sense.',
    ],
  },
];

void main() {
  test('falls back to Datamuse when dictionaryapi.dev is down', () async {
    final repo = _repository({
      'api.dictionaryapi.dev': (530, 'error code: 1033'),
      'api.datamuse.com': (200, jsonEncode(_datamuseCongestion)),
    });

    final entry = await repo.lookup('Congestion');

    expect(entry, isNotNull);
    expect(entry!.word, 'congestion');
    expect(entry.phonetic, '/kʌndʒˈɛstʃʌn/');
    expect(entry.senses.single.partOfSpeech, 'noun');
    expect(entry.senses.single.definition, 'An excess of traffic.');
  });

  test('ignores Datamuse spelling suggestions for unknown words', () async {
    final repo = _repository({
      'api.dictionaryapi.dev': (404, '{"title":"No Definitions Found"}'),
      'api.datamuse.com': (200, jsonEncode([{'word': 'congestion', 'defs': ['n\tx']}])),
    });

    expect(await repo.lookup('congestoin'), isNull);
  });

  test('throws when both dictionaries are unreachable', () async {
    final repo = _repository({
      'api.dictionaryapi.dev': (530, 'error code: 1033'),
      'api.datamuse.com': (503, 'unavailable'),
    });

    expect(repo.lookup('congestion'), throwsA(isA<DioException>()));
  });
}
