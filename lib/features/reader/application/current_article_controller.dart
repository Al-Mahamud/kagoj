import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../listen/application/listen_controller.dart';
import '../domain/article.dart';

final currentArticleProvider =
    NotifierProvider<CurrentArticleController, Article?>(CurrentArticleController.new);

/// The article open in the reader. It outlives navigation: leaving the reader
/// (back, or another tab) keeps it, and the "Now reading" bar brings it back.
/// Only [close] or opening a different article replaces it.
class CurrentArticleController extends Notifier<Article?> {
  @override
  Article? build() => null;

  void open(Article article) => state = article;

  Future<void> close() async {
    final listen = ref.read(listenControllerProvider);
    if (listen.article != null && identical(listen.article, state)) {
      await ref.read(listenControllerProvider.notifier).pause();
    }
    state = null;
  }
}
