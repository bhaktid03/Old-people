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
  final List<_Post> _posts = [
    _Post(
      userName: 'Asha',
      text: 'Morning walk was refreshing! 🌄 Stay active everyone.',
      imageUrls: [
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
        'https://images.unsplash.com/photo-1441974231531-c6227db76b6e',
      ],
      likes: 12,
      comments: 4,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    _Post(
      userName: 'Ramesh',
      text: 'Sharing my favorite old song as a video memory 💿',
      videoThumbnailUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4',
      likes: 23,
      comments: 7,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    _Post(
      userName: 'Meera',
      text: 'Any tips for growing tulsi at home? 🌱',
      likes: 8,
      comments: 12,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {});
  }

  void _openComposer() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _ComposerSheet(
          onSubmit: (text, images, videoThumb) {
            Navigator.of(context).pop();
            setState(() {
              _posts.insert(
                0,
                _Post(
                  userName: 'You',
                  text: text,
                  imageUrls: images,
                  videoThumbnailUrl: videoThumb,
                  likes: 0,
                  comments: 0,
                  createdAt: DateTime.now(),
                ),
              );
              _segment = 1; // switch to recent to show the new post
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_Post> visiblePosts = List<_Post>.from(_posts)
      ..sort((a, b) => _segment == 0
          ? (b.score).compareTo(a.score) // trending by score
          : b.createdAt.compareTo(a.createdAt)); // recent by time

    return Scaffold(
      appBar: AppBar(
        title: Text(
          L10n.communityWall,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        leading: const SizedBox(), // keep layout clean under shell
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openComposer,
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit),
        label: Text(L10n.shareYourThoughts),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _Segmented(
                    selected: _segment,
                    onChanged: (v) => setState(() => _segment = v),
                  ),
                  const SizedBox(height: Spacing.sm),
                  _InlineComposer(onTap: _openComposer),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
            for (final p in visiblePosts)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: CommunityPostCard(
                  userName: p.userName,
                  text: p.text,
                  imageUrls: p.imageUrls,
                  videoThumbnailUrl: p.videoThumbnailUrl,
                  likes: p.likes,
                  comments: p.comments,
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
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

class _InlineComposer extends StatelessWidget {
  const _InlineComposer({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          L10n.whatsOnYourMind,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _ComposerSheet extends StatefulWidget {
  const _ComposerSheet({required this.onSubmit});

  final void Function(String text, List<String> imageUrls, String? videoThumb) onSubmit;

  @override
  State<_ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends State<_ComposerSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _images = <String>[];
  String? _videoThumb;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(L10n.shareYourVichaar, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: _controller,
                maxLines: null,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: L10n.tellUsPlaceholder,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_images.isNotEmpty || _videoThumb != null) ...[
                const SizedBox(height: Spacing.md),
                _PreviewMedia(images: _images, videoThumb: _videoThumb),
              ],
              const SizedBox(height: Spacing.md),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ChipButton(
                    icon: Icons.photo_outlined,
                    label: 'Photo',
                    onTap: () {
                      setState(() {
                        _images.add('https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e');
                      });
                    },
                  ),
                  _ChipButton(
                    icon: Icons.videocam_outlined,
                    label: 'Video',
                    onTap: () {
                      setState(() {
                        _videoThumb = 'https://images.unsplash.com/photo-1518770660439-4636190af475';
                      });
                    },
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(L10n.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSubmit(_controller.text.trim(), List<String>.from(_images), _videoThumb);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(L10n.post),
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

class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

class _PreviewMedia extends StatelessWidget {
  const _PreviewMedia({required this.images, required this.videoThumb});

  final List<String> images;
  final String? videoThumb;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final url in images)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(url, width: 72, height: 72, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                            width: 72,
                            height: 72,
                            color: AppColors.outline.withOpacity(0.2),
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image),
                          )),
                ),
            ],
          ),
        if (videoThumb != null) ...[
          const SizedBox(height: Spacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  videoThumb!,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 140,
                    color: AppColors.outline.withOpacity(0.2),
                    alignment: Alignment.center,
                    child: const Icon(Icons.videocam_off),
                  ),
                ),
                const CircleAvatar(
                  backgroundColor: Colors.black38,
                  child: Icon(Icons.play_arrow_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Post {
  _Post({
    required this.userName,
    required this.text,
    this.imageUrls = const [],
    this.videoThumbnailUrl,
    required this.likes,
    required this.comments,
    required this.createdAt,
  });

  final String userName;
  final String text;
  final List<String> imageUrls;
  final String? videoThumbnailUrl;
  final int likes;
  final int comments;
  final DateTime createdAt;

  int get score => likes * 2 + comments; // simplistic trending score
}


