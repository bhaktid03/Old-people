import 'package:flutter/material.dart';
import '../app/theme/colors.dart';
import '../app/theme/spacing.dart';
import '../core/localization/l10n.dart';

class HeadlineCard extends StatelessWidget {
  const HeadlineCard({
    super.key,
    required this.title,
    required this.summary,
    required this.source,
    this.onListen,
    this.onOpen,
    this.onTap,
  });

  final String title;
  final String summary;
  final String source;
  final VoidCallback? onListen;
  final VoidCallback? onOpen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  '[$source] ',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              summary,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onListen,
                  icon: const Icon(Icons.volume_up_rounded, size: 24),
                  label: Text(L10n.listen),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.brand,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.xl,
                      vertical: Spacing.sm,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                OutlinedButton(
                  onPressed: onOpen,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.outline, width: 1.2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.sm,
                    ),
                  ),
                  child: Text(L10n.openArticle),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}


