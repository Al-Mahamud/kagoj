import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../listen/application/listen_controller.dart';
import '../../application/current_article_controller.dart';

/// Docked above the bottom navigation while an article is open but the reader
/// isn't on screen. Tap to return to the reader; ✕ closes the article.
class NowReadingBar extends ConsumerWidget {
  const NowReadingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(currentArticleProvider);
    if (article == null) return const SizedBox.shrink();

    final listen = ref.watch(listenControllerProvider);
    final listening = identical(listen.article, article) && listen.started;
    final colors = context.colors;

    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: () => context.go('/reader'),
        child: Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.line))),
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  listening ? Icons.headphones_rounded : Icons.chrome_reader_mode_outlined,
                  color: colors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      listening
                          ? 'Listening · ${article.source.name}'
                          : 'Now reading · ${article.source.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: colors.accent),
                    ),
                    Text(
                      article.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              if (listening)
                IconButton(
                  tooltip: listen.playing ? 'Pause' : 'Play',
                  icon: Icon(listen.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  onPressed: ref.read(listenControllerProvider.notifier).togglePlay,
                ),
              IconButton(
                tooltip: 'Close article',
                icon: const Icon(Icons.close_rounded),
                onPressed: ref.read(currentArticleProvider.notifier).close,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
