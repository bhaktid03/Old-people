import 'package:flutter/material.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../widgets/community_post_card.dart';

class CommunityWallScreen extends StatefulWidget {
  const CommunityWallScreen({super.key});

  @override
  State<CommunityWallScreen> createState() => _CommunityWallScreenState();
}

class _CommunityWallScreenState extends State<CommunityWallScreen> {
  int _segment = 0; // 0 = trending, 1 = recent

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          L10n.communityWall,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        leading: const SizedBox(), // keep layout clean under shell
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _Segmented(
              selected: _segment,
              onChanged: (v) => setState(() => _segment = v),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          // Sample posts (fake data)
          const CommunityPostCard(
            userName: 'User name',
            text: '',
          ),
          const CommunityPostCard(
            userName: 'User name',
            text:
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus lacus id mi volutpat, rhoncus consequat ipsum gravida.',
          ),
          const CommunityPostCard(
            userName: 'User name',
            text: '',
          ),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SegmentButton(
            label: L10n.trending,
            selected: selected == 0,
            onTap: () => onChanged(0),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _SegmentButton(
            label: L10n.recent,
            selected: selected == 1,
            onTap: () => onChanged(1),
          ),
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  const BoxShadow(color: AppColors.shadow, blurRadius: 2, offset: Offset(0, 1)),
                ]
              : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}


