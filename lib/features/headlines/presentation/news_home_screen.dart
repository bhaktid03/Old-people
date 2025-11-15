import 'package:flutter/material.dart';
import '../data/headline_model.dart';
import '../data/api_headlines_repository.dart';
import '../data/headlines_repository.dart';
import 'news_detail_screen.dart';
import '../../../core/accessibility/accessibility_manager.dart';
import '../../../core/session/session_manager.dart';
import '../../../api/profiles/profiles_repository.dart';
import '../../../api/profiles/models/profile.dart';
import '../../../api/common/endpoints.dart';
import '../../../app/theme/colors.dart';
import '../../profile/presentation/profile_screen.dart';

class NewsHomeScreen extends StatefulWidget {
  const NewsHomeScreen({super.key});

  @override
  State<NewsHomeScreen> createState() => _NewsHomeScreenState();
}

class _NewsHomeScreenState extends State<NewsHomeScreen> {
  final HeadlinesRepository _repository = ApiHeadlinesRepository();
  final AccessibilityManager _accessibilityManager = AccessibilityManager();
  final SessionManager _session = SessionManager();
  final ProfilesRepository _profilesRepository = ProfilesRepository();
  
  List<Headline> _headlines = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedSource;
  int _limit = 20;
  Profile? _userProfile;
  bool _isLoadingProfile = true;

  // Available news sources based on API
  final List<Map<String, String?>> _newsSources = [
    {'value': null, 'label': 'All Sources'},
    {'value': 'indian_express', 'label': 'Indian Express'},
    {'value': 'bbc_hindi', 'label': 'BBC Hindi'},
    {'value': 'ndtv', 'label': 'NDTV'},
    {'value': 'toi', 'label': 'Times of India'},
    {'value': 'the_hindu', 'label': 'The Hindu'},
  ];

  @override
  void initState() {
    super.initState();
    _accessibilityManager.addListener(_onAccessibilityChanged);
    _loadProfile();
    _loadHeadlines();
  }

  @override
  void dispose() {
    _accessibilityManager.removeListener(_onAccessibilityChanged);
    super.dispose();
  }

  void _onAccessibilityChanged() {
    setState(() {});
  }

