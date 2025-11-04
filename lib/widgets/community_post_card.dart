import 'package:flutter/material.dart';
import '../app/theme/colors.dart';
import '../app/theme/spacing.dart';
import '../core/localization/l10n.dart';

class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.userName,
    required this.text,
    this.onPlay,
    this.isPlaying = false,
  });

  final String userName;
  final String text; // empty string means voice-only
  final VoidCallback? onPlay;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 18, child: Icon(Icons.person)),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    userName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
                  tooltip: 'More',
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            _AudioRow(isPlaying: isPlaying, onPlay: onPlay),
            if (text.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Text(text, style: Theme.of(context).textTheme.bodyLarge),
            ],
            const SizedBox(height: Spacing.sm),
            const Divider(height: 1),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Icon(Icons.star_border, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(L10n.showRespect,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppColors.textSecondary)),
                const Spacer(),
                const Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(L10n.thoughtsQ,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppColors.textSecondary)),
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


