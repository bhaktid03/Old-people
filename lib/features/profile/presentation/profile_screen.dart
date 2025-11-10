import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../widgets/community_post_card.dart';
import '../../../api/profiles/profiles_repository.dart';
import '../../../api/profiles/models/profile.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/ui/ui_utils.dart';
import '../../../api/common/endpoints.dart';
import '../../../api/community/community_posts_api.dart';
import '../../../core/accessibility/accessibility_manager.dart';
import '../../../app/router.dart';
import '../../../widgets/bottom_nav.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfilesRepository _profilesRepository = ProfilesRepository();
  final CommunityPostsApi _communityPostsApi = CommunityPostsApi();
  final SessionManager _session = SessionManager();
  final AccessibilityManager _accessibilityManager = AccessibilityManager();
  
  Profile? _profile;
  List<_Post> _myPosts = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTab = 0; // 0 = Thoughts, 1 = Media

  @override
  void initState() {
    super.initState();
    _accessibilityManager.addListener(_onThemeChanged);
    _loadProfileData();
  }

  @override
  void dispose() {
    _accessibilityManager.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadProfileData() async {
    // Initialize session to load userId from SharedPreferences
    await _session.init();
    
    final userId = _session.userId;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User not logged in';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load profile first
      final profile = await _profilesRepository.getProfile(userId);
      
      // Load user posts from thoughts API (with error handling)
      List<Map<String, dynamic>> thoughtsData = [];
      try {
        thoughtsData = await _profilesRepository.getUserPosts(userId: userId, limit: 50);
        print('[ProfileScreen] Loaded ${thoughtsData.length} thoughts');
      } catch (postsError) {
        print('Warning: Could not load user thoughts: $postsError');
      }

      // Also load community posts and filter by userId
      List<Map<String, dynamic>> communityPostsData = [];
      try {
        final allCommunityPosts = await _communityPostsApi.getV2Posts(limit: 100);
        // Filter community posts by userId
        communityPostsData = allCommunityPosts.where((post) {
          final author = post['author'] as Map<String, dynamic>?;
          final authorId = author?['userId']?.toString() ?? author?['_id']?.toString();
          return authorId == userId;
        }).toList();
        print('[ProfileScreen] Loaded ${communityPostsData.length} community posts for user');
      } catch (communityError) {
        print('Warning: Could not load community posts: $communityError');
      }

      // Combine both thoughts and community posts
      final allPostsData = [...thoughtsData, ...communityPostsData];
      print('[ProfileScreen] Total posts to parse: ${allPostsData.length} (${thoughtsData.length} thoughts + ${communityPostsData.length} community posts)');

      final posts = allPostsData.map((json) {
        try {
          // If author info is missing, inject profile data for current user's posts
          final Map<String, dynamic>? author = json['author'] as Map<String, dynamic>?;
          final Map<String, dynamic>? user = json['user'] as Map<String, dynamic>?;
          final String authorId = (author?['userId'] ?? author?['_id'] ?? user?['userId'] ?? user?['_id'] ?? '').toString();
          
          if (authorId == userId) {
            // This is the current user's post - inject profile data if missing
            if (author != null) {
              if (author['displayName'] == null && profile.displayName.isNotEmpty) {
                author['displayName'] = profile.displayName;
              }
              if (author['imageUrl'] == null && profile.photoUrl != null && profile.photoUrl!.isNotEmpty) {
                author['imageUrl'] = profile.photoUrl;
              }
            } else if (user != null) {
              if (user['displayName'] == null && profile.displayName.isNotEmpty) {
                user['displayName'] = profile.displayName;
              }
              if (user['imageUrl'] == null && profile.photoUrl != null && profile.photoUrl!.isNotEmpty) {
                user['imageUrl'] = profile.photoUrl;
              }
            } else {
              // Create author object if it doesn't exist
              json['author'] = {
                'userId': userId,
                'displayName': profile.displayName,
                'imageUrl': profile.photoUrl,
              };
            }
          }
          
          return _Post.fromJson(json);
        } catch (e) {
          print('[ProfileScreen] Error parsing post: $e, JSON: $json');
          // Return a default post to prevent crashes
          // Try to get userId from the json for error case
          final Map<String, dynamic>? errorAuthor = json['author'] as Map<String, dynamic>?;
          final Map<String, dynamic>? errorUser = json['user'] as Map<String, dynamic>?;
          final String errorAuthorId = (errorAuthor?['userId'] ?? errorAuthor?['_id'] ?? errorUser?['userId'] ?? errorUser?['_id'] ?? userId ?? '').toString();
          
          return _Post(
            userName: errorAuthorId.isNotEmpty ? errorAuthorId : (userId ?? ''),
            text: 'Error loading post',
            avatarUrl: null,
            likes: 0,
            comments: 0,
            createdAt: DateTime.now(),
            contentType: null,
            audioPath: null,
          );
        }
      }).toList();
      
      print('[ProfileScreen] Parsed ${posts.length} posts successfully');

      // Sort posts by creation date (newest first)
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      print('[ProfileScreen] Sorted posts by creation date (newest first)');

      if (mounted) {
        setState(() {
          _profile = profile;
          _myPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = UiUtils.friendlyErrorMessage(e);
        });
      }
    }
  }


  // Separate posts into thoughts and media
  List<_Post> get _thoughts {
    final thoughts = _myPosts.where((post) {
      // Thoughts are text-only posts without images, videos, or audio
      final isMedia = post.imageUrls.isNotEmpty || 
                      (post.videoPath != null && post.videoPath!.isNotEmpty) ||
                      (post.audioPath != null && post.audioPath!.isNotEmpty) ||
                      post.contentType == 'video' ||
                      post.contentType == 'audio';
      return !isMedia && post.text.isNotEmpty;
    }).toList();
    // Ensure sorted by creation date (newest first)
    thoughts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    print('[ProfileScreen] Thoughts count: ${thoughts.length}');
    return thoughts;
  }

  List<_Post> get _media {
    final media = _myPosts.where((post) {
      // Media posts have images, videos, audio, or are audio/video content type
      final hasMedia = post.imageUrls.isNotEmpty || 
                       (post.videoPath != null && post.videoPath!.isNotEmpty) ||
                       (post.audioPath != null && post.audioPath!.isNotEmpty) ||
                       post.contentType == 'video' ||
                       post.contentType == 'audio';
      if (hasMedia) {
        print('[ProfileScreen] Media post found - contentType: ${post.contentType}, images: ${post.imageUrls.length}, video: ${post.videoPath}, audio: ${post.audioPath}');
      }
      return hasMedia;
    }).toList();
    // Ensure sorted by creation date (newest first)
    media.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    print('[ProfileScreen] Media count: ${media.length} out of ${_myPosts.length} total posts');
    return media;
  }

  // Helper method to get colors based on theme
  Color _getTextPrimary() {
    if (_accessibilityManager.isDarkMode) {
      return Colors.white;
    } else if (_accessibilityManager.isWarmMode) {
      return const Color(0xFF4A3A2A); // Warm dark brown
    }
    return AppColors.textPrimary;
  }

  Color _getTextSecondary() {
    if (_accessibilityManager.isDarkMode) {
      return Colors.white.withOpacity(0.7);
    } else if (_accessibilityManager.isWarmMode) {
      return const Color(0xFF6B5A4A); // Medium warm brown
    }
    return AppColors.textSecondary;
  }

  Color _getBackgroundColor() {
    if (_accessibilityManager.isDarkMode) {
      return const Color(0xFF121212);
    } else if (_accessibilityManager.isWarmMode) {
      return const Color(0xFFF5E6D3); // Warm beige
    }
    return AppColors.background;
  }

  Color _getSurfaceColor() {
    if (_accessibilityManager.isDarkMode) {
      return const Color(0xFF1E1E1E);
    } else if (_accessibilityManager.isWarmMode) {
      return const Color(0xFFF9F0E6); // Warm cream
    }
    return AppColors.surface;
  }

  Color _getOutlineColor() {
    if (_accessibilityManager.isDarkMode) {
      return Colors.white.withOpacity(0.1);
    } else if (_accessibilityManager.isWarmMode) {
      return const Color(0xFFD4C4B0); // Warm beige border
    }
    return AppColors.outline;
  }

  // Logout and Delete Account handlers
  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await routerDelegate.logout();
        // Router will automatically rebuild and show login page
        // The ValueNotifier listener ensures notifyListeners() is called when _isAuthenticated changes
      } catch (e) {
        if (mounted) {
          UiUtils.showTopSnackBar(
            context: context,
            message: UiUtils.friendlyErrorMessage(e),
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final userId = _session.userId;
      if (userId == null || userId.isEmpty) {
        UiUtils.showTopSnackBar(
          context: context,
          message: 'User not logged in',
          isError: true,
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await _profilesRepository.deleteAccount(userId);
        await routerDelegate.logout();
        
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          UiUtils.showTopSnackBar(
            context: context,
            message: 'Account deleted successfully',
            isSuccess: true,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          UiUtils.showTopSnackBar(
            context: context,
            message: UiUtils.friendlyErrorMessage(e),
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _accessibilityManager.isDarkMode;
    final isWarm = _accessibilityManager.isWarmMode;
    
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      bottomNavigationBar: AccessibleBottomNav(
        currentIndex: -1, // Profile is not in main navigation
        onTap: (index) {
          // Simply pop back to home screen
          // User can then use the bottom nav from HomeShell to navigate to the desired tab
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        onAddTap: () {
          // Pop back to home, then navigate to community and open composer
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            // After popping, try to find HomeShell and open composer
            // We'll use a post-frame callback to ensure navigation is complete
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Try to find the community screen and open composer
              // Since we can't directly access HomeShell, we'll navigate to community tab
              // The user will need to manually open composer from there, or we can use a different approach
              // For now, just pop back - the user can use the plus button from HomeShell
            });
          }
        },
      ),
      appBar: AppBar(
        backgroundColor: _getSurfaceColor(),
        foregroundColor: _getTextPrimary(),
        title: Text(
          _profile?.displayName ?? 'Profile',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getTextPrimary(),
              ),
        ),
        leading: const SizedBox(),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: _getTextPrimary(),
            ),
            onPressed: () async {
              if (_profile == null) return;
              final result = await Navigator.of(context).push(
                MaterialPageRoute<bool>(
                  builder: (context) => EditProfileScreen(profile: _profile!),
                ),
              );
              if (result == true) {
                _loadProfileData();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? Colors.white70 : AppColors.brand,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: isDark 
                              ? Colors.white70 
                              : (isWarm ? const Color(0xFF6B5A4A) : AppColors.error),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: _getTextPrimary(),
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadProfileData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brand,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfileData,
                  color: AppColors.brand,
                  child: CustomScrollView(
                    slivers: [
                      // Profile Header Section
                      SliverToBoxAdapter(
                        child: _InstagramProfileHeader(
                          profile: _profile,
                          thoughtsCount: _thoughts.length,
                          mediaCount: _media.length,
                          points: _profile?.points ?? 0,
                          isDark: isDark,
                          isWarm: isWarm,
                          getTextPrimary: _getTextPrimary,
                          getTextSecondary: _getTextSecondary,
                          getSurfaceColor: _getSurfaceColor,
                          getOutlineColor: _getOutlineColor,
                          onEdit: () async {
                            if (_profile == null) return;
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute<bool>(
                                builder: (context) => EditProfileScreen(profile: _profile!),
                              ),
                            );
                            if (result == true) {
                            _loadProfileData();
                            }
                          },
                          onLogout: () => _handleLogout(context),
                          onDeleteAccount: () => _handleDeleteAccount(context),
                        ),
                      ),
                      // Tab Bar
                      SliverToBoxAdapter(
                        child: _ProfileTabBar(
                          selectedIndex: _selectedTab,
                          isDark: isDark,
                          isWarm: isWarm,
                          getTextPrimary: _getTextPrimary,
                          getTextSecondary: _getTextSecondary,
                          getOutlineColor: _getOutlineColor,
                          onTabChanged: (index) {
                            setState(() {
                              _selectedTab = index;
                            });
                          },
                        ),
                      ),
                      // Content based on selected tab
                      if (_selectedTab == 0)
                        _thoughts.isEmpty
                            ? SliverFillRemaining(
                                hasScrollBody: false,
                          child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.article_outlined,
                                        size: 64,
                                        color: AppColors.textSecondary.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No thoughts yet',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                                    ],
                                  ),
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final thought = _thoughts[index];
                                    return _ThoughtCard(
                                      thought: thought,
                                      isDark: isDark,
                                      isWarm: isWarm,
                                      getTextPrimary: _getTextPrimary,
                                      getTextSecondary: _getTextSecondary,
                                      getSurfaceColor: _getSurfaceColor,
                                      getOutlineColor: _getOutlineColor,
                                    );
                                  },
                                  childCount: _thoughts.length,
                          ),
                        )
                      else
                        _media.isEmpty
                            ? SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.photo_library_outlined,
                                        size: 64,
                                        color: _getTextSecondary().withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No photos or videos yet',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: _getTextSecondary(),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                sliver: SliverGrid(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 2,
                                    mainAxisSpacing: 2,
                                    childAspectRatio: 1,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final mediaPost = _media[index];
                                      return _MediaGridItem(
                                        post: mediaPost,
                                        isDark: isDark,
                                        isWarm: isWarm,
                                        getTextSecondary: _getTextSecondary,
                                      );
                                    },
                                    childCount: _media.length,
                                  ),
                                ),
                              ),
                    ],
                  ),
                ),
    );
  }
}

