import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reader/domain/article.dart';
import '../data/tts_service.dart';

class ListenState {
  const ListenState({
    this.article,
    this.index = 0,
    this.playing = false,
    this.rate = TtsService.normalRate,
  });

  final Article? article;

  /// Sentence currently being read (or the one to resume from).
  final int index;
  final bool playing;
  final double rate;

  bool get started => playing || index > 0;

  ListenState copyWith({int? index, bool? playing, double? rate}) => ListenState(
        article: article,
        index: index ?? this.index,
        playing: playing ?? this.playing,
        rate: rate ?? this.rate,
      );
}

final listenControllerProvider =
    NotifierProvider<ListenController, ListenState>(ListenController.new);

/// Reads an article aloud one sentence at a time so the reader can highlight
/// and scroll to the current sentence.
class ListenController extends Notifier<ListenState> {
  /// Bumped on every pause/seek; a running read loop exits when it changes.
  int _session = 0;

  TtsService get _tts => ref.read(ttsServiceProvider);

  @override
  ListenState build() => const ListenState();

  void load(Article article) {
    if (identical(state.article, article)) return;
    _session++;
    _tts.stop();
    state = ListenState(article: article, rate: state.rate);
  }

  Future<void> play() async {
    final article = state.article;
    if (article == null || article.sentences.isEmpty) return;

    final session = ++_session;
    state = state.copyWith(playing: true);
    await _tts.configure(article.language.ttsLocale, state.rate);

    var i = state.index;
    while (i < article.sentences.length) {
      if (session != _session) return;
      state = state.copyWith(index: i);
      await _tts.speak(article.sentences[i].text);
      i++;
    }
    if (session == _session) state = state.copyWith(playing: false, index: 0);
  }

  Future<void> pause() async {
    _session++;
    state = state.copyWith(playing: false);
    await _tts.stop();
  }

  Future<void> togglePlay() => state.playing ? pause() : play();

  Future<void> seekTo(int index) async {
    final article = state.article;
    if (article == null) return;
    final wasPlaying = state.playing;
    await pause();
    state = state.copyWith(index: index.clamp(0, article.sentences.length - 1));
    if (wasPlaying) play();
  }

  Future<void> next() => seekTo(state.index + 1);

  Future<void> previous() => seekTo(state.index - 1);

  Future<void> setRate(double rate) async {
    final wasPlaying = state.playing;
    await pause();
    state = state.copyWith(rate: rate);
    if (wasPlaying) play();
  }
}
