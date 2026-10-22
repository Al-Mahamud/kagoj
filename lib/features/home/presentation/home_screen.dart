import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/paper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../papers/data/papers_repository.dart';
import '../../papers/presentation/paper_form_sheet.dart';
import 'widgets/edition_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _openForm(BuildContext context, {Paper? paper}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PaperFormSheet(paper: paper),
    );
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref, Paper paper) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(paper.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(paper.url, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;

    if (action == 'edit') {
      _openForm(context, paper: paper);
    } else if (action == 'delete') {
      await ref.read(papersRepositoryProvider).delete(paper.id);
      ref.invalidate(papersProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final papers = ref.watch(papersProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset('assets/brand/logo.png',
                    width: 40, height: 40, semanticLabel: 'Kagoj logo'),
              ),
              const SizedBox(width: 10),
              Text(
                'Kagoj',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
              const SizedBox(width: 6),
              Text(
                'কাগজ',
                style: AppTheme.article(PaperLanguage.bangla, size: 16)
                    .copyWith(color: context.colors.accent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            DateFormat('EEEE, d MMMM').format(now),
            style: theme.textTheme.labelLarge?.copyWith(color: context.colors.muted),
          ),
          Text(
            _greeting(now),
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Your papers',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          papers.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Could not load papers: $e'),
            data: (papers) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 222,
              ),
              itemCount: papers.length + 1,
              itemBuilder: (context, i) {
                if (i == papers.length) {
                  return AddPaperCard(onTap: () => _openForm(context));
                }
                final paper = papers[i];
                return EditionCard(
                  paper: paper,
                  colorIndex: i,
                  onLongPress:
                      paper.builtIn ? null : () => _showActions(context, ref, paper),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Long-press a paper you added to edit or remove it.',
            style: TextStyle(fontSize: 12, color: context.colors.muted),
          ),
          // TODO: "Continue listening" card and "Word of the day" (see design canvas).
        ],
      ),
    );
  }
}
