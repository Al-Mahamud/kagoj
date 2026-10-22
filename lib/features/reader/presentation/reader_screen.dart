import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../listen/application/listen_controller.dart';
import '../../listen/presentation/player_panel.dart';
import '../application/current_article_controller.dart';
import '../domain/article.dart';
import 'widgets/article_view.dart';
import 'widgets/meaning_sheet.dart';
import 'widgets/translation_sheet.dart';

/// The /reader route: shows whatever article is currently open.
class ReaderRoute extends ConsumerWidget {
  const ReaderRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(currentArticleProvider);
    if (article == null) return const Scaffold();
    // A new article gets a fresh reader (scroll position, paragraph keys).
    return ReaderScreen(key: ValueKey(article.signature), article: article);
  }
}

/// Kagoj's own reader for an article extracted from the ePaper text view.
/// Tap a word → meaning; select text → "Translate"; Listen → read aloud.
/// Back keeps the article open (see the "Now reading" bar); ✕ closes it.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.article});

  final Article article;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final List<GlobalKey> _paragraphKeys =
      List.generate(widget.article.paragraphs.length, (_) => GlobalKey());
  String _selection = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(listenControllerProvider.notifier).load(widget.article),
    );
  }

  void _scrollToSentence(int index) {
    final sentences = widget.article.sentences;
    if (index >= sentences.length) return;
    final context = _paragraphKeys[sentences[index].paragraph].currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.2,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _showMeaning(String word, Sentence sentence) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MeaningSheet(
        word: word,
        sentence: sentence.text,
        article: widget.article,
      ),
    );
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
    ref.read(currentArticleProvider.notifier).close();
  }

  void _showTranslation(String text) {
    if (text.trim().isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TranslationSheet(text: text.trim(), article: widget.article),
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final listen = ref.watch(listenControllerProvider);
    final isThisArticle = identical(listen.article, article);

    ref.listen(listenControllerProvider, (previous, next) {
      if (next.playing && next.index != previous?.index) {
        _scrollToSentence(next.index);
      }
    });

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(article.source.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            Text('Text view',
                style: TextStyle(fontSize: 12, color: context.colors.muted)),
          ],
        ),
        // TODO: text size / theme (Aa) and bookmark actions.
        actions: [
          IconButton(
            tooltip: 'Close article',
            icon: const Icon(Icons.close_rounded),
            onPressed: _close,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SelectionArea(
        onSelectionChanged: (content) => _selection = content?.plainText ?? '',
        contextMenuBuilder: (context, region) =>
            AdaptiveTextSelectionToolbar.buttonItems(
          anchors: region.contextMenuAnchors,
          buttonItems: [
            ContextMenuButtonItem(
              label: 'Translate',
              onPressed: () {
                region.hideToolbar();
                _showTranslation(_selection);
              },
            ),
            ...region.contextMenuButtonItems,
          ],
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text(article.title, style: AppTheme.headline(article.language)),
            if (article.byline != null) ...[
              const SizedBox(height: 8),
              Text(article.byline!,
                  style: TextStyle(fontSize: 12, color: context.colors.muted)),
            ],
            const SizedBox(height: 16),
            ArticleView(
              article: article,
              paragraphKeys: _paragraphKeys,
              activeSentence: isThisArticle && listen.started ? listen.index : null,
              onWordTap: _showMeaning,
            ),
          ],
        ),
      ),
      bottomNavigationBar: isThisArticle ? PlayerPanel(state: listen) : null,
    );
  }
}
