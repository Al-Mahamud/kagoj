import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

final ttsServiceProvider = Provider((ref) {
  final service = TtsService();
  ref.onDispose(service.stop);
  return service;
});

/// Thin wrapper over the device TTS engine (Google TTS on most Android phones).
/// Bangla needs the bn-BD voice installed: Settings → Text-to-speech → Google.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialised = false;

  /// Android's normal speaking rate in flutter_tts.
  static const normalRate = 0.5;
  static const slowRate = 0.25;

  Future<void> _ensureInitialised() async {
    if (_initialised) return;
    // Makes speak() complete only when the utterance has finished.
    await _tts.awaitSpeakCompletion(true);
    _initialised = true;
  }

  Future<void> configure(String locale, double rate) async {
    await _ensureInitialised();
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(rate);
  }

  Future<void> speak(String text) async {
    await _ensureInitialised();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<bool> isLanguageAvailable(String locale) async =>
      await _tts.isLanguageAvailable(locale) == true;
}