// Instagram-style Profile Header
class _InstagramProfileHeader extends StatelessWidget {
  const _InstagramProfileHeader({
    this.profile,
    required this.thoughtsCount,
    required this.mediaCount,
    required this.points,
    required this.isDark,
    required this.isWarm,
    required this.getTextPrimary,
    required this.getTextSecondary,
    required this.getSurfaceColor,
    required this.getOutlineColor,
    required this.onEdit,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  final Profile? profile;
  final int thoughtsCount;
  final int mediaCount;
  final int points;
  final bool isDark;
  final bool isWarm;
  final Color Function() getTextPrimary;
  final Color Function() getTextSecondary;
  final Color Function() getSurfaceColor;
  final Color Function() getOutlineColor;
  final VoidCallback onEdit;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '$apiBaseUrl$url';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = profile?.displayName ?? (profile?.userId ?? '');
    final photoUrl = profile?.photoUrl;
    final fullPhotoUrl = photoUrl != null && photoUrl.isNotEmpty
        ? _getFullImageUrl(photoUrl)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Photo
              CircleAvatar(
                radius: 45,
                backgroundColor: getOutlineColor(),
                backgroundImage: fullPhotoUrl != null
                    ? NetworkImage(fullPhotoUrl)
                    : null,
                child: fullPhotoUrl == null
                    ? Icon(Icons.person_rounded, size: 50, color: getTextSecondary())
                    : null,
              ),
              const SizedBox(width: 20),
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      count: thoughtsCount, 
                      label: 'Thoughts',
                      getTextPrimary: getTextPrimary,
                      getTextSecondary: getTextSecondary,
                    ),
                    _StatItem(
                      count: mediaCount, 
                      label: 'Media',
                      getTextPrimary: getTextPrimary,
                      getTextSecondary: getTextSecondary,
                    ),
                    _StatItem(
                      count: points, 
                      label: 'Points',
                      getTextPrimary: getTextPrimary,
                      getTextSecondary: getTextSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name and Edit Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: getTextPrimary(),
                          ),
                    ),
                    if (points > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$points Respect Points',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: getTextSecondary(),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: getOutlineColor()),
                  ),
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: getTextPrimary(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Logout and Delete Account buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: getOutlineColor()),
                  ),
                  icon: Icon(Icons.logout, color: getTextPrimary()),
                  label: Text(
                    'Logout',
                    style: TextStyle(
                      color: getTextPrimary(),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDeleteAccount,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: AppColors.error),
                  ),
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  label: const Text(
                    'Delete Account',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.count, 
    required this.label,
    required this.getTextPrimary,
    required this.getTextSecondary,
  });

  final int count;
  final String label;
  final Color Function() getTextPrimary;
  final Color Function() getTextSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: getTextPrimary(),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: getTextSecondary(),
              ),
        ),
      ],
    );
  }
}

