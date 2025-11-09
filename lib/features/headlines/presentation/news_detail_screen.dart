import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/accessibility/accessibility_manager.dart';
import '../../../widgets/share_thoughts_modal.dart';
import '../../../widgets/text_input_screen.dart';
import '../../../widgets/audio_recording_screen.dart';
import '../../../widgets/video_recording_screen.dart';
import '../data/viewer_thought_model.dart';
import '../../../widgets/viewer_thought_card.dart';
import '../../../widgets/highlighted_text.dart';
import '../data/headline_model.dart';
import '../../../services/audio_player_service.dart';
import '../../../services/voice_interpret_service.dart';
import '../../../services/tts_service.dart';
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
  final TtsService _ttsService = TtsService();
  String? _playingId;
  bool _isUploading = false;
  bool _isLoadingThoughts = false;
  bool _isTtsPlaying = false;
  bool _isTtsPaused = false;
  String? _highlightedWord;
  int? _highlightStartOffset;
  int? _highlightEndOffset;
  String _fullTextToRead = '';
  
  // Track text section boundaries for accurate highlighting
  int _titleEnd = 0;
  int _sourceStart = 0;
  int _sourceEnd = 0;
  int _summaryStart = 0;

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

    // Set up TTS callbacks to update UI
    _ttsService.onStart = () {
      if (mounted) {
        setState(() {
          _isTtsPlaying = true;
          _isTtsPaused = false;
          _highlightedWord = null;
          _highlightStartOffset = null;
          _highlightEndOffset = null;
        });
      }
    };
    _ttsService.onComplete = () {
      if (mounted) {
        setState(() {
          _isTtsPlaying = false;
          _isTtsPaused = false;
          _highlightedWord = null;
          _highlightStartOffset = null;
          _highlightEndOffset = null;
        });
      }
    };
    _ttsService.onStop = () {
      if (mounted) {
        setState(() {
          _isTtsPlaying = false;
          _isTtsPaused = false;
          _highlightedWord = null;
          _highlightStartOffset = null;
          _highlightEndOffset = null;
        });
      }
    };
    // Set up word update callback for highlighting
    _ttsService.onWordUpdate = (String word, int startOffset, int endOffset) {
      if (mounted) {
        // Clean the word - remove leading/trailing punctuation and whitespace
        // This ensures we only highlight the actual word content
        final cleanedWord = word.trim().replaceAll(RegExp(r'^[^\w\u0900-\u097F]+|[^\w\u0900-\u097F]+$', unicode: true), '');
        
        setState(() {
          // Only update if we have a valid word (not just punctuation/whitespace)
          if (cleanedWord.isNotEmpty) {
            _highlightedWord = cleanedWord;
            _highlightStartOffset = startOffset;
            _highlightEndOffset = endOffset;
          } else {
            // Clear highlight if word is empty/invalid
            _highlightedWord = null;
            _highlightStartOffset = null;
            _highlightEndOffset = null;
          }
        });
      }
    };
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _ttsService.stop();
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
        child: _ModernActionButtons(
          isTtsPlaying: _isTtsPlaying,
          isTtsPaused: _isTtsPaused,
          onListen: _isTtsPlaying || _isTtsPaused
              ? () => _handleTtsToggle()
              : () => _handleListenButton(),
          onShareThoughts: () => _showShareThoughtsModal(context),
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
            // Title with highlighting support (offset-based matching)
            HighlightedText(
              text: widget.headline.title,
              highlightedWord: _isTtsPlaying && _getSectionForOffset(_highlightStartOffset ?? -1) == 'title' 
                  ? _highlightedWord 
                  : null,
              highlightStartOffset: _getSectionForOffset(_highlightStartOffset ?? -1) == 'title'
                  ? _getSectionRelativeOffset(_highlightStartOffset, 'title')
                  : null,
              highlightEndOffset: _getSectionForOffset(_highlightEndOffset ?? -1) == 'title'
                  ? _getSectionRelativeOffset(_highlightEndOffset, 'title')
                  : null,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
              highlightColor: Colors.yellow.withOpacity(0.5),
            ),
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                const Icon(Icons.newspaper_rounded, size: 20),
                const SizedBox(width: 8),
                // Source with highlighting support (offset-based matching)
                Expanded(
                  child: HighlightedText(
                    text: widget.headline.source,
                    highlightedWord: _isTtsPlaying && _getSectionForOffset(_highlightStartOffset ?? -1) == 'source' 
                        ? _highlightedWord 
                        : null,
                    highlightStartOffset: _getSectionForOffset(_highlightStartOffset ?? -1) == 'source'
                        ? _getSectionRelativeOffset(_highlightStartOffset, 'source')
                        : null,
                    highlightEndOffset: _getSectionForOffset(_highlightEndOffset ?? -1) == 'source'
                        ? _getSectionRelativeOffset(_highlightEndOffset, 'source')
                        : null,
                    style: Theme.of(context).textTheme.bodyMedium,
                    highlightColor: Colors.yellow.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            // Summary with highlighting support (offset-based matching)
            HighlightedText(
              text: widget.headline.summary ?? '',
              highlightedWord: _isTtsPlaying && _getSectionForOffset(_highlightStartOffset ?? -1) == 'summary' 
                  ? _highlightedWord 
                  : null,
              highlightStartOffset: _getSectionForOffset(_highlightStartOffset ?? -1) == 'summary'
                  ? _getSectionRelativeOffset(_highlightStartOffset, 'summary')
                  : null,
              highlightEndOffset: _getSectionForOffset(_highlightEndOffset ?? -1) == 'summary'
                  ? _getSectionRelativeOffset(_highlightEndOffset, 'summary')
                  : null,
              style: Theme.of(context).textTheme.bodyLarge,
              highlightColor: Colors.yellow.withOpacity(0.5),
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

  /// Gets the full text content to be read aloud
  /// Also calculates section boundaries for accurate highlighting
  String _getTextToRead() {
    final buffer = StringBuffer();
    
    // Add title
    buffer.write(widget.headline.title);
    _titleEnd = buffer.length;
    buffer.writeln();
    buffer.writeln();
    
    // Add source information (just the source name for cleaner TTS)
    if (widget.headline.source.isNotEmpty) {
      _sourceStart = buffer.length;
      buffer.write(widget.headline.source);
      _sourceEnd = buffer.length;
      buffer.writeln();
      buffer.writeln();
    } else {
      _sourceStart = _titleEnd;
      _sourceEnd = _titleEnd;
    }
    
    // Add summary (read once, not repeated)
    if (widget.headline.summary != null && widget.headline.summary!.isNotEmpty) {
      _summaryStart = buffer.length;
      buffer.write(widget.headline.summary!);
    } else {
      _summaryStart = _sourceEnd;
    }
    
    return buffer.toString().trim();
  }
  
  /// Determines which section a highlight offset falls into
  /// Returns: 'title', 'source', 'summary', or null
  /// Offsets are relative to the full text (including newlines between sections)
  String? _getSectionForOffset(int offset) {
    if (offset < 0) return null;
    
    // Title section: from start to end of title (before newlines)
    if (offset < _titleEnd) {
      return 'title';
    }
    
    // Source section: from source start to source end (before newlines)
    // Note: _sourceStart includes the newlines after title
    if (_sourceStart > 0 && offset >= _sourceStart && offset < _sourceEnd) {
      return 'source';
    }
    
    // Summary section: from summary start to end
    // Note: _summaryStart includes the newlines after source
    if (_summaryStart > 0 && offset >= _summaryStart) {
      return 'summary';
    }
    
    return null;
  }
  
  /// Calculates the offset within a section (relative to that section's text)
  /// Accounts for newlines that were added between sections in the full text
  int? _getSectionRelativeOffset(int? fullTextOffset, String section) {
    if (fullTextOffset == null || fullTextOffset < 0) return null;
    
    switch (section) {
      case 'title':
        // Title starts at 0, so offset is already relative
        return fullTextOffset.clamp(0, widget.headline.title.length);
      
      case 'source':
        // Source starts at _sourceStart in full text
        // Need to account for newlines: _sourceStart = _titleEnd + 2 newlines
        if (_sourceStart > 0) {
          final relativeOffset = (fullTextOffset - _sourceStart).clamp(0, widget.headline.source.length);
          return relativeOffset;
        }
        return null;
      
      case 'summary':
        // Summary starts at _summaryStart in full text
        // Need to account for newlines: _summaryStart = _sourceEnd + 2 newlines
        if (_summaryStart > 0 && widget.headline.summary != null) {
          final relativeOffset = (fullTextOffset - _summaryStart).clamp(0, widget.headline.summary!.length);
          return relativeOffset;
        }
        return null;
      
      default:
        return null;
    }
  }

  /// Handles the Listen button press - starts TTS
  Future<void> _handleListenButton() async {
    try {
      final textToRead = _getTextToRead();
      if (textToRead.isEmpty) {
        _announce(context, 'No content available to read');
        return;
      }

      // Store the full text for highlighting
      _fullTextToRead = textToRead;

      // Stop any currently playing audio thoughts to avoid conflicts
      if (_playingId != null) {
        await _player.stop();
      }

      // Clear previous highlights
      if (mounted) {
        setState(() {
          _highlightedWord = null;
          _highlightStartOffset = null;
          _highlightEndOffset = null;
        });
      }

      // Start TTS
      await _ttsService.speak(
        textToRead,
        headlineLanguage: widget.headline.language,
      );
    } catch (e) {
      print('Error starting TTS: $e');
      if (mounted) {
        _announce(context, 'Error reading article: $e');
      }
    }
  }

  /// Handles TTS toggle (pause/resume)
  Future<void> _handleTtsToggle() async {
    try {
      if (_isTtsPaused) {
        // Resume
        await _ttsService.resume();
        if (mounted) {
          setState(() {
            _isTtsPlaying = true;
            _isTtsPaused = false;
          });
        }
      } else if (_isTtsPlaying) {
        // Pause
        await _ttsService.pause();
        if (mounted) {
          setState(() {
            _isTtsPaused = true;
            _isTtsPlaying = false;
          });
        }
      }
    } catch (e) {
      print('Error toggling TTS: $e');
      if (mounted) {
        _announce(context, 'Error controlling playback: $e');
      }
    }
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

class _ModernActionButtons extends StatelessWidget {
  const _ModernActionButtons({
    required this.isTtsPlaying,
    required this.isTtsPaused,
    required this.onListen,
    required this.onShareThoughts,
  });

  final bool isTtsPlaying;
  final bool isTtsPaused;
  final VoidCallback onListen;
  final VoidCallback onShareThoughts;

  @override
  Widget build(BuildContext context) {
    final accessibilityManager = AccessibilityManager();
    final fontScale = accessibilityManager.fontScale;
    final isDark = accessibilityManager.isDarkMode;
    final isWarm = accessibilityManager.isWarmMode;

    return Container(
      padding: EdgeInsets.all((16 * fontScale).clamp(12.0, 20.0)),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1E1E1E)
            : (isWarm ? const Color(0xFFF9F0E6) : Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModernButton(
              onPressed: onListen,
              icon: isTtsPlaying
                  ? Icons.pause_circle_filled_rounded
                  : isTtsPaused
                      ? Icons.play_circle_filled_rounded
                      : Icons.headphones_rounded,
              label: isTtsPlaying
                  ? L10n.pause
                  : isTtsPaused
                      ? L10n.play
                      : L10n.listen,
              isPrimary: true,
              fontScale: fontScale,
              isDark: isDark,
              isWarm: isWarm,
            ),
          ),
          SizedBox(width: (16 * fontScale).clamp(12.0, 20.0)),
          Expanded(
            child: _ModernButton(
              onPressed: onShareThoughts,
              icon: Icons.mic_rounded,
              label: L10n.thoughtsQ,
              isPrimary: false,
              fontScale: fontScale,
              isDark: isDark,
              isWarm: isWarm,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernButton extends StatefulWidget {
  const _ModernButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.fontScale,
    required this.isDark,
    required this.isWarm,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;
  final double fontScale;
  final bool isDark;
  final bool isWarm;

  @override
  State<_ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<_ModernButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = (64 * widget.fontScale).clamp(56.0, 72.0);
    final iconSize = (28 * widget.fontScale).clamp(24.0, 32.0);
    final fontSize = (16 * widget.fontScale).clamp(14.0, 20.0);
    final borderRadius = 16.0;

    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;
    List<BoxShadow> shadows;

    if (widget.isPrimary) {
      // Primary button (Listen) - gradient style
      backgroundColor = AppColors.brand;
      foregroundColor = Colors.white;
      borderColor = AppColors.brandDark;
      shadows = [
        BoxShadow(
          color: AppColors.brand.withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      // Secondary button (Share Thoughts)
      backgroundColor = widget.isDark
          ? Colors.white.withOpacity(0.15)
          : (widget.isWarm ? const Color(0xFFF5E6D3) : Colors.white);
      foregroundColor = widget.isDark
          ? Colors.white
          : (widget.isWarm ? const Color(0xFF4A3A2A) : AppColors.brand);
      borderColor = widget.isDark
          ? Colors.white.withOpacity(0.3)
          : (widget.isWarm ? const Color(0xFFD4C4B0) : AppColors.brand.withOpacity(0.3));
      shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: buttonHeight,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor,
              width: widget.isPrimary ? 0 : 1.5,
            ),
            boxShadow: shadows,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: (20 * widget.fontScale).clamp(16.0, 24.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      size: iconSize,
                      color: foregroundColor,
                    ),
                    SizedBox(width: (12 * widget.fontScale).clamp(10.0, 16.0)),
                    Flexible(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: foregroundColor,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


