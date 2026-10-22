import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/paper.dart';
import '../../../core/theme/app_colors.dart';
import '../../papers/data/papers_repository.dart';
import '../../reader/application/current_article_controller.dart';
import '../../reader/data/article_extractor.dart';
import '../../reader/domain/article.dart';

/// Resolves the paper by id, then shows its site.
class EpaperBrowserScreen extends ConsumerWidget {
  const EpaperBrowserScreen({super.key, required this.paperId});

  final String paperId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papers = ref.watch(papersProvider);

    return papers.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Could not load papers: $e'))),
      data: (papers) {
        final matches = papers.where((p) => p.id == paperId);
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('This paper was removed.')),
          );
        }
        return _EpaperBrowser(key: ValueKey(paperId), paper: matches.first);
      },
    );
  }
}

/// Shows the real ePaper site. Login cookies persist in the WebView, so the
/// user signs in once. While browsing, the page is polled for an article in
/// text view; when one is found, "Open in reader" appears.
class _EpaperBrowser extends ConsumerStatefulWidget {
  const _EpaperBrowser({super.key, required this.paper});

  final Paper paper;

  @override
  ConsumerState<_EpaperBrowser> createState() => _EpaperBrowserState();
}

class _EpaperBrowserState extends ConsumerState<_EpaperBrowser> {
  InAppWebViewController? _controller;
  Timer? _poll;
  bool _checking = false;
  double _progress = 0;
  Article? _detected;

  /// Why the current page failed to load, shown instead of a blank page.
  String? _error;

  @override
  void initState() {
    super.initState();
    // The text view usually opens without a URL change, so poll instead of
    // relying on navigation callbacks alone.
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _detect());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _detect() async {
    final controller = _controller;
    if (controller == null || _checking || _error != null) return;
    _checking = true;
    try {
      final url = (await controller.getUrl())?.toString() ?? '';
      final article = await ref
          .read(articleExtractorProvider)
          .extract(controller, widget.paper, url);
      if (!mounted || article?.signature == _detected?.signature) return;
      setState(() => _detected = article);
    } catch (e) {
      debugPrint('Article detection failed: $e');
    } finally {
      _checking = false;
    }
  }

  void _retry() {
    setState(() => _error = null);
    _controller?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final controller = _controller;
        if (controller != null && await controller.canGoBack()) {
          await controller.goBack();
        } else if (context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.paper.name),
          actions: [
            IconButton(
              tooltip: 'Reload',
              icon: const Icon(Icons.refresh),
              onPressed: _retry,
            ),
          ],
          bottom: _progress < 1
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(value: _progress, minHeight: 2),
                )
              : null,
        ),
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.paper.url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                thirdPartyCookiesEnabled: true,
                useHybridComposition: true,
              ),
              onWebViewCreated: (controller) => _controller = controller,
              onProgressChanged: (_, progress) =>
                  setState(() => _progress = progress / 100),
              onLoadStop: (_, __) => _detect(),
              onReceivedError: (_, request, error) {
                if (request.isForMainFrame != true) return;
                setState(() => _error = error.description);
              },
              // Never bypass a certificate problem; report it instead.
              onReceivedServerTrustAuthRequest: (_, challenge) async {
                setState(() => _error =
                    'The secure connection to ${challenge.protectionSpace.host} '
                    'could not be verified.');
                return ServerTrustAuthResponse(
                  action: ServerTrustAuthResponseAction.CANCEL,
                );
              },
            ),
            if (_error != null) _LoadError(message: _error!, onRetry: _retry),
          ],
        ),
        floatingActionButton: _detected == null || _error != null
            ? null
            : FloatingActionButton.extended(
                backgroundColor: context.colors.accent,
                foregroundColor: context.colors.onAccent,
                icon: const Icon(Icons.chrome_reader_mode_outlined),
                label: const Text('Open in reader'),
                onPressed: () {
                  ref.read(currentArticleProvider.notifier).open(_detected!);
                  context.push('/reader');
                },
              ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: context.colors.muted),
          const SizedBox(height: 16),
          const Text("This page didn't load",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.muted)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
