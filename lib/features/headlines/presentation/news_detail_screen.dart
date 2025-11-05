import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import '../../../app/theme/spacing.dart';
import '../../../core/localization/l10n.dart';
import '../../../widgets/share_thoughts_modal.dart';
import '../../../widgets/text_input_screen.dart';
import '../../../widgets/audio_recording_screen.dart';
import '../../../widgets/video_recording_screen.dart';
import '../data/viewer_thought_model.dart';
import '../../../widgets/viewer_thought_card.dart';
import '../data/headline_model.dart';
import '../../../services/audio_player_service.dart';
import '../../../services/voice_interpret_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../../api/thoughts/thoughts_repository.dart';
import '../../../core/session/session_manager.dart';

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
  final AudioPlayerService _player = AudioPlayerService();
  final ThoughtsRepository _thoughtsRepository = ThoughtsRepository();
  final SessionManager _sessionManager = SessionManager();
  String? _playingId;
  bool _isUploading = false;
  bool _isLoadingThoughts = false;

  Future<void> _loadThoughts() async {
    if (widget.headline.url == null || widget.headline.url!.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingThoughts = true;
    });

    try {
      final fresh = await _thoughtsRepository.getThoughtsByNewsUrl(widget.headline.url!);
      if (mounted) {
        setState(() {
          // Preserve local transcript/llmReply/media fields when server doesn't provide them yet
          final existingById = {for (final t in _thoughts) t.id: t};
          final merged = <ViewerThought>[];
          for (final f in fresh) {
            final prev = existingById[f.id];
            if (prev == null) {
              merged.add(f);
            } else {
              merged.add(ViewerThought(
                id: f.id,
                userName: f.userName,
                type: f.type,
                text: f.text ?? prev.text, // keep transcript if server missing
                audioUrl: f.audioUrl ?? prev.audioUrl,
                videoUrl: f.videoUrl ?? prev.videoUrl,
                localFilePath: prev.localFilePath ?? f.localFilePath,
                remoteFileId: f.remoteFileId ?? prev.remoteFileId,
                mediaUrl: f.mediaUrl ?? prev.mediaUrl,
                duration: f.duration ?? prev.duration,
                status: f.status,
                llmReply: f.llmReply ?? prev.llmReply, // keep caption if server missing
                headlineId: f.headlineId ?? prev.headlineId,
                createdAt: f.createdAt,
              ));
            }
          }
          _thoughts
            ..clear()
            ..addAll(merged);
          _isLoadingThoughts = false;
        });
      }
    } catch (e) {
      print('Error loading thoughts: $e');
      if (mounted) {
        setState(() {
          _isLoadingThoughts = false;
        });
      }
    }
  }

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    // initial load from backend
    _loadThoughts();
    // Listen to player state changes to update UI in real-time
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        if (state.playing && _player.currentId != null) {
          // Audio is playing - show pause button and waves
          _playingId = _player.currentId;
        } else {
          // Audio is paused or completed - show play button, stop waves
          _playingId = null;
          // Clear service's currentId when completed
          if (state.processingState == ProcessingState.completed && _player.currentId != null) {
            _player.stop();
          }
        }
      });
    });

    // Also listen to position to detect completion more reliably
    _positionSubscription = _player.positionStream.listen((position) async {
      if (!mounted) return;
      final duration = _player.duration;
      if (duration != null && position >= duration && _playingId != null) {
        // Audio reached end - clear playing state
        setState(() {
          _playingId = null;
        });
        await _player.stop();
      }
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

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
            if (_isLoadingThoughts) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: Spacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
            ] else if (_thoughts.isEmpty) ...[
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
                  .map((t) => ViewerThoughtCard(
                        thought: t,
                        isPlaying: _playingId == t.id,
                        onPlay: () async {
                          try {
                            // Use mediaUrl if available (from server), otherwise use local file or audioUrl
                            String? sourcePath;
                            if (t.mediaUrl != null && t.mediaUrl!.isNotEmpty) {
                              sourcePath = t.mediaUrl;
                              print('[NewsDetailScreen] Using mediaUrl: $sourcePath');
                            } else if (t.localFilePath != null && t.localFilePath!.isNotEmpty) {
                              sourcePath = t.localFilePath;
                              print('[NewsDetailScreen] Using localFilePath: $sourcePath');
                            } else if (t.audioUrl != null && t.audioUrl!.isNotEmpty) {
                              sourcePath = t.audioUrl;
                              print('[NewsDetailScreen] Using audioUrl: $sourcePath');
                            }

                            if (sourcePath == null || sourcePath.isEmpty) {
                              print('[NewsDetailScreen] No valid source path found for thought: ${t.id}');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No audio source available')),
                              );
                              return;
                            }

                            print('[NewsDetailScreen] Playing audio: id=${t.id}, sourcePath=$sourcePath');
                            await _player.togglePlay(id: t.id, sourcePath: sourcePath);
                            if (mounted) {
                              setState(() {
                                _playingId = _player.currentId;
                              });
                            }
                          } catch (e) {
                            print('[NewsDetailScreen] Error playing audio: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error playing audio: $e')),
                              );
                            }
                          }
                        },
                      ))
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
    await _sessionManager.init();
    final userId = _sessionManager.userId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to share your thoughts')),
      );
      return;
    }

    final result = await showShareThoughtsModal<String>(context);
    if (result != null && mounted) {
      switch (result) {
        case 'record_audio':
          final audioResult = await Navigator.of(context).push<dynamic>(
            MaterialPageRoute(builder: (_) => const AudioRecordingScreen()),
          );
          if (audioResult != null && mounted) {
            String? path;
            String? transcript;
            if (audioResult is String) {
              path = audioResult;
            } else if (audioResult is Map) {
              path = audioResult['path'] as String?;
              transcript = (audioResult['transcript'] as String?)?.trim();
            }

            if (path == null || path.isEmpty) return;

            final audioFile = File(path);
            if (!await audioFile.exists()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Audio file not found')),
              );
              return;
            }

            // Optimistically add thought
            final tempId = DateTime.now().millisecondsSinceEpoch.toString();
            setState(() {
              _isUploading = true;
              _thoughts.insert(
                0,
                ViewerThought(
                  id: tempId,
                  userName: 'You',
                  type: ThoughtType.audio,
                  localFilePath: path,
                  text: (transcript != null && transcript.isNotEmpty) ? transcript : null,
                  headlineId: widget.headline.id,
                  createdAt: DateTime.now(),
                  status: ThoughtStatus.pending,
                ),
              );
            });
            _announce(context, 'Uploading audio thought...');

            // Upload to server
            try {
              final thought = await _thoughtsRepository.createAudioThought(
                newsUrl: widget.headline.url ?? '',
                userId: userId,
                audioFile: audioFile,
              );

              if (!mounted) return;
              setState(() {
                final idx = _thoughts.indexWhere((t) => t.id == tempId);
                if (idx != -1) {
                  _thoughts[idx] = thought;
                } else {
                  _thoughts.insert(0, thought);
                }
                _isUploading = false;
              });
              _announce(context, 'Audio thought uploaded');
              // After upload, call STT+LLM to get transcript and summary
              try {
                final vi = VoiceInterpretService();
                final viResp = await vi.uploadAndInterpret(
                  filePath: audioFile.path,
                  language: L10n.locale.value,
                );
                final transcript = (viResp['transcript'] as String?)?.trim();
                final llmReply = (viResp['llmReply'] as String?)?.trim();

                if (mounted) {
                  setState(() {
                    final idx = _thoughts.indexWhere((t) => t.id == thought.id);
                    if (idx != -1) {
                      _thoughts[idx] = ViewerThought(
                        id: _thoughts[idx].id,
                        userName: _thoughts[idx].userName,
                        type: _thoughts[idx].type,
                        text: (transcript != null && transcript.isNotEmpty)
                            ? transcript
                            : _thoughts[idx].text,
                        audioUrl: _thoughts[idx].audioUrl,
                        videoUrl: _thoughts[idx].videoUrl,
                        localFilePath: _thoughts[idx].localFilePath,
                        remoteFileId: _thoughts[idx].remoteFileId,
                        mediaUrl: _thoughts[idx].mediaUrl,
                        duration: _thoughts[idx].duration,
                        status: _thoughts[idx].status,
                        llmReply: llmReply ?? _thoughts[idx].llmReply,
                        headlineId: _thoughts[idx].headlineId,
                        createdAt: _thoughts[idx].createdAt,
                      );
                    }
                  });
                }
              } catch (e) {
                // Non-fatal: keep UI, just log/notify
                print('Voice interpret failed: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transcription running in background')),
                  );
                }
              }
              // Reload thoughts to get any server-side updates later
              _loadThoughts();
            } catch (e) {
              if (!mounted) return;
              setState(() {
                _thoughts.removeWhere((t) => t.id == tempId);
                _isUploading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to upload audio: $e')),
              );
            }
          }
          break;
        case 'type_text':
          final text = await Navigator.of(context).push<String>(
            MaterialPageRoute(builder: (_) => const TextInputScreen()),
          );
          if (text != null && text.trim().isNotEmpty && mounted) {
            // Optimistically add thought
            final tempId = DateTime.now().millisecondsSinceEpoch.toString();
            setState(() {
              _isUploading = true;
              _thoughts.insert(
                0,
                ViewerThought(
                  id: tempId,
                  userName: 'You',
                  type: ThoughtType.text,
                  text: text.trim(),
                  createdAt: DateTime.now(),
                  status: ThoughtStatus.pending,
                ),
              );
            });
            _announce(context, 'Posting thought...');

            // Create thought on server
            try {
              final thought = await _thoughtsRepository.createTextThought(
                newsUrl: widget.headline.url ?? '',
                userId: userId,
                text: text.trim(),
              );

              if (!mounted) return;
              setState(() {
                final idx = _thoughts.indexWhere((t) => t.id == tempId);
                if (idx != -1) {
                  _thoughts[idx] = thought;
                } else {
                  _thoughts.insert(0, thought);
                }
                _isUploading = false;
              });
              _announce(context, 'Thought posted');
              // Reload thoughts to get any updates
              _loadThoughts();
            } catch (e) {
              if (!mounted) return;
              setState(() {
                _thoughts.removeWhere((t) => t.id == tempId);
                _isUploading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to post thought: $e')),
              );
            }
          }
          break;
        case 'record_video':
          final videoPath = await Navigator.of(context).push<String>(
            MaterialPageRoute(builder: (_) => const VideoRecordingScreen()),
          );
          if (videoPath != null && mounted) {
            final videoFile = File(videoPath);
            if (!await videoFile.exists()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video file not found')),
              );
              return;
            }

            // Optimistically add thought
            final tempId = DateTime.now().millisecondsSinceEpoch.toString();
            setState(() {
              _isUploading = true;
              _thoughts.insert(
                0,
                ViewerThought(
                  id: tempId,
                  userName: 'You',
                  type: ThoughtType.video,
                  localFilePath: videoPath,
                  createdAt: DateTime.now(),
                  status: ThoughtStatus.pending,
                ),
              );
            });
            _announce(context, 'Uploading video thought...');

            // Upload to server
            try {
              final thought = await _thoughtsRepository.createVideoThought(
                newsUrl: widget.headline.url ?? '',
                userId: userId,
                videoFile: videoFile,
              );

              if (!mounted) return;
              setState(() {
                final idx = _thoughts.indexWhere((t) => t.id == tempId);
                if (idx != -1) {
                  _thoughts[idx] = thought;
                } else {
                  _thoughts.insert(0, thought);
                }
                _isUploading = false;
              });
              _announce(context, 'Video thought uploaded');
              // Reload thoughts to get any updates
              _loadThoughts();
            } catch (e) {
              if (!mounted) return;
              setState(() {
                _thoughts.removeWhere((t) => t.id == tempId);
                _isUploading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to upload video: $e')),
              );
            }
          }
          break;
      }
    }
  }
}


