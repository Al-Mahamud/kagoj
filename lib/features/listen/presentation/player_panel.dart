import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/listen_controller.dart';

/// Bottom of the reader: a "Listen" button before playback starts, then the
/// dark player with progress, sentence skip and speed.
class PlayerPanel extends ConsumerWidget {
  const PlayerPanel({super.key, required this.state});

  final ListenState state;

  static const _rates = [0.35, 0.5, 0.65];
  static const _rateLabels = ['0.75×', '1.0×', '1.25×'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(listenControllerProvider.notifier);
    final total = state.article?.sentences.length ?? 0;

    if (!state.started) {
      return SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: context.colors.accent,
            foregroundColor: context.colors.onAccent,
          ),
          onPressed: controller.play,
          icon: const Icon(Icons.headphones),
          label: const Text('Listen to this article',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.player,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : (state.index + 1) / total,
                minHeight: 4,
                color: AppColors.playerAccent,
                backgroundColor: AppColors.playerLine,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Sentence ${state.index + 1} of $total',
                  style: const TextStyle(color: AppColors.playerMuted, fontSize: 12)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.playerLine),
                    minimumSize: const Size(64, 44),
                  ),
                  onPressed: () {
                    final i = _rates.indexOf(state.rate);
                    controller.setRate(_rates[(i + 1) % _rates.length]);
                  },
                  child: Text(_rates.contains(state.rate)
                      ? _rateLabels[_rates.indexOf(state.rate)]
                      : '1.0×'),
                ),
                IconButton(
                  tooltip: 'Previous sentence',
                  color: Colors.white,
                  iconSize: 28,
                  onPressed: controller.previous,
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
                IconButton.filled(
                  tooltip: state.playing ? 'Pause' : 'Play',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.playerAccent,
                    foregroundColor: AppColors.player,
                    fixedSize: const Size(68, 68),
                  ),
                  iconSize: 34,
                  onPressed: controller.togglePlay,
                  icon: Icon(state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                ),
                IconButton(
                  tooltip: 'Next sentence',
                  color: Colors.white,
                  iconSize: 28,
                  onPressed: controller.next,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
                // TODO: sleep timer.
                IconButton(
                  tooltip: 'Sleep timer',
                  color: Colors.white,
                  // The player is dark in both themes, so the theme's
                  // disabled colour would be invisible in light mode.
                  disabledColor: AppColors.playerMuted.withValues(alpha: 0.6),
                  onPressed: null,
                  icon: const Icon(Icons.bedtime_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
