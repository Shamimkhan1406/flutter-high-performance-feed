class PostModel {
  final String id;
  final DateTime createdAt;

  final String mediaThumbUrl;
  final String mediaMobileUrl;
  final String mediaRawUrl;

  final int likeCount;

  final bool isLiked;

  const PostModel({
    required this.id,
    required this.createdAt,
    required this.mediaThumbUrl,
    required this.mediaMobileUrl,
    required this.mediaRawUrl,
    required this.likeCount,
    required this.isLiked,
  });

  factory PostModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return PostModel(
      id: map['id'] as String,

      createdAt: DateTime.parse(
        map['created_at'],
      ),

      mediaThumbUrl:
          map['media_thumb_url'] ?? '',

      mediaMobileUrl:
          map['media_mobile_url'] ?? '',

      mediaRawUrl:
          map['media_raw_url'] ?? '',

      likeCount:
          map['like_count'] ?? 0,

      isLiked:
          map['is_liked'] ?? false,
    );
  }

  PostModel copyWith({
    String? id,
    DateTime? createdAt,
    String? mediaThumbUrl,
    String? mediaMobileUrl,
    String? mediaRawUrl,
    int? likeCount,
    bool? isLiked,
  }) {
    return PostModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      mediaThumbUrl:
          mediaThumbUrl ?? this.mediaThumbUrl,
      mediaMobileUrl:
          mediaMobileUrl ?? this.mediaMobileUrl,
      mediaRawUrl:
          mediaRawUrl ?? this.mediaRawUrl,
      likeCount:
          likeCount ?? this.likeCount,
      isLiked:
          isLiked ?? this.isLiked,
    );
  }
}