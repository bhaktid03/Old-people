class Headline {
  const Headline({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    this.url,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String summary;
  final String source; // newspaper name
  final String? url;
  final DateTime? publishedAt;

  factory Headline.fromJson(Map<String, dynamic> json) {
    return Headline(
      id: json['_id']?.toString() ?? json['id'].toString(),
      title: json['title'] as String,
      summary: json['summary'] as String,
      source: json['source'] as String,
      url: json['url'] as String?,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'source': source,
        'url': url,
        'publishedAt': publishedAt?.toIso8601String(),
      };
}


