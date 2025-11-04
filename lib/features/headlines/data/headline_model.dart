class Headline {
  const Headline({
    required this.id,
    required this.title,
    required this.source,
    this.summary,
    this.url,
    this.imageUrl,
    this.contentHtml,
    this.category,
    this.categories,
    this.publishedAt,
    this.language,
  });

  final String id;
  final String title;
  final String? summary;
  final String source; // newspaper name
  final String? url;
  final String? imageUrl;
  final String? contentHtml;
  final String? category;
  final List<String>? categories;
  final DateTime? publishedAt;
  final String? language;

  factory Headline.fromJson(Map<String, dynamic> json) {
    return Headline(
      id: json['_id']?.toString() ?? json['id'].toString(),
      title: json['title'] as String,
      summary: json['summary'] as String?,
      source: json['source'] as String,
      url: json['url'] as String?,
      imageUrl: json['imageUrl'] as String?,
      contentHtml: json['contentHtml'] as String?,
      category: json['category'] as String?,
      categories: json['categories'] != null
          ? List<String>.from(json['categories'] as List)
          : null,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      language: json['language'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'source': source,
        'url': url,
        'imageUrl': imageUrl,
        'contentHtml': contentHtml,
        'category': category,
        'categories': categories,
        'publishedAt': publishedAt?.toIso8601String(),
        'language': language,
      };
}