// Tab Bar for Thoughts/Media
class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({
    required this.selectedIndex,
    required this.isDark,
    required this.isWarm,
    required this.getTextPrimary,
    required this.getTextSecondary,
    required this.getOutlineColor,
    required this.onTabChanged,
  });

  final int selectedIndex;
  final bool isDark;
  final bool isWarm;
  final Color Function() getTextPrimary;
  final Color Function() getTextSecondary;
  final Color Function() getOutlineColor;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: getOutlineColor().withOpacity(0.3)),
          bottom: BorderSide(color: getOutlineColor().withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              icon: Icons.article_outlined,
              selectedIcon: Icons.article,
              label: 'Thoughts',
              isSelected: selectedIndex == 0,
              getTextPrimary: getTextPrimary,
              getTextSecondary: getTextSecondary,
              onTap: () => onTabChanged(0),
            ),
          ),
          Expanded(
            child: _TabButton(
              icon: Icons.grid_on_outlined,
              selectedIcon: Icons.grid_on,
              label: 'Media',
              isSelected: selectedIndex == 1,
              getTextPrimary: getTextPrimary,
              getTextSecondary: getTextSecondary,
              onTap: () => onTabChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.getTextPrimary,
    required this.getTextSecondary,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final Color Function() getTextPrimary;
  final Color Function() getTextSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? getTextPrimary() : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 20,
              color: isSelected ? getTextPrimary() : getTextSecondary(),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected ? getTextPrimary() : getTextSecondary(),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// Thought Card for list view
class _ThoughtCard extends StatelessWidget {
  const _ThoughtCard({
    required this.thought,
    required this.isDark,
    required this.isWarm,
    required this.getTextPrimary,
    required this.getTextSecondary,
    required this.getSurfaceColor,
    required this.getOutlineColor,
  });

  final _Post thought;
  final bool isDark;
  final bool isWarm;
  final Color Function() getTextPrimary;
  final Color Function() getTextSecondary;
  final Color Function() getSurfaceColor;
  final Color Function() getOutlineColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfilePostDetailScreen(
              userName: thought.userName,
              text: thought.text,
              avatarUrl: thought.avatarUrl,
              imageUrls: thought.imageUrls,
              videoPath: thought.videoPath,
              likes: thought.likes,
              comments: thought.comments,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: getSurfaceColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: getOutlineColor().withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              thought.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: getTextPrimary(),
                  ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.favorite_outline, size: 16, color: getTextSecondary()),
                const SizedBox(width: 4),
                Text(
                  '${thought.likes}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: getTextSecondary(),
                      ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.comment_outlined, size: 16, color: getTextSecondary()),
                const SizedBox(width: 4),
                Text(
                  '${thought.comments}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: getTextSecondary(),
                      ),
                ),
                const Spacer(),
                Text(
                  _formatDate(thought.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: getTextSecondary(),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Media Grid Item
class _MediaGridItem extends StatelessWidget {
  const _MediaGridItem({
    required this.post,
    required this.isDark,
    required this.isWarm,
    required this.getTextSecondary,
  });

  final _Post post;
  final bool isDark;
  final bool isWarm;
  final Color Function() getTextSecondary;

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '$apiBaseUrl$url';
  }

  String? _getFullVideoUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '$apiBaseUrl$url';
  }

  @override
  Widget build(BuildContext context) {
    final String? cover = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
    final bool hasVideo = (post.videoPath != null && post.videoPath!.isNotEmpty) || 
                          post.contentType == 'video';
    final bool hasAudio = (post.audioPath != null && post.audioPath!.isNotEmpty) ||
                          post.contentType == 'audio';
    final fullCoverUrl = cover != null ? _getFullImageUrl(cover) : null;
    final fullVideoUrl = hasVideo ? _getFullVideoUrl(post.videoPath) : null;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfilePostDetailScreen(
              userName: post.userName,
              text: post.text,
              avatarUrl: post.avatarUrl,
              imageUrls: post.imageUrls,
              videoPath: post.videoPath,
              likes: post.likes,
              comments: post.comments,
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background - Image, Video thumbnail, or Audio card
          if (fullCoverUrl != null)
            // Show actual image
            Image.network(
              fullCoverUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: (isDark 
                      ? Colors.white.withOpacity(0.1)
                      : (isWarm 
                          ? const Color(0xFFD4C4B0).withOpacity(0.3)
                          : AppColors.outline.withOpacity(0.2))),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / 
                            loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (c, e, s) => Container(
                color: (isDark 
                    ? Colors.white.withOpacity(0.1)
                    : (isWarm 
                        ? const Color(0xFFD4C4B0).withOpacity(0.3)
                        : AppColors.outline.withOpacity(0.2))),
                child: Icon(Icons.broken_image, color: getTextSecondary(), size: 32),
              ),
            )
          else if (hasVideo && fullVideoUrl != null)
            // Video thumbnail
            _VideoThumbnail(videoUrl: fullVideoUrl)
          else if (hasVideo)
            // Video placeholder if no URL
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brand.withOpacity(0.6),
                    AppColors.brandDark.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Video',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            )
          else if (hasAudio)
            // Audio card with nice UI
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brand.withOpacity(0.7),
                    AppColors.brandDark.withOpacity(0.9),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.graphic_eq,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Audio',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
                  if (post.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                        Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        post.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 9,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            // Fallback
            Container(
              color: (isDark 
                  ? Colors.white.withOpacity(0.1)
                  : (isWarm 
                      ? const Color(0xFFD4C4B0).withOpacity(0.3)
                      : AppColors.outline.withOpacity(0.2))),
              child: Icon(Icons.image, size: 32, color: getTextSecondary()),
            ),
          
          // Video play indicator overlay
          if (hasVideo && fullCoverUrl == null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Play',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Audio indicator badge
          if (hasAudio && !hasVideo)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mic,
                  color: AppColors.brand,
                  size: 14,
                ),
              ),
            ),
          
          // Video indicator badge (when image is shown)
          if (hasVideo && fullCoverUrl != null)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          
          // Multiple images indicator
          if (post.imageUrls.length > 1 && fullCoverUrl != null)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.collections,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
                ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.profile, required this.onEdit});

  final Profile? profile;
  final VoidCallback onEdit;

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // If it's a relative path, prepend the base URL
    return '$apiBaseUrl$url';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = profile?.displayName ?? (profile?.userId ?? '');
    final photoUrl = profile?.photoUrl;
    final fullPhotoUrl = photoUrl != null && photoUrl.isNotEmpty
        ? _getFullImageUrl(photoUrl)
        : null;

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.outline,
          backgroundImage: fullPhotoUrl != null
              ? NetworkImage(fullPhotoUrl)
              : null,
          child: fullPhotoUrl == null
              ? const Icon(Icons.person_rounded, size: 56, color: AppColors.textSecondary)
              : null,
        ),
        const SizedBox(height: Spacing.sm),
        Text(displayName, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Spacing.sm),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: onEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text('Edit Profile'),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppColors.brand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Respect Points', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('$points Points', style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('History')),
        ],
      ),
    );
  }
}

