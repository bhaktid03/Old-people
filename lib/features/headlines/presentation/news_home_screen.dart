import 'package:flutter/material.dart';
import '../data/headline_model.dart';
import '../data/api_headlines_repository.dart';
import '../data/headlines_repository.dart';
import 'news_detail_screen.dart';

class NewsHomeScreen extends StatefulWidget {
  const NewsHomeScreen({super.key});

  @override
  State<NewsHomeScreen> createState() => _NewsHomeScreenState();
}

class _NewsHomeScreenState extends State<NewsHomeScreen> {
  final HeadlinesRepository _repository = ApiHeadlinesRepository();
  List<Headline> _headlines = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedSource;
  int _limit = 20;

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
    _loadHeadlines();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
      ),
      body: Column(
        children: [
          // Source dropdown filter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
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
                const Icon(Icons.filter_list_rounded),
                const SizedBox(width: 12),
                const Text(
                  'Source:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String?>(
                    value: _selectedSource,
                    isExpanded: true,
                    hint: const Text('Select Source'),
                    items: _newsSources.map((source) {
                      return DropdownMenuItem<String?>(
                        value: source['value'],
                        child: Text(source['label']!),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSource = newValue;
                      });
                      _loadHeadlines();
                    },
                  ),
                ),
              ],
            ),
          ),
          // News list or loading/error state
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadHeadlines,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
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
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No news articles found',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different source',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHeadlines,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _headlines.length,
        itemBuilder: (context, index) {
          final headline = _headlines[index];
          return _NewsCard(
            headline: headline,
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

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.headline,
    required this.onTap,
  });

  final Headline headline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image if available
              if (headline.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    headline.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              if (headline.imageUrl != null) const SizedBox(height: 12),
              // Title
              Text(
                headline.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Summary if available
              if (headline.summary != null && headline.summary!.isNotEmpty)
                Text(
                  headline.summary!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              if (headline.summary != null && headline.summary!.isNotEmpty)
                const SizedBox(height: 8),
              // Source and metadata
              Row(
                children: [
                  Icon(
                    Icons.newspaper_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    headline.source,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                  if (headline.category != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.category_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      headline.category!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ],
              ),
              if (headline.publishedAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(headline.publishedAt!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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