  Future<void> _loadProfile() async {
    try {
      await _session.init();
      final userId = _session.userId;
      if (userId != null) {
        final profile = await _profilesRepository.getProfile(userId);
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _isLoadingProfile = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingProfile = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _loadHeadlines() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final headlines = await _repository.getHeadlines(
        source: _selectedSource,
        limit: _limit,
      );
      setState(() {
        _headlines = headlines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load news: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '$apiBaseUrl$url';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _accessibilityManager.isDarkMode;
    final isWarm = _accessibilityManager.isWarmMode;
    
    // Get background color based on theme
    Color backgroundColor;
    if (isDark) {
      backgroundColor = const Color(0xFF121212);
    } else if (isWarm) {
      backgroundColor = const Color(0xFFF5E6D3); // Warm beige
    } else {
      backgroundColor = AppColors.background;
    }
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Profile and Accessibility Controls
            _buildTopBar(isDark, isWarm),
            
            // Source Filter (Simplified for elderly users)
            _buildSourceFilter(isDark, isWarm),
            
            // News Content
            Expanded(
              child: _buildContent(isDark, isWarm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark, bool isWarm) {
    final photoUrl = _userProfile?.photoUrl;
    final fullPhotoUrl = photoUrl != null && photoUrl.isNotEmpty
        ? _getFullImageUrl(photoUrl)
        : null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Circle at Left - Clickable to navigate to profile
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.brand.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.outline.withOpacity(0.3),
              backgroundImage: fullPhotoUrl != null
                  ? NetworkImage(fullPhotoUrl)
                  : null,
              child: fullPhotoUrl == null
                  ? Icon(
                      Icons.person,
                      size: 28,
                      color: isDark 
                      ? Colors.white70 
                      : (isWarm ? const Color(0xFF6B5A4A) : AppColors.textSecondary),
                    )
                  : null,
              ),
            ),
          ),
          
          // App Name Heading
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              'Chaupal',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark 
                    ? Colors.white 
                    : (isWarm ? const Color(0xFF4A3A2A) : AppColors.textPrimary),
                height: 1.2,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Accessibility Controls at Right
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Font Size Decrease Button
              IconButton(
                onPressed: _accessibilityManager.currentFontScaleIndex > 0
                    ? () {
                        _accessibilityManager.decreaseFontSize();
                      }
                    : null,
                icon: Icon(
                  Icons.text_decrease,
                  size: 20,
                  color: isDark 
                      ? Colors.white70 
                      : (isWarm ? const Color(0xFF4A3A2A) : AppColors.textPrimary),
                ),
                tooltip: 'Decrease font size',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              
              // Font Size Label
              Container(
                constraints: const BoxConstraints(maxWidth: 50),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1)
                      : AppColors.outline.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _accessibilityManager.fontScaleLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark 
                        ? Colors.white 
                        : (isWarm ? const Color(0xFF4A3A2A) : AppColors.textPrimary),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Font Size Increase Button
              IconButton(
                onPressed: _accessibilityManager.currentFontScaleIndex < 
                    _accessibilityManager.maxFontScaleIndex
                    ? () {
                        _accessibilityManager.increaseFontSize();
                      }
                    : null,
                icon: Icon(
                  Icons.text_increase,
                  size: 20,
                  color: isDark 
                      ? Colors.white70 
                      : (isWarm ? const Color(0xFF4A3A2A) : AppColors.textPrimary),
                ),
                tooltip: 'Increase font size',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              
              const SizedBox(width: 2),
              
              // Theme Mode Toggle (Light -> Warm -> Dark -> Light)
              IconButton(
                onPressed: () {
                  _accessibilityManager.toggleThemeMode();
                },
                icon: Icon(
                  _accessibilityManager.themeModeIcon,
                  size: 20,
                  color: isDark 
                      ? Colors.white70 
                      : (_accessibilityManager.isWarmMode 
                          ? const Color(0xFF6B5A4A) 
                          : AppColors.textPrimary),
                ),
                tooltip: 'Switch theme (${_accessibilityManager.themeModeLabel})',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceFilter(bool isDark, bool isWarm) {
    // Get filter bar color based on theme
    Color filterBarColor;
    if (isDark) {
      filterBarColor = const Color(0xFF1E1E1E);
    } else if (isWarm) {
      filterBarColor = const Color(0xFFF9F0E6); // Warm cream
    } else {
      filterBarColor = AppColors.surface;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: (16 * _accessibilityManager.fontScale).clamp(14.0, 20.0),
      ),
      decoration: BoxDecoration(
        color: filterBarColor,
        border: Border(
          bottom: BorderSide(
            color: isDark 
                ? Colors.white.withOpacity(0.1)
                : (isWarm 
                    ? const Color(0xFFD4C4B0).withOpacity(0.5)
                    : AppColors.outline.withOpacity(0.3)),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top divider line
          Container(
            height: 1,
            color: isDark 
                ? Colors.white.withOpacity(0.1)
                : (isWarm 
                    ? const Color(0xFFD4C4B0).withOpacity(0.5)
                    : AppColors.outline.withOpacity(0.3)),
            margin: const EdgeInsets.only(bottom: 12),
          ),
          // Label
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.newspaper_rounded,
                  size: (22 * _accessibilityManager.fontScale).clamp(20.0, 26.0),
                  color: isDark 
                      ? Colors.white70 
                      : (isWarm ? const Color(0xFF6B5A4A) : AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
                Text(
                  'Choose News Source:',
                  style: TextStyle(
                    fontSize: (18 * _accessibilityManager.fontScale).clamp(16.0, 22.0),
                    fontWeight: FontWeight.w700,
                    color: isDark 
                        ? Colors.white 
                        : (isWarm ? const Color(0xFF4A3A2A) : AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          // Divider line below label
          Container(
            height: 1,
            color: isDark 
                ? Colors.white.withOpacity(0.1)
                : (isWarm 
                    ? const Color(0xFFD4C4B0).withOpacity(0.5)
                    : AppColors.outline.withOpacity(0.3)),
            margin: const EdgeInsets.only(bottom: 12),
          ),
          // Horizontal scrollable buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _newsSources.map((source) {
                final isSelected = _selectedSource == source['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _SourceButton(
                    label: source['label']!,
                    isSelected: isSelected,
                    isDark: isDark,
                    isWarm: isWarm,
                    fontScale: _accessibilityManager.fontScale,
                    onTap: () {
                      setState(() {
                        _selectedSource = source['value'];
                      });
                      _loadHeadlines();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          // Bottom divider line
          Container(
            height: 1,
            color: isDark 
                ? Colors.white.withOpacity(0.1)
                : (isWarm 
                    ? const Color(0xFFD4C4B0).withOpacity(0.5)
                    : AppColors.outline.withOpacity(0.3)),
            margin: const EdgeInsets.only(top: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, bool isWarm) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? Colors.white70 : AppColors.brand,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64 * _accessibilityManager.fontScale,
                color: isDark ? Colors.white70 : AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 18 * _accessibilityManager.fontScale,
                  color: isDark 
                      ? Colors.white70 
                      : (isWarm ? const Color(0xFF4A3A2A) : AppColors.textPrimary),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadHeadlines,
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 18 * _accessibilityManager.fontScale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16 * _accessibilityManager.fontScale,
                  ),
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_headlines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64 * _accessibilityManager.fontScale,
              color: isDark 
                  ? Colors.white.withOpacity(0.5)
                  : AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No news articles found',
              style: TextStyle(
                fontSize: 20 * _accessibilityManager.fontScale,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different source',
              style: TextStyle(
                fontSize: 18 * _accessibilityManager.fontScale,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHeadlines,
      color: AppColors.brand,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _headlines.length,
        itemBuilder: (context, index) {
          final headline = _headlines[index];
          return _NewspaperStyleCard(
            headline: headline,
            isDark: isDark,
            isWarm: isWarm,
            fontScale: _accessibilityManager.fontScale,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewsDetailScreen(headline: headline),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NewspaperStyleCard extends StatelessWidget {
  const _NewspaperStyleCard({
    required this.headline,
    required this.isDark,
    required this.isWarm,
    required this.fontScale,
    required this.onTap,
  });

  final Headline headline;
  final bool isDark;
  final bool isWarm;
  final double fontScale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Get card color based on theme
    Color cardColor;
    if (isDark) {
      cardColor = const Color(0xFF1E1E1E);
    } else if (isWarm) {
      cardColor = const Color(0xFFF9F0E6); // Warm cream
    } else {
      cardColor = AppColors.surface;
    }
    
    // Get border color based on theme
    Color borderColor;
    if (isDark) {
      borderColor = Colors.white.withOpacity(0.1);
    } else if (isWarm) {
      borderColor = const Color(0xFFD4C4B0); // Warm beige border
    } else {
      borderColor = AppColors.outline.withOpacity(0.5);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image if available - cap height to prevent overflow
            if (headline.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Image.network(
                  headline.imageUrl!,
                  height: (220 * fontScale).clamp(200.0, 280.0),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: (220 * fontScale).clamp(200.0, 280.0),
                      color: isDark 
                          ? Colors.white.withOpacity(0.1)
                          : (isWarm 
                              ? const Color(0xFFD4C4B0).withOpacity(0.3)
                              : AppColors.outline.withOpacity(0.2)),
                      child: Icon(
                        Icons.image_not_supported,
                        size: (48 * fontScale).clamp(40.0, 60.0),
                        color: isDark 
                            ? Colors.white60 
                            : (isWarm ? const Color(0xFF6B5A4A) : AppColors.textSecondary),
                      ),
                    );
                  },
                ),
              ),
            
            Padding(
              padding: EdgeInsets.all((20 * fontScale).clamp(16.0, 28.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: (12 * fontScale).clamp(10.0, 16.0),
                      vertical: (6 * fontScale).clamp(5.0, 8.0),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.brand,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.newspaper_rounded,
                          size: (18 * fontScale).clamp(16.0, 22.0),
                          color: AppColors.brand,
                        ),
                        SizedBox(width: (6 * fontScale).clamp(5.0, 8.0)),
                        Flexible(
                          child: Text(
                            headline.source.toUpperCase(),
                            style: TextStyle(
                              fontSize: (14 * fontScale).clamp(12.0, 18.0),
                              fontWeight: FontWeight.w700,
                              color: AppColors.brand,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: (16 * fontScale).clamp(12.0, 20.0)),
                  
                  // Bold Newspaper-Style Heading
                  Text(
                    headline.title,
                    style: TextStyle(
                      fontSize: (24 * fontScale).clamp(20.0, 36.0),
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      color: isDark 
                        ? Colors.white 
                        : (isWarm ? const Color(0xFF4A3A2A) : AppColors.textPrimary),
                      letterSpacing: -0.5,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Summary if available
                  if (headline.summary != null && headline.summary!.isNotEmpty) ...[
                    SizedBox(height: (12 * fontScale).clamp(10.0, 16.0)),
                    Text(
                      headline.summary!,
                      style: TextStyle(
                        fontSize: (18 * fontScale).clamp(16.0, 26.0),
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                            color: isDark 
                                ? Colors.white.withOpacity(0.8)
                                : (isWarm ? const Color(0xFF6B5A4A) : AppColors.textSecondary),
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  SizedBox(height: (16 * fontScale).clamp(12.0, 20.0)),
                  
                  // Metadata Row
                  Row(
                    children: [
                      if (headline.category != null) ...[
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: (10 * fontScale).clamp(8.0, 14.0),
                              vertical: (4 * fontScale).clamp(3.0, 6.0),
                            ),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.1)
                                  : (isWarm 
                                      ? const Color(0xFFD4C4B0).withOpacity(0.3)
                                      : AppColors.outline.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              headline.category!,
                              style: TextStyle(
                                fontSize: (14 * fontScale).clamp(12.0, 18.0),
                                fontWeight: FontWeight.w600,
                                color: isDark 
                      ? Colors.white70 
                      : (isWarm ? const Color(0xFF4A3A2A) : AppColors.textPrimary),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(width: (12 * fontScale).clamp(8.0, 16.0)),
                      ],
                      if (headline.publishedAt != null) ...[
                        Icon(
                          Icons.access_time,
                          size: (16 * fontScale).clamp(14.0, 20.0),
                          color: isDark 
                              ? Colors.white.withOpacity(0.6)
                              : (isWarm ? const Color(0xFF6B5A4A).withOpacity(0.7) : AppColors.textMuted),
                        ),
                        SizedBox(width: (4 * fontScale).clamp(3.0, 6.0)),
                        Flexible(
                          child: Text(
                            _formatDate(headline.publishedAt!),
                            style: TextStyle(
                              fontSize: (14 * fontScale).clamp(12.0, 18.0),
                              color: isDark 
                                  ? Colors.white.withOpacity(0.6)
                                  : (isWarm ? const Color(0xFF6B5A4A).withOpacity(0.7) : AppColors.textMuted),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: (18 * fontScale).clamp(16.0, 22.0),
                        color: AppColors.brand,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.isWarm,
    required this.fontScale,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final bool isWarm;
  final double fontScale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Selected button styling
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    
    if (isSelected) {
      backgroundColor = AppColors.brand;
      textColor = Colors.white;
      borderColor = AppColors.brand;
    } else {
      if (isDark) {
        backgroundColor = Colors.white.withOpacity(0.1);
        textColor = Colors.white70;
        borderColor = Colors.white.withOpacity(0.2);
      } else if (isWarm) {
        backgroundColor = const Color(0xFFE8D9C4).withOpacity(0.5);
        textColor = const Color(0xFF4A3A2A);
        borderColor = const Color(0xFFD4C4B0);
      } else {
        backgroundColor = AppColors.outline.withOpacity(0.1);
        textColor = AppColors.textPrimary;
        borderColor = AppColors.outline.withOpacity(0.3);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: (20 * fontScale).clamp(18.0, 26.0),
          vertical: (14 * fontScale).clamp(12.0, 18.0),
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.5 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brand.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: (17 * fontScale).clamp(15.0, 21.0),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: textColor,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