class _PostGrid extends StatelessWidget {
  const _PostGrid({required this.posts});

  final List<_Post> posts;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final p = posts[index];
        final String? cover = p.imageUrls.isNotEmpty ? p.imageUrls.first : null;
        final bool hasVideo = p.videoPath != null && p.videoPath!.isNotEmpty;
        final bool hasText = p.text.isNotEmpty;
        final bool hasImage = cover != null;
        
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfilePostDetailScreen(
                  userName: p.userName,
                  text: p.text,
                  avatarUrl: p.avatarUrl,
                  imageUrls: p.imageUrls,
                  videoPath: p.videoPath,
                  likes: p.likes,
                  comments: p.comments,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background - image, video thumbnail, or text placeholder
                if (hasImage)
                  Image.network(
                    cover!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: AppColors.outline.withOpacity(0.2)),
                  )
                else if (hasVideo)
                  Container(
                    color: AppColors.brand.withOpacity(0.3),
                    child: const Icon(Icons.videocam, size: 32, color: AppColors.brand),
                  )
                else
                  Container(
                    color: AppColors.outline.withOpacity(0.2),
                    padding: const EdgeInsets.all(8),
                    child: hasText
                        ? Text(
                            p.text,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                            textAlign: TextAlign.center,
                          )
                        : const Icon(Icons.text_fields, size: 24, color: AppColors.textSecondary),
                  ),
                // Video indicator
                if (hasVideo)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                // Audio indicator (for audio thoughts)
                if (!hasVideo && !hasImage && !hasText)
                  const Align(
                    alignment: Alignment.center,
                    child: Icon(Icons.mic, size: 24, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Detail page for a single profile post
class ProfilePostDetailScreen extends StatelessWidget {
  const ProfilePostDetailScreen({
    super.key,
    required this.userName,
    required this.text,
    this.avatarUrl,
    required this.imageUrls,
    required this.videoPath,
    required this.likes,
    required this.comments,
  });

  final String userName;
  final String text;
  final String? avatarUrl;
  final List<String> imageUrls;
  final String? videoPath;
  final int likes;
  final int comments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          CommunityPostCard(
            userName: userName,
            text: text,
            avatar: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            imageUrls: imageUrls,
            videoPath: videoPath,
            likes: likes,
            comments: comments,
          ),
        ],
      ),
    );
  }
}

