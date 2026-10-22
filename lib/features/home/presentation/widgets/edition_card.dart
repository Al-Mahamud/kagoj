import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/paper.dart';
import '../../../../core/theme/app_colors.dart';

/// Card colours for papers that don't set their own.
const _palette = [
  Color(0xFF13233A),
  Color(0xFF0F766E),
  Color(0xFF7C2D12),
  Color(0xFF3730A3),
  Color(0xFF831843),
  Color(0xFF334155),
];

class EditionCard extends StatelessWidget {
  const EditionCard({
    super.key,
    required this.paper,
    required this.colorIndex,
    this.onLongPress,
  });

  final Paper paper;
  final int colorIndex;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = paper.colorValue != null
        ? Color(paper.colorValue!)
        : _palette[colorIndex % _palette.length];
    final host = Uri.tryParse(paper.url)?.host ?? '';

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/paper/${paper.id}'),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageThumbnail(ink: color),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  paper.language.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                paper.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                host,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddPaperCard extends StatelessWidget {
  const AddPaperCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: context.colors.line, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: context.colors.accentSoft,
              foregroundColor: context.colors.accent,
              child: Icon(Icons.add_link, size: 26),
            ),
            SizedBox(height: 12),
            Text('Add paper', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('from a link', style: TextStyle(fontSize: 12, color: context.colors.muted)),
          ],
        ),
      ),
    );
  }
}

/// Stylised front page used until real page thumbnails are fetched.
class _PageThumbnail extends StatelessWidget {
  const _PageThumbnail({required this.ink});

  final Color ink;

  @override
  Widget build(BuildContext context) {
    Widget bar(double widthFactor) => FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: 4,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFC9CDD4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );

    return Container(
      height: 112,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          FractionallySizedBox(
            widthFactor: 0.7,
            child: Container(height: 10, color: ink),
          ),
          const Divider(height: 12, color: Color(0xFFC9CDD4)),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6DAE0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [bar(1), bar(1), bar(0.7), bar(1)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
