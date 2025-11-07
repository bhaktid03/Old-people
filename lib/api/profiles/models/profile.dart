class Profile {
  Profile({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.points = 0,
    this.createdAt,
  });

  final String userId;
  final String displayName;
  final String? photoUrl;
  final int points;
  final DateTime? createdAt;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['userId'] ?? json['_id'] ?? json['id'] ?? '',
      displayName: json['displayName'] ?? json['name'] ?? '',
      // Backend uses 'imageUrl', but we also support 'photoUrl' for compatibility
      photoUrl: json['imageUrl'] ?? json['photoUrl'] ?? json['avatarUrl'] ?? json['photo'],
      points: json['points'] ?? json['respectPoints'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'points': points,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  Profile copyWith({
    String? userId,
    String? displayName,
    String? photoUrl,
    int? points,
    DateTime? createdAt,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

