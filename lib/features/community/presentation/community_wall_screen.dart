import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/video_recording_screen.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../widgets/community_post_card.dart';
import '../../../widgets/mic_dictation_button.dart';
import '../../../core/ui/ui_utils.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/accessibility/accessibility_manager.dart';
import '../../../api/community/community_posts_api.dart';
import '../../../api/common/endpoints.dart' show apiBaseUrl;
import '../../../api/profiles/profiles_repository.dart';
import '../../../api/profiles/models/profile.dart';

class CommunityWallScreen extends StatefulWidget {
  const CommunityWallScreen({super.key});

  @override
  State<CommunityWallScreen> createState() => CommunityWallScreenState();
}

class CommunityWallScreenState extends State<CommunityWallScreen> {
  int _segment = 0; // 0 = trending, 1 = recent
  final SessionManager _session = SessionManager();
  final CommunityPostsApi _communityPostsApi = CommunityPostsApi();
  final ProfilesRepository _profilesRepository = ProfilesRepository();
  bool _isLoading = false;
  bool _isPosting = false;
  final List<_Post> _posts = [];
  // Cache for profile data to avoid repeated API calls
  final Map<String, Profile> _profileCache = {};

  Future<void> _refresh() async {
    await _loadPosts();
  }

  @override
  void initState() {
    super.initState();
    // Ensure session is initialized so userId is available
    _session.init();
    _loadPosts();
  }

