import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paper.dart';
import '../domain/article.dart';

final articleExtractorProvider = Provider((ref) => ArticleExtractor());

/// Pulls the visible text-view article out of an ePaper page.
class ArticleExtractor {
  String? _script;

  Future<String> _loadScript() async =>
      _script ??= await rootBundle.loadString('assets/js/extract_article.js');

  Future<Article?> extract(
    InAppWebViewController controller,
    Paper source,
    String url,
  ) async {
    final script = await _loadScript();
    final config = jsonEncode(source.selectors.toJson());
    final raw = await controller.evaluateJavascript(
      source: 'window.__kagojSelectors = $config;\n$script',
    );
    if (raw is! String) return null;

    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>) return null;

    final paragraphs = (data['paragraphs'] as List).cast<String>();
    if (paragraphs.isEmpty) return null;

    return Article(
      source: source,
      url: url,
      title: data['title'] as String,
      byline: data['byline'] as String?,
      paragraphs: paragraphs,
    );
  }
}
