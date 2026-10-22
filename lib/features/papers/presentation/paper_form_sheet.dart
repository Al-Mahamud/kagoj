import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paper.dart';
import '../../../core/theme/app_colors.dart';
import '../data/papers_repository.dart';

/// Add a paper by link, or edit one the user added earlier.
class PaperFormSheet extends ConsumerStatefulWidget {
  const PaperFormSheet({super.key, this.paper});

  /// Null when adding a new paper.
  final Paper? paper;

  @override
  ConsumerState<PaperFormSheet> createState() => _PaperFormSheetState();
}

class _PaperFormSheetState extends ConsumerState<PaperFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _url = TextEditingController(text: widget.paper?.url);
  late final _name = TextEditingController(text: widget.paper?.name);
  late PaperLanguage _language = widget.paper?.language ?? PaperLanguage.english;
  bool _saving = false;

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    super.dispose();
  }

  /// Accepts "epaper.example.com" as well as full links.
  static Uri? _parseLink(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
    if (uri == null ||
        !(uri.scheme == 'https' || uri.scheme == 'http') ||
        !uri.host.contains('.')) {
      return null;
    }
    return uri;
  }

  /// "https://epaper.example.com/x" → "example.com".
  static String _nameFromHost(String host) =>
      host.replaceFirst(RegExp(r'^(www|epaper|e-paper)\.'), '');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uri = _parseLink(_url.text)!;
    final name = _name.text.trim().isEmpty ? _nameFromHost(uri.host) : _name.text.trim();

    final paper = widget.paper?.copyWith(
          name: name,
          url: uri.toString(),
          language: _language,
        ) ??
        Paper(
          id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          url: uri.toString(),
          language: _language,
        );

    setState(() => _saving = true);
    await ref.read(papersRepositoryProvider).save(paper);
    ref.invalidate(papersProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.paper != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  editing ? 'Edit paper' : 'Add a paper',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Paste the ePaper link. It is saved on this phone.',
                  style: TextStyle(color: context.colors.muted),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _url,
                  autofocus: !editing,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Link',
                    hintText: 'https://epaper.example.com',
                    prefixIcon: Icon(Icons.link),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      _parseLink(v ?? '') == null ? 'Enter a valid web link' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name (optional)',
                    hintText: 'e.g. Bangladesh Pratidin',
                    prefixIcon: Icon(Icons.newspaper),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Language',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Used for the read-aloud voice and meanings.',
                  style: TextStyle(fontSize: 12, color: context.colors.muted),
                ),
                const SizedBox(height: 8),
                SegmentedButton<PaperLanguage>(
                  segments: [
                    for (final language in PaperLanguage.values)
                      ButtonSegment(value: language, label: Text(language.label)),
                  ],
                  selected: {_language},
                  onSelectionChanged: (s) => setState(() => _language = s.first),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: context.colors.accent,
                    foregroundColor: context.colors.onAccent,
                  ),
                  onPressed: _saving ? null : _save,
                  child: Text(editing ? 'Save changes' : 'Save paper'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