  Future<void> _loadPosts({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      // Ensure session is initialized before accessing userId/displayName
      await _session.init();
      
      final List<Map<String, dynamic>> raw = await _communityPostsApi.getV2Posts(limit: 20);
      
      // Create a map to track posts by ID to prevent duplicates
      final Map<String, _Post> postsMap = <String, _Post>{};
      
      // Collect unique author IDs that need profile data
      final Set<String> authorIdsToFetch = <String>{};
      
      for (final Map<String, dynamic> p in raw) {
        final String postId = (p['_id'] ?? p['id'] ?? '').toString();
        if (postId.isEmpty) continue; // Skip posts without ID
        
        final Map<String, dynamic>? author = p['author'] as Map<String, dynamic>?;
        final String authorId = (author?['userId'] ?? author?['_id'] ?? '').toString();
        if (authorId.isNotEmpty) {
          // Check if we need to fetch profile data
          final String? displayName = author?['displayName'];
          final String? imageUrl = author?['imageUrl'] ?? author?['photoUrl'] ?? author?['avatarUrl'];
          
          // If displayName or imageUrl is null, and we don't have it cached, fetch it
          if ((displayName == null || imageUrl == null) && !_profileCache.containsKey(authorId)) {
            // Check if it's the current user - use session data first
            final currentUserId = _session.userId;
            if (authorId == currentUserId) {
              final sessionDisplayName = _session.displayName;
              final sessionPhotoUrl = _session.photoUrl;
              // For current user, still fetch profile to ensure we have latest photoUrl
              // even if session has some data, as profile might have been updated
              authorIdsToFetch.add(authorId);
            } else {
              authorIdsToFetch.add(authorId);
            }
          }
        }
      }
      
      // Fetch profiles for authors that need it
      for (final String authorId in authorIdsToFetch) {
        try {
          final profile = await _profilesRepository.getProfile(authorId);
          _profileCache[authorId] = profile;
        } catch (e) {
          print('Failed to fetch profile for $authorId: $e');
          // Continue with other posts even if one profile fetch fails
        }
      }
      
      // Now process posts with profile data
      for (final Map<String, dynamic> p in raw) {
        final String postId = (p['_id'] ?? p['id'] ?? '').toString();
        if (postId.isEmpty) continue; // Skip posts without ID
        
        final Map<String, dynamic>? author = p['author'] as Map<String, dynamic>?;
        final String authorId = (author?['userId'] ?? author?['_id'] ?? '').toString();
        
        // Get displayName and photoUrl from various sources
        String? displayName;
        String? photoUrl;
        
        // Check if it's the current user - ALWAYS prioritize session data for current user
        final currentUserId = _session.userId;
        final bool isCurrentUser = authorId == currentUserId && currentUserId != null && currentUserId.isNotEmpty;
        
        // Debug: Log if we detect bad names
        if (isCurrentUser) {
          final apiDisplayName = author?['displayName'] as String?;
          if (apiDisplayName != null && (apiDisplayName.toLowerCase().contains('grandpa') || apiDisplayName.toLowerCase().contains('ram'))) {
            print('[CommunityWall] Warning: API returned bad displayName "$apiDisplayName" for current user. Using session data instead.');
          }
        }
        
        // Helper function to check if a name is a default/bad name that should be rejected
        bool isBadDefaultName(String? name) {
          if (name == null || name.isEmpty) return true;
          final lower = name.toLowerCase().trim();
          return lower == 'grandpa ram' || 
                 lower == 'grandpa' || 
                 lower == 'ram' ||
                 lower == 'user' ||
                 lower == 'anonymous' ||
                 lower == 'unknown';
        }
        
        if (isCurrentUser) {
          // For current user's posts, ALWAYS use session data first (most up-to-date)
          // Don't trust API response as it might have stale/wrong data like "grandpa ram"
          displayName = _session.displayName;
          photoUrl = _session.photoUrl;
          
          // Debug: Log session photoUrl
          if (photoUrl != null && photoUrl.isNotEmpty) {
            print('[CommunityWall] Current user photoUrl from session: $photoUrl');
          } else {
            print('[CommunityWall] Current user photoUrl is null/empty in session, will check API/cache');
          }
          
          // Reject bad default names from session
          if (isBadDefaultName(displayName)) {
            displayName = null;
          }
          
          // Only fallback to API/cache if session data is completely missing or bad
          if (displayName == null || displayName.isEmpty) {
            displayName = author?['displayName'] as String?;
            // Reject bad default names from API
            if (isBadDefaultName(displayName)) {
              displayName = null;
            }
            final cachedProfile = _profileCache[authorId];
            if ((displayName == null || displayName.isEmpty) && cachedProfile != null) {
              displayName = cachedProfile.displayName;
              // Reject bad default names from cache
              if (isBadDefaultName(displayName)) {
                displayName = null;
              }
            }
          }
          // For photoUrl, also check API/cache if session doesn't have it
          if (photoUrl == null || photoUrl.isEmpty) {
            photoUrl = author?['imageUrl'] ?? author?['photoUrl'] ?? author?['avatarUrl'];
            if (photoUrl != null && photoUrl.isNotEmpty) {
              print('[CommunityWall] Current user photoUrl from API: $photoUrl');
            }
            final cachedProfile = _profileCache[authorId];
            if ((photoUrl == null || photoUrl.isEmpty) && cachedProfile != null) {
              photoUrl = cachedProfile.photoUrl;
              if (photoUrl != null && photoUrl.isNotEmpty) {
                print('[CommunityWall] Current user photoUrl from cache: $photoUrl');
              }
            }
          }
        } else {
          // For other users' posts, check API response first, then cache
          displayName = author?['displayName'] as String?;
          // Reject bad default names from API
          if (isBadDefaultName(displayName)) {
            displayName = null;
          }
          photoUrl = author?['imageUrl'] ?? author?['photoUrl'] ?? author?['avatarUrl'];
          
          // Finally check profile cache
          final cachedProfile = _profileCache[authorId];
          if ((displayName == null || displayName.isEmpty) && cachedProfile != null) {
            displayName = cachedProfile.displayName;
            // Reject bad default names from cache
            if (isBadDefaultName(displayName)) {
              displayName = null;
            }
          }
          if ((photoUrl == null || photoUrl.isEmpty) && cachedProfile != null) {
            photoUrl = cachedProfile.photoUrl;
          }
        }
        
        // Fallback to userId if no displayName or if displayName is a bad default name
        // NEVER show default names like "User", "grandpa ram", etc.
        final String userName = (!isBadDefaultName(displayName) && displayName != null && displayName.isNotEmpty) 
            ? displayName 
            : authorId;
        final String text = (p['text'] ?? '').toString();

        final List<String> imageUrls = <String>[];
        final List<String> videoUrls = <String>[];

        final dynamic mediaList = p['media'];
        if (mediaList is List) {
          for (final dynamic m in mediaList) {
            if (m is! Map<String, dynamic>) continue;
            final String type = (m['type'] ?? '').toString();
            final String streamPath = (m['streamUrl'] ?? '').toString();
            if (streamPath.isEmpty) continue;
            final String url = (streamPath.startsWith('http://') || streamPath.startsWith('https://'))
                ? streamPath
                : '$apiBaseUrl$streamPath';
            if (type == 'image') imageUrls.add(url);
            if (type == 'video') videoUrls.add(url);
          }
        }

        final String? videoPath = videoUrls.isNotEmpty ? videoUrls.first : null;

        final dynamic likesDyn = p['likes'];
        final dynamic commentsDyn = p['comments'];

        // Build full avatar URL if available
        String? avatarUrl;
        final String? authorPhotoUrl = photoUrl;
        if (authorPhotoUrl != null && authorPhotoUrl.isNotEmpty) {
          // Check if it's already a full URL
          if (authorPhotoUrl.startsWith('http://') || authorPhotoUrl.startsWith('https://')) {
            avatarUrl = authorPhotoUrl;
          } else {
            // It's a relative path, prepend the base URL
            // Ensure the path starts with / if it doesn't already
            final String path = authorPhotoUrl.startsWith('/') ? authorPhotoUrl : '/$authorPhotoUrl';
            avatarUrl = '$apiBaseUrl$path';
          }
          if (isCurrentUser) {
            print('[CommunityWall] Built avatarUrl for current user: $avatarUrl');
          }
        } else if (isCurrentUser) {
          print('[CommunityWall] No avatarUrl for current user - photoUrl was null/empty');
        }
        
        postsMap[postId] = _Post(
          id: postId,
          userName: userName,
          text: text,
          avatarUrl: avatarUrl,
          imageUrls: imageUrls,
          videoPath: videoPath,
          likes: likesDyn is num ? likesDyn.toInt() : 0,
          comments: commentsDyn is num ? commentsDyn.toInt() : 0,
          createdAt: DateTime.tryParse((p['createdAt'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
        );
      }

      if (!mounted) return;
      setState(() {
        // Clear and replace with fresh data to prevent mixing
        _posts.clear();
        _posts.addAll(postsMap.values);
      });
    } catch (e) {
      if (!mounted) return;
      UiUtils.showTopSnackBar(context: context, message: UiUtils.friendlyErrorMessage(e), isError: true);
    } finally {
      if (mounted) {
        if (!silent) setState(() => _isLoading = false);
      }
    }
  }

  void openComposer() {
    final accessibilityManager = AccessibilityManager();
    final isDark = accessibilityManager.isDarkMode;
    final isWarm = accessibilityManager.isWarmMode;
    
    Color sheetColor = isDark 
        ? const Color(0xFF1E1E1E) 
        : (isWarm ? const Color(0xFFF9F0E6) : AppColors.surface);
    
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _ComposerSheet(
          onSubmit: (text, images, videoPath) async {
            Navigator.of(context).pop();
            final BuildContext ctx = context;
            final String? userId = _session.userId;
            if (userId == null || userId.isEmpty) {
              UiUtils.showTopSnackBar(context: ctx, message: 'Please log in first', isError: true);
              return;
            }

            // Show posting indicator
            if (mounted) {
              setState(() {
                _isPosting = true;
              });
            }

            try {
              final List<File> imageFiles = images
                  .where((p) => p.isNotEmpty && File(p).existsSync())
                  .map((p) => File(p))
                  .toList();
              final List<File> videoFiles = <File>[];
              if (videoPath != null && videoPath.isNotEmpty && File(videoPath).existsSync()) {
                videoFiles.add(File(videoPath));
              }

              // Get displayName and photoUrl from session
              final displayName = _session.displayName;
              final photoUrl = _session.photoUrl;
              
              // Create the post
              await _communityPostsApi.createV2Post(
                userId: userId,
                text: text,
                displayName: displayName,
                photoUrl: photoUrl,
                images: imageFiles,
                videos: videoFiles,
              );

              // Wait for the refresh to complete to ensure accurate data
              await _loadPosts(silent: false);

              // Switch to recent segment to show the new post
              if (mounted) {
                setState(() {
                  _segment = 1;
                });
              }

              // Show success message after refresh completes
              if (mounted) {
                UiUtils.showTopSnackBar(context: ctx, message: 'Posted successfully', isSuccess: true);
              }
            } catch (e) {
              if (mounted) {
                UiUtils.showTopSnackBar(
                  context: ctx,
                  message: UiUtils.friendlyErrorMessage(e),
                  isError: true,
                );
              }
            } finally {
              if (mounted) {
                setState(() {
                  _isPosting = false;
                });
              }
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_Post> visiblePosts = List<_Post>.from(_posts)
      ..sort((a, b) {
        // Primary sort based on segment
        final int primary = _segment == 0
            ? (b.score).compareTo(a.score) // trending by score
            : b.createdAt.compareTo(a.createdAt); // recent by time
        // Secondary sort by ID for stability
        return primary != 0 ? primary : a.id.compareTo(b.id);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          L10n.communityWall,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        leading: const SizedBox(), // keep layout clean under shell
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openComposer,
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
                  _InlineComposer(onTap: openComposer),
                  if (_isLoading || _isPosting) ...[
                    const SizedBox(height: Spacing.md),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
            for (final p in visiblePosts)
              Padding(
                key: ValueKey(p.id),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: CommunityPostCard(
                  userName: p.userName,
                  text: p.text,
                  avatar: p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
                  imageUrls: p.imageUrls,
                  videoPath: p.videoPath,
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

  final void Function(String text, List<String> imageUrls, String? videoPath) onSubmit;

  @override
  State<_ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends State<_ComposerSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _images = <String>[]; // local file paths or URLs
  String? _videoPath;
  final ImagePicker _picker = ImagePicker();
  final AccessibilityManager _accessibilityManager = AccessibilityManager();

  Future<void> _pickImages() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (files.isEmpty) return;
      if (!mounted) return;
      setState(() {
        _images.addAll(files.map((f) => f.path));
      });
    } catch (_) {
      // no-op: keep UX quiet on cancel
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (file == null) return;
      if (!mounted) return;
      setState(() => _videoPath = file.path);
    } catch (_) {
      // no-op
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final fontScale = _accessibilityManager.fontScale;
    final isDark = _accessibilityManager.isDarkMode;
    final isWarm = _accessibilityManager.isWarmMode;
    
    Color backgroundColor = isDark 
        ? const Color(0xFF1E1E1E) 
        : (isWarm ? const Color(0xFFF9F0E6) : AppColors.surface);
    Color textColor = isDark 
        ? Colors.white 
        : (isWarm ? const Color(0xFF4A3A2A) : AppColors.textPrimary);
    Color hintColor = isDark 
        ? Colors.white.withOpacity(0.5) 
        : (isWarm ? const Color(0xFF6B5A4A) : AppColors.textMuted);
    
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: Container(
          color: backgroundColor,
          child: SingleChildScrollView(
            padding: EdgeInsets.all((20 * fontScale).clamp(16.0, 24.0)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withOpacity(0.2)
                          : (isWarm ? const Color(0xFFD4C4B0) : AppColors.outline),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: (20 * fontScale).clamp(16.0, 24.0)),
                Text(
                  L10n.shareYourVichaar,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: (24 * fontScale).clamp(20.0, 32.0),
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                ),
                SizedBox(height: (20 * fontScale).clamp(16.0, 24.0)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLines: 6,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: (18 * fontScale).clamp(16.0, 24.0),
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: L10n.tellUsPlaceholder,
                          hintStyle: TextStyle(
                            fontSize: (18 * fontScale).clamp(16.0, 24.0),
                            color: hintColor,
                          ),
                          contentPadding: EdgeInsets.all((16 * fontScale).clamp(14.0, 20.0)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.2)
                                  : (isWarm ? const Color(0xFFD4C4B0) : AppColors.outline),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.2)
                                  : (isWarm ? const Color(0xFFD4C4B0) : AppColors.outline),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.brand,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark 
                              ? Colors.white.withOpacity(0.05)
                              : (isWarm ? const Color(0xFFF5E6D3) : AppColors.background),
                        ),
                      ),
                    ),
                    SizedBox(width: (12 * fontScale).clamp(10.0, 16.0)),
                    MicDictationButton(
                      controller: _controller,
                      size: (64 * fontScale).clamp(56.0, 72.0),
                    ),
                  ],
                ),
                if (_images.isNotEmpty || _videoPath != null) ...[
                  SizedBox(height: (24 * fontScale).clamp(20.0, 28.0)),
                  _PreviewMedia(
                    images: _images,
                    videoPath: _videoPath,
                    fontScale: fontScale,
                    isDark: isDark,
                    isWarm: isWarm,
                  ),
                ],
                SizedBox(height: (24 * fontScale).clamp(20.0, 28.0)),
                // Large action buttons for elderly users
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _LargeActionButton(
                            icon: Icons.photo_outlined,
                            label: 'Add Photo',
                            onTap: _pickImages,
                            fontScale: fontScale,
                            isDark: isDark,
                            isWarm: isWarm,
                          ),
                        ),
                        SizedBox(width: (12 * fontScale).clamp(10.0, 16.0)),
                        Expanded(
                          child: _LargeActionButton(
                            icon: Icons.videocam_outlined,
                            label: 'Add Video',
                            onTap: _pickVideo,
                            fontScale: fontScale,
                            isDark: isDark,
                            isWarm: isWarm,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: (12 * fontScale).clamp(10.0, 16.0)),
                    Row(
                      children: [
                        Expanded(
                          child: _LargeActionButton(
                            icon: Icons.fiber_manual_record_outlined,
                            label: 'Record Video',
                            onTap: () async {
                              final path = await Navigator.of(context).push<String>(
                                MaterialPageRoute(builder: (_) => const VideoRecordingScreen()),
                              );
                              if (path != null && mounted) {
                                setState(() => _videoPath = path);
                              }
                            },
                            fontScale: fontScale,
                            isDark: isDark,
                            isWarm: isWarm,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: (24 * fontScale).clamp(20.0, 28.0)),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: (18 * fontScale).clamp(16.0, 22.0),
                          ),
                          side: BorderSide(
                            color: isDark 
                                ? Colors.white.withOpacity(0.3)
                                : (isWarm ? const Color(0xFFD4C4B0) : AppColors.outline),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          L10n.cancel,
                          style: TextStyle(
                            fontSize: (18 * fontScale).clamp(16.0, 22.0),
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: (16 * fontScale).clamp(12.0, 20.0)),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onSubmit(_controller.text.trim(), List<String>.from(_images), _videoPath);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: (18 * fontScale).clamp(16.0, 22.0),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          L10n.post,
                          style: TextStyle(
                            fontSize: (18 * fontScale).clamp(16.0, 22.0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LargeActionButton extends StatelessWidget {
  const _LargeActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.fontScale,
    required this.isDark,
    required this.isWarm,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double fontScale;
  final bool isDark;
  final bool isWarm;

  @override
  Widget build(BuildContext context) {
    Color buttonColor = isDark 
        ? Colors.white.withOpacity(0.1)
        : (isWarm ? const Color(0xFFF5E6D3) : AppColors.surface);
    Color borderColor = isDark 
        ? Colors.white.withOpacity(0.2)
        : (isWarm ? const Color(0xFFD4C4B0) : AppColors.outline);
    Color textColor = isDark 
        ? Colors.white 
        : (isWarm ? const Color(0xFF4A3A2A) : AppColors.textPrimary);
    Color iconColor = isDark 
        ? Colors.white70 
        : (isWarm ? const Color(0xFF6B5A4A) : AppColors.textSecondary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all((16 * fontScale).clamp(14.0, 20.0)),
          decoration: BoxDecoration(
            color: buttonColor,
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: (28 * fontScale).clamp(24.0, 32.0),
                color: iconColor,
              ),
              SizedBox(width: (12 * fontScale).clamp(10.0, 16.0)),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: (18 * fontScale).clamp(16.0, 22.0),
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewMedia extends StatelessWidget {
  const _PreviewMedia({
    required this.images,
    required this.videoPath,
    required this.fontScale,
    required this.isDark,
    required this.isWarm,
  });

  final List<String> images;
  final String? videoPath;
  final double fontScale;
  final bool isDark;
  final bool isWarm;

  @override
  Widget build(BuildContext context) {
    Color borderColor = isDark 
        ? Colors.white.withOpacity(0.2)
        : (isWarm ? const Color(0xFFD4C4B0) : AppColors.outline);
    Color textColor = isDark 
        ? Colors.white 
        : (isWarm ? const Color(0xFF4A3A2A) : AppColors.textPrimary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty) ...[
          Text(
            'Selected Photos (${images.length})',
            style: TextStyle(
              fontSize: (18 * fontScale).clamp(16.0, 22.0),
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          SizedBox(height: (12 * fontScale).clamp(10.0, 16.0)),
          _ImagesPreviewRemovable(
            imagePathsOrUrls: images,
            fontScale: fontScale,
            isDark: isDark,
            isWarm: isWarm,
          ),
        ],
        if (videoPath != null) ...[
          if (images.isNotEmpty) SizedBox(height: (16 * fontScale).clamp(12.0, 20.0)),
          Text(
            'Selected Video',
            style: TextStyle(
              fontSize: (18 * fontScale).clamp(16.0, 22.0),
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          SizedBox(height: (12 * fontScale).clamp(10.0, 16.0)),
          Container(
            height: (200 * fontScale).clamp(180.0, 240.0),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.1)
                  : (isWarm ? const Color(0xFFD4C4B0).withOpacity(0.3) : AppColors.outline.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_rounded,
                  size: (32 * fontScale).clamp(28.0, 36.0),
                  color: textColor,
                ),
                SizedBox(width: (12 * fontScale).clamp(10.0, 16.0)),
                Text(
                  'Video attached',
                  style: TextStyle(
                    fontSize: (18 * fontScale).clamp(16.0, 22.0),
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ImagesPreviewRemovable extends StatefulWidget {
  const _ImagesPreviewRemovable({
    required this.imagePathsOrUrls,
    required this.fontScale,
    required this.isDark,
    required this.isWarm,
  });

  final List<String> imagePathsOrUrls;
  final double fontScale;
  final bool isDark;
  final bool isWarm;

  @override
  State<_ImagesPreviewRemovable> createState() => _ImagesPreviewRemovableState();
}

class _ImagesPreviewRemovableState extends State<_ImagesPreviewRemovable> {
  void _removeAt(int index) {
    setState(() {
      widget.imagePathsOrUrls.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // For single image, show large preview. For multiple, show grid
    final imageSize = widget.imagePathsOrUrls.length == 1
        ? (280 * widget.fontScale).clamp(250.0, 320.0)
        : (120 * widget.fontScale).clamp(100.0, 140.0);
    
    Color borderColor = widget.isDark 
        ? Colors.white.withOpacity(0.2)
        : (widget.isWarm ? const Color(0xFFD4C4B0) : AppColors.outline);

    if (widget.imagePathsOrUrls.length == 1) {
      // Single large image preview
      final String pathOrUrl = widget.imagePathsOrUrls[0];
      final bool isNetwork = Uri.tryParse(pathOrUrl)?.hasScheme == true &&
          (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://'));
      
      return Stack(
        children: [
          Container(
            width: double.infinity,
            height: imageSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: isNetwork
                  ? Image.network(
                      pathOrUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: widget.isDark 
                            ? Colors.white.withOpacity(0.1)
                            : (widget.isWarm ? const Color(0xFFD4C4B0).withOpacity(0.3) : AppColors.outline.withOpacity(0.2)),
                        child: Icon(
                          Icons.broken_image,
                          size: (48 * widget.fontScale).clamp(40.0, 56.0),
                          color: widget.isDark 
                              ? Colors.white60 
                              : (widget.isWarm ? const Color(0xFF6B5A4A) : AppColors.textSecondary),
                        ),
                      ),
                    )
                  : Image.file(
                      File(pathOrUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: widget.isDark 
                            ? Colors.white.withOpacity(0.1)
                            : (widget.isWarm ? const Color(0xFFD4C4B0).withOpacity(0.3) : AppColors.outline.withOpacity(0.2)),
                        child: Icon(
                          Icons.broken_image,
                          size: (48 * widget.fontScale).clamp(40.0, 56.0),
                          color: widget.isDark 
                              ? Colors.white60 
                              : (widget.isWarm ? const Color(0xFF6B5A4A) : AppColors.textSecondary),
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            top: (12 * widget.fontScale).clamp(10.0, 16.0),
            right: (12 * widget.fontScale).clamp(10.0, 16.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _removeAt(0),
                borderRadius: BorderRadius.circular((20 * widget.fontScale).clamp(18.0, 24.0)),
                child: Container(
                  width: (40 * widget.fontScale).clamp(36.0, 44.0),
                  height: (40 * widget.fontScale).clamp(36.0, 44.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close,
                    size: (24 * widget.fontScale).clamp(20.0, 28.0),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Multiple images - show in grid
    return Wrap(
      spacing: (12 * widget.fontScale).clamp(10.0, 16.0),
      runSpacing: (12 * widget.fontScale).clamp(10.0, 16.0),
      children: List<Widget>.generate(widget.imagePathsOrUrls.length, (index) {
        final String pathOrUrl = widget.imagePathsOrUrls[index];
        final bool isNetwork = Uri.tryParse(pathOrUrl)?.hasScheme == true &&
            (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://'));
        
        return Stack(
          children: [
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: isNetwork
                    ? Image.network(
                        pathOrUrl,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: widget.isDark 
                              ? Colors.white.withOpacity(0.1)
                              : (widget.isWarm ? const Color(0xFFD4C4B0).withOpacity(0.3) : AppColors.outline.withOpacity(0.2)),
                          child: Icon(
                            Icons.broken_image,
                            size: (32 * widget.fontScale).clamp(28.0, 36.0),
                            color: widget.isDark 
                                ? Colors.white60 
                                : (widget.isWarm ? const Color(0xFF6B5A4A) : AppColors.textSecondary),
                          ),
                        ),
                      )
                    : Image.file(
                        File(pathOrUrl),
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: widget.isDark 
                              ? Colors.white.withOpacity(0.1)
                              : (widget.isWarm ? const Color(0xFFD4C4B0).withOpacity(0.3) : AppColors.outline.withOpacity(0.2)),
                          child: Icon(
                            Icons.broken_image,
                            size: (32 * widget.fontScale).clamp(28.0, 36.0),
                            color: widget.isDark 
                                ? Colors.white60 
                                : (widget.isWarm ? const Color(0xFF6B5A4A) : AppColors.textSecondary),
                          ),
                        ),
                      ),
              ),
            ),
            Positioned(
              top: (8 * widget.fontScale).clamp(6.0, 10.0),
              right: (8 * widget.fontScale).clamp(6.0, 10.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _removeAt(index),
                  borderRadius: BorderRadius.circular((18 * widget.fontScale).clamp(16.0, 20.0)),
                  child: Container(
                    width: (36 * widget.fontScale).clamp(32.0, 40.0),
                    height: (36 * widget.fontScale).clamp(32.0, 40.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.close,
                      size: (20 * widget.fontScale).clamp(18.0, 24.0),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _Post {
  _Post({
    required this.id,
    required this.userName,
    required this.text,
    this.avatarUrl,
    this.imageUrls = const [],
    this.videoPath,
    required this.likes,
    required this.comments,
    required this.createdAt,
  });

  final String id;
  final String userName;
  final String text;
  final String? avatarUrl;
  final List<String> imageUrls;
  final String? videoPath;
  final int likes;
  final int comments;
  final DateTime createdAt;

  int get score => likes * 2 + comments; // simplistic trending score
}
