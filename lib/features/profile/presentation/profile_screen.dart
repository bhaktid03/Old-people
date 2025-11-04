import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../widgets/community_post_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<_Post> _myPosts = [
    _Post(
      userName: 'You',
      text: 'Enjoyed the park with friends today 🌳',
      imageUrls: const [
        'https://images.unsplash.com/photo-1445979323117-80453f573b71',
      ],
      likes: 18,
      comments: 5,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    _Post(
      userName: 'You',
      text: 'Shared a favorite recipe 😊',
      imageUrls: const [
        'https://images.unsplash.com/photo-1461354464878-ad92f492a5a0',
      ],
      likes: 6,
      comments: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        leading: const SizedBox(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ProfileHeader(onEdit: () {}),
          ),
          const SizedBox(height: Spacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _StatCard(points: 100),
          ),
          const SizedBox(height: Spacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _PostGrid(posts: _myPosts),
          ),
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.outline,
          child: Icon(Icons.person_rounded, size: 56, color: AppColors.textSecondary),
        ),
        const SizedBox(height: Spacing.sm),
        Text('User Name', style: Theme.of(context).textTheme.titleMedium),
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
        final String? cover = p.videoThumbnailUrl ?? (p.imageUrls.isNotEmpty ? p.imageUrls.first : null);
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfilePostDetailScreen(
                  userName: p.userName,
                  text: p.text,
                  imageUrls: p.imageUrls,
                  videoThumbnailUrl: p.videoThumbnailUrl,
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
                if (cover != null)
                  Image.network(
                    cover,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: AppColors.outline.withOpacity(0.2)),
                  )
                else
                  Container(color: AppColors.outline.withOpacity(0.2)),
                if (p.videoThumbnailUrl != null)
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
    required this.imageUrls,
    required this.videoThumbnailUrl,
    required this.likes,
    required this.comments,
  });

  final String userName;
  final String text;
  final List<String> imageUrls;
  final String? videoThumbnailUrl;
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
            imageUrls: imageUrls,
            videoThumbnailUrl: videoThumbnailUrl,
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
}


