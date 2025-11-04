import 'package:flutter/material.dart';
import '../../../app/theme/spacing.dart';
import '../../../core/localization/l10n.dart';
import '../../../widgets/share_thoughts_modal.dart';
import '../../../widgets/text_input_screen.dart';
import '../../../widgets/audio_recording_screen.dart';
import '../data/viewer_thought_model.dart';
import '../../../widgets/viewer_thought_card.dart';
import '../data/headline_model.dart';

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key, required this.headline});

  final Headline headline;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  double _textScale = 1.0;
  double _baseScale = 1.0;
  final List<ViewerThought> _thoughts = <ViewerThought>[];

  @override
  Widget build(BuildContext context) {
    // Apply text scale to the whole page for consistent sizing
    final scaledMedia = MediaQuery.of(context).copyWith(
      textScaleFactor: _textScale,
    );

    return MediaQuery(
      data: scaledMedia,
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.headline.title, style: Theme.of(context).textTheme.titleMedium),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(Spacing.md),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _announce(context, 'Listening to article'),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: Text(L10n.listen),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showShareThoughtsModal(context),
                  icon: const Icon(Icons.mic_rounded),
                  label: Text(L10n.shareYourThoughts),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onScaleStart: (details) {
            _baseScale = _textScale;
          },
          onScaleUpdate: (details) {
            // Only react when two or more fingers are on screen
            if (details.pointerCount < 2) return;
            final newScale = (_baseScale * details.scale).clamp(0.9, 1.8);
            if (newScale != _textScale) {
              setState(() {
                _textScale = newScale;
              });
            }
          },
          child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            Text(
              widget.headline.title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                const Icon(Icons.newspaper_rounded, size: 20),
                const SizedBox(width: 8),
                Text(widget.headline.source, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: Spacing.md),
            Text(
              // Placeholder long body; will be replaced by content from API later
              '${widget.headline.summary}\n\n${widget.headline.summary}\n\n${widget.headline.summary}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            // Thoughts By Viewers section
            Text(
              L10n.thoughtsByViewers,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: Spacing.sm),
            if (_thoughts.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                child: Text(
                  L10n.noThoughtsYet,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),
              ),
            ] else ...[
              const SizedBox(height: Spacing.xs),
              ..._thoughts
                  .map((t) => ViewerThoughtCard(thought: t))
                  .toList(),
              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
      ),
      ),
    );
  }

  void _announce(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textScaleFactor: 1.1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showShareThoughtsModal(BuildContext context) async {
    final result = await showShareThoughtsModal<String>(context);
    if (result != null) {
      switch (result) {
        case 'record_audio':
          final audioResult = await Navigator.of(context).push<String>(
            MaterialPageRoute(builder: (_) => const AudioRecordingScreen()),
          );
          if (audioResult != null && mounted) {
            setState(() {
              _thoughts.insert(
                0,
                ViewerThought(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  userName: 'You',
                  type: ThoughtType.audio,
                  audioUrl: audioResult,
                  createdAt: DateTime.now(),
                ),
              );
            });
            _announce(context, 'Audio thought added');
          }
          break;
        case 'type_text':
          final text = await Navigator.of(context).push<String>(
            MaterialPageRoute(builder: (_) => const TextInputScreen()),
          );
          if (text != null && text.trim().isNotEmpty && mounted) {
            setState(() {
              _thoughts.insert(
                0,
                ViewerThought(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  userName: 'You',
                  type: ThoughtType.text,
                  text: text.trim(),
                  createdAt: DateTime.now(),
                ),
              );
            });
            _announce(context, 'Thought posted');
          }
          break;
        case 'record_video':
          _announce(context, 'Video recording not implemented yet');
          break;
      }
    }
  }
}


