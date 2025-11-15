import 'package:flutter/material.dart';
import '../app/theme/colors.dart';
import '../app/theme/spacing.dart';
import '../core/localization/l10n.dart';

class ShareThoughtsModal extends StatelessWidget {
  const ShareThoughtsModal({super.key});

  void _handleRecordAudio(BuildContext context) {
    Navigator.of(context).pop('record_audio');
  }

  void _handleTypeText(BuildContext context) {
    Navigator.of(context).pop('type_text');
  }

  void _handleRecordVideo(BuildContext context) {
    Navigator.of(context).pop('record_video');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and close button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.lg,
                Spacing.sm,
                Spacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      L10n.shareYourVichaar,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 18,
                          ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Three action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                0,
                Spacing.lg,
                Spacing.lg,
              ),
              child: Column(
                children: [
                  _ActionButton(
                    icon: Icons.mic_rounded,
                    label: L10n.recordAudio,
                    onTap: () => _handleRecordAudio(context),
                  ),
                  const SizedBox(height: Spacing.md),
                  _ActionButton(
                    icon: Icons.keyboard_rounded,
                    label: L10n.typeText,
                    onTap: () => _handleTypeText(context),
                  ),
                  const SizedBox(height: Spacing.md),
                  _ActionButton(
                    icon: Icons.videocam_rounded,
                    label: L10n.recordVideo,
                    onTap: () => _handleRecordVideo(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F5), // Light grey background matching image
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.lg,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: Spacing.md),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to show the share thoughts modal
Future<T?> showShareThoughtsModal<T>(BuildContext context) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) => const ShareThoughtsModal(),
  );
}
