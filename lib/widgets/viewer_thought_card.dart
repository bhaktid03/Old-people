import 'package:flutter/material.dart';
import '../app/theme/colors.dart';
import '../app/theme/spacing.dart';
import '../core/localization/l10n.dart';
import '../features/headlines/data/viewer_thought_model.dart';

class ViewerThoughtCard extends StatelessWidget {
  const ViewerThoughtCard({
    super.key,
    required this.thought,
    this.onPlay,
    this.isPlaying = false,
  });

  final ViewerThought thought;
  final VoidCallback? onPlay;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    thought.userName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
                  tooltip: 'More',
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            // Show audio/video controls if applicable
            if (thought.type == ThoughtType.audio) ...[
              _AudioRow(isPlaying: isPlaying, onPlay: onPlay),
              if (thought.text != null && thought.text!.isNotEmpty) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  thought.text!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ] else if (thought.type == ThoughtType.video) ...[
              _VideoPlayer(onPlay: onPlay),
              if (thought.text != null && thought.text!.isNotEmpty) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  thought.text!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ] else if (thought.text != null && thought.text!.isNotEmpty) ...[
              Text(
                thought.text!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: Spacing.sm),
            const Divider(height: 1),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Icon(Icons.star_border, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 6),
                Text(
                  L10n.showRespect,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const Spacer(),
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  L10n.thoughtsQ,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _AudioRow extends StatelessWidget {
  const _AudioRow({required this.isPlaying, this.onPlay});

  final bool isPlaying;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: onPlay,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.sm,
            ),
          ),
          icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
          label: Text(isPlaying ? L10n.pause : L10n.play),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoPlayer extends StatelessWidget {
  const _VideoPlayer({this.onPlay});

  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.videocam_rounded,
            size: 48,
            color: AppColors.textMuted,
          ),
          Positioned(
            bottom: Spacing.md,
            child: ElevatedButton.icon(
              onPressed: onPlay,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(L10n.play),
            ),
          ),
        ],
      ),
    );
  }
}

