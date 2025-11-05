import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../app/theme/colors.dart';
import '../app/theme/spacing.dart';
import '../core/localization/l10n.dart';
import '../features/headlines/data/viewer_thought_model.dart';

class ViewerThoughtCard extends StatefulWidget {
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
  State<ViewerThoughtCard> createState() => _ViewerThoughtCardState();
}

class _ViewerThoughtCardState extends State<ViewerThoughtCard> with SingleTickerProviderStateMixin {
  bool _showTranscript = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didUpdateWidget(ViewerThoughtCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync animation with playing state
    if (widget.isPlaying && !oldWidget.isPlaying) {
      // Start animation when playback starts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isPlaying) {
          _waveController.repeat();
        }
      });
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      // Stop and reset animation when playback stops/pauses/completes
      _waveController.stop();
      _waveController.reset();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

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
                    widget.thought.userName,
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
            if (widget.thought.type == ThoughtType.audio) ...[
              // Assistant reply as caption above audio player
              if (widget.thought.llmReply != null && widget.thought.llmReply!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.brand.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.thought.llmReply!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: Spacing.md),
              ],
              _AudioRow(
                isPlaying: widget.isPlaying,
                onPlay: widget.onPlay,
                waveController: widget.isPlaying ? _waveController : null,
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  Text('Transcript', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() => _showTranscript = !_showTranscript),
                    child: Text(_showTranscript ? 'Hide' : 'View'),
                  ),
                ],
              ),
              if (_showTranscript)
                Text(
                  (widget.thought.text != null && widget.thought.text!.isNotEmpty)
                      ? widget.thought.text!
                      : 'Transcript not available',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
            ] else if (widget.thought.type == ThoughtType.video) ...[
              if (widget.thought.videoUrl != null) ...[
                _ThoughtVideoPlayer(videoPath: widget.thought.videoUrl!),
              ] else ...[
                _VideoPlayer(onPlay: widget.onPlay),
              ],
              if (widget.thought.text != null && widget.thought.text!.isNotEmpty) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  widget.thought.text!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ] else if (widget.thought.text != null && widget.thought.text!.isNotEmpty) ...[
              Text(
                widget.thought.text!,
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
  const _AudioRow({
    required this.isPlaying,
    this.onPlay,
    this.waveController,
  });

  final bool isPlaying;
  final VoidCallback? onPlay;
  final AnimationController? waveController;

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
          child: isPlaying && waveController != null
              ? _SoundWave(controller: waveController!)
              : Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.outline.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
        ),
      ],
    );
  }
}

class _SoundWave extends StatelessWidget {
  const _SoundWave({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(20, (index) {
              final delay = index * 0.1;
              final value = (controller.value + delay) % 1.0;
              final height = 8 + (math.sin(value * math.pi * 2) * 0.5 + 0.5) * 24;
              return Container(
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.6 + (value * 0.4)),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
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

class _ThoughtVideoPlayer extends StatefulWidget {
  const _ThoughtVideoPlayer({required this.videoPath});

  final String videoPath;

  @override
  State<_ThoughtVideoPlayer> createState() => _ThoughtVideoPlayerState();
}

class _ThoughtVideoPlayerState extends State<_ThoughtVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      final file = File(widget.videoPath);
      final controller = VideoPlayerController.file(file);
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

  void _togglePlay() {
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
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outline),
        ),
        child: Text(
          'Failed to load video',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error),
        ),
      );
    }

    if (_isInitializing || _controller == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outline),
        ),
        child: const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final aspect = _controller!.value.aspectRatio == 0
        ? 16 / 9
        : _controller!.value.aspectRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
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
                  onTap: _togglePlay,
                  child: Container(
                    color: Colors.transparent,
                    height: 200,
                    alignment: Alignment.center,
                    child: Icon(
                      _controller!.value.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      size: 56,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

