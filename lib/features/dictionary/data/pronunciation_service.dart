import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/models/paper.dart';
import '../../listen/application/listen_controller.dart';
import '../../listen/data/tts_service.dart';

final pronunciationServiceProvider = Provider((ref) {
  final service = PronunciationService(ref);
  ref.onDispose(service.dispose);
  return service;
});

/// Plays a word or sentence: the dictionary's recording when there is one,
/// otherwise the device TTS voice for the language.
class PronunciationService {
  PronunciationService(this._ref);

  final Ref _ref;
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(
    String text, {
    required PaperLanguage language,
    String? audioUrl,
    bool slow = false,
  }) async {
    // Article read-aloud and pronunciation share the TTS engine.
    await _ref.read(listenControllerProvider.notifier).pause();

    if (audioUrl != null && !slow) {
      try {
        await _player.setUrl(audioUrl);
        await _player.play();
        return;
      } catch (_) {
        // Fall back to TTS below.
      }
    }

    final tts = _ref.read(ttsServiceProvider);
    await tts.configure(
      language.ttsLocale,
      slow ? TtsService.slowRate : TtsService.normalRate,
    );
    await tts.speak(text);
  }

  void dispose() => _player.dispose();
}