class _Post {
  _Post({
    required this.userName,
    required this.text,
    this.avatarUrl,
    this.imageUrls = const [],
    this.videoPath,
    this.audioPath,
    required this.likes,
    required this.comments,
    required this.createdAt,
    this.contentType,
  });

  final String userName;
  final String text;
  final String? avatarUrl;
  final List<String> imageUrls;
  final String? videoPath;
  final String? audioPath; // For audio files
  final int likes;
  final int comments;
  final DateTime createdAt;
  final String? contentType; // 'text', 'audio', 'video'

  factory _Post.fromJson(Map<String, dynamic> json) {
    // Handle thoughts structure (from getThoughts API)
    final content = json['content'] as Map<String, dynamic>?;
    final contentType = json['contentType'] as String?;
    final thoughtId = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    
    // Get text content - check content.text first (thoughts structure), then fallback
    final text = content?['text'] as String? ?? 
                 json['text'] as String? ?? 
                 json['transcript'] as String? ?? 
                 '';

    // Get user name and avatar
    final Map<String, dynamic>? author = json['author'] as Map<String, dynamic>?;
    final Map<String, dynamic>? user = json['user'] as Map<String, dynamic>?;
    final String authorId = (author?['userId'] ?? author?['_id'] ?? user?['userId'] ?? user?['_id'] ?? '').toString();
    
    // Try to get displayName from various sources
    String? displayName = json['userName'] as String? ?? 
                         user?['displayName'] as String? ?? 
                         author?['displayName'] as String?;
    
    // If still null and we have authorId, check if it's the current user (use session)
    if (displayName == null && authorId.isNotEmpty) {
      // Note: We can't access session here, but the profile screen will handle this
      // by using the profile data it already loaded for the current user
      displayName = authorId; // Fallback to userId
    }
    
    // Always use userId if displayName is not available (never show default names)
    final String userName = displayName ?? authorId;
    final String? authorPhotoUrl = author?['imageUrl'] ?? author?['photoUrl'] ?? author?['avatarUrl'] ?? 
                                   user?['imageUrl'] ?? user?['photoUrl'] ?? user?['avatarUrl'];

    // Handle images - check community posts format FIRST (media array), then other formats
    final imageUrls = <String>[];
    String? videoPath;
    String? audioPath;
    String? detectedContentType = contentType;
    
    // Check for community posts format: media array with type and streamUrl
    final dynamic mediaList = json['media'];
    if (mediaList is List) {
      print('[ProfileScreen] Found media array with ${mediaList.length} items');
      for (final dynamic m in mediaList) {
        if (m is! Map<String, dynamic>) continue;
        final String type = (m['type'] ?? '').toString().toLowerCase();
        final String streamPath = (m['streamUrl'] ?? '').toString();
        print('[ProfileScreen] Media item - type: $type, streamUrl: $streamPath');
        if (streamPath.isEmpty) continue;
        
        // Build full URL if it's relative
        final String url = (streamPath.startsWith('http://') || streamPath.startsWith('https://'))
            ? streamPath
            : '$apiBaseUrl$streamPath';
        
        if (type == 'image') {
          imageUrls.add(url);
          print('[ProfileScreen] Added image URL: $url');
        } else if (type == 'video') {
          videoPath = url;
          if (detectedContentType == null) detectedContentType = 'video';
          print('[ProfileScreen] Added video URL: $url');
        } else if (type == 'audio') {
          audioPath = url;
          if (detectedContentType == null) detectedContentType = 'audio';
          print('[ProfileScreen] Added audio URL: $url');
        }
      }
      print('[ProfileScreen] Total images found: ${imageUrls.length}');
    } else {
      print('[ProfileScreen] No media array found or media is not a list. Type: ${mediaList.runtimeType}');
    }
    
    // If no media array found, check other formats
    if (imageUrls.isEmpty) {
    if (json['imageUrls'] is List) {
      imageUrls.addAll((json['imageUrls'] as List).cast<String>());
    } else if (json['images'] is List) {
      imageUrls.addAll((json['images'] as List).cast<String>());
    } else if (json['media'] != null && json['media'] is Map) {
      final media = json['media'] as Map<String, dynamic>;
      if (media['images'] is List) {
        imageUrls.addAll((media['images'] as List).cast<String>());
        }
      }
    }

    // Handle video/audio - check thoughts structure if not already set
    if (videoPath == null && audioPath == null) {
      String? mediaUrl = content?['mediaUrl'] as String?;
      
      if (contentType == 'video' || contentType == 'audio') {
        // For thoughts, build the stream URL if we have a thoughtId
        if (thoughtId.isNotEmpty) {
          // Build full URL for media stream
          if (mediaUrl != null && mediaUrl.isNotEmpty) {
            if (mediaUrl.startsWith('http://') || mediaUrl.startsWith('https://')) {
              if (contentType == 'video') {
                videoPath = mediaUrl;
              } else {
                audioPath = mediaUrl;
              }
            } else {
              // Relative path, construct full URL
              final streamUrl = '$apiBaseUrl/api/v1/media/by-thought/$thoughtId/stream';
              if (contentType == 'video') {
                videoPath = streamUrl;
              } else {
                audioPath = streamUrl;
              }
            }
          } else {
            // No mediaUrl, but it's a video/audio thought, construct stream URL
            final streamUrl = '$apiBaseUrl/api/v1/media/by-thought/$thoughtId/stream';
            if (contentType == 'video') {
              videoPath = streamUrl;
            } else {
              audioPath = streamUrl;
            }
          }
        }
      } else {
        // Handle other video formats
    if (json['videoPath'] != null) {
      videoPath = json['videoPath'] as String?;
    } else if (json['video'] != null) {
      videoPath = json['video'] is String ? json['video'] as String : null;
    } else if (json['media'] != null && json['media'] is Map) {
      final media = json['media'] as Map<String, dynamic>;
      if (media['video'] != null) {
        videoPath = media['video'] is String ? media['video'] as String : null;
          }
        }
      }
    }
    
    // If we have audioPath but no contentType, set it
    if (audioPath != null && detectedContentType == null) {
      detectedContentType = 'audio';
    }

    // Get likes and comments counts (thoughts might not have these, default to 0)
    final likes = json['likes'] ?? 
                  json['likesCount'] ?? 
                  json['reactionsCount'] ?? 
                  0;
    final comments = json['comments'] ?? 
                     json['commentsCount'] ?? 
                     0;

    // Parse createdAt
    DateTime? createdAt;
    if (json['createdAt'] != null) {
      createdAt = DateTime.tryParse(json['createdAt'].toString());
    }
    createdAt ??= DateTime.now();

    // Build full avatar URL if available
    String? avatarUrl;
    if (authorPhotoUrl != null && authorPhotoUrl.isNotEmpty) {
      avatarUrl = (authorPhotoUrl.startsWith('http://') || authorPhotoUrl.startsWith('https://'))
          ? authorPhotoUrl
          : '$apiBaseUrl$authorPhotoUrl';
    }
    
    final post = _Post(
      userName: userName.toString(),
      text: text.toString(),
      avatarUrl: avatarUrl,
      imageUrls: imageUrls,
      videoPath: videoPath,
      audioPath: audioPath,
      likes: (likes is int) ? likes : int.tryParse(likes.toString()) ?? 0,
      comments: (comments is int) ? comments : int.tryParse(comments.toString()) ?? 0,
      createdAt: createdAt,
      contentType: detectedContentType ?? contentType,
    );
    
    // Debug logging
    final finalContentType = detectedContentType ?? contentType;
    print('[ProfileScreen] Parsed post - userName: $userName, text: ${text.length} chars, imageUrls: ${imageUrls.length}, videoPath: ${videoPath != null ? "yes" : "no"}, audioPath: ${audioPath != null ? "yes" : "no"}, contentType: $finalContentType');
    if (imageUrls.isNotEmpty) {
      print('[ProfileScreen] Image URLs: $imageUrls');
    }
    
    return post;
  }
}

// Video Thumbnail Widget
class _VideoThumbnail extends StatefulWidget {
  const _VideoThumbnail({required this.videoUrl});

  final String videoUrl;

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeThumbnail();
  }

  Future<void> _initializeThumbnail() async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await controller.initialize();
      // Seek to first frame
      await controller.seekTo(Duration.zero);
      // Pause immediately
      await controller.pause();
      
      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('[VideoThumbnail] Error loading thumbnail: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.brand.withOpacity(0.4),
              AppColors.brandDark.withOpacity(0.6),
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_hasError || _controller == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.brand.withOpacity(0.6),
              AppColors.brandDark.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Video',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video thumbnail frame
        VideoPlayer(_controller!),
        // Dark overlay for better play button visibility
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


