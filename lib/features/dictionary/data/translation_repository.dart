import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paper.dart';

class TranslationNotConfiguredException implements Exception {
  @override
  String toString() => 'Translation service is not configured yet.';
}

/// Bangla ↔ English translation for sentences and Bangla words.
/// There is no good free Bangla dictionary API, so this needs a provider:
/// Google Cloud Translation, or an LLM (e.g. Claude) for meaning in context.
abstract class TranslationRepository {
  Future<String> translate(
    String text, {
    required PaperLanguage from,
    required PaperLanguage to,
    String? context,
  });
}

class NotConfiguredTranslationRepository implements TranslationRepository {
  @override
  Future<String> translate(
    String text, {
    required PaperLanguage from,
    required PaperLanguage to,
    String? context,
  }) =>
      Future.error(TranslationNotConfiguredException());
}

// TODO: replace with a real implementation once the provider is chosen.
final translationRepositoryProvider =
    Provider<TranslationRepository>((ref) => NotConfiguredTranslationRepository());
