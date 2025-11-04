import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../app/theme/colors.dart';
import '../app/theme/spacing.dart';
import '../core/localization/l10n.dart';

class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.userName,
    required this.text,
    this.avatar,
    this.imageUrls = const [],
    this.videoPath,
    this.onPlay,
    this.isPlaying = false,
    this.likes = 0,
    this.comments = 0,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  final String userName;
  final String text; // empty string means voice-only
  final ImageProvider<Object>? avatar;
  final List<String> imageUrls;
  final String? videoPath;
  final VoidCallback? onPlay;
  final bool isPlaying;
  final int likes;
  final int comments;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: avatar,
                  child: avatar == null ? const Icon(Icons.person) : null,
                ),
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
            if (text.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            if (imageUrls.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              _ImagesGrid(imageUrls: imageUrls),
            ],
            if (videoPath != null) ...[
              const SizedBox(height: Spacing.sm),
              _PostVideoPlayer(videoPath: videoPath!),
            ],
            if (text.isEmpty && imageUrls.isEmpty && videoPath == null)
              ...[
                const SizedBox(height: Spacing.sm),
                _AudioRow(isPlaying: isPlaying, onPlay: onPlay),
              ],
            const SizedBox(height: Spacing.sm),
            const Divider(height: 1),
            const SizedBox(height: Spacing.sm),
            _ActionsRow(
              likes: likes,
              comments: comments,
              onLike: onLike,
              onComment: onComment,
              onShare: onShare,
            ),
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

class _ImagesGrid extends StatelessWidget {
  const _ImagesGrid({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final int count = imageUrls.length.clamp(1, 4);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: count,
        itemBuilder: (context, index) {
          final String url = imageUrls[index];
          final bool showOverlay = index == 3 && imageUrls.length > 4;
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(color: AppColors.outline.withOpacity(0.2)),
              Image.network(url, fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image))),
              if (showOverlay)
                Container(
                  color: Colors.black45,
                  alignment: Alignment.center,
                  child: Text(
                    '+${imageUrls.length - 3}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PostVideoPlayer extends StatefulWidget {
  const _PostVideoPlayer({required this.videoPath});

  final String videoPath;

  @override
  State<_PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<_PostVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.file(File(widget.videoPath));
      _controller = controller;
      await controller.initialize();
      controller.setLooping(false);
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggle() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.outline.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline),
        ),
        child: Text('Failed to load video', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error)),
      );
    }
    if (_isInitializing || _controller == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.outline.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline),
        ),
        child: const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final aspect = _controller!.value.aspectRatio == 0 ? 16 / 9 : _controller!.value.aspectRatio;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: aspect,
            child: VideoPlayer(_controller!),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: AppColors.brand,
                bufferedColor: AppColors.outline,
                backgroundColor: Colors.black26,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              child: Container(
                color: Colors.transparent,
                height: 200,
                alignment: Alignment.center,
                child: Icon(
                  _controller!.value.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                  size: 56,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.likes,
    required this.comments,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  final int likes;
  final int comments;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: Icons.favorite_border,
          label: likes.toString(),
          onTap: onLike,
        ),
        const SizedBox(width: Spacing.lg),
        _ActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: comments.toString(),
          onTap: onComment,
        ),
        const Spacer(),
        _ActionButton(
          icon: Icons.share_outlined,
          label: null, // icon only to keep compact
          onTap: onShare,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, this.label, this.onTap});

  final IconData icon;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label!, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}


