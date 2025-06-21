class FavoriteItem {
  final int? id;
  final String type; // 'book', 'podcast', 'space'
  final String title;
  final String imageUrl;
  final DateTime createdAt;
  final Map<String, dynamic> data; // Store specific data for each type

  FavoriteItem({
    this.id,
    required this.type,
    required this.title,
    required this.imageUrl,
    required this.createdAt,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'image_url': imageUrl,
      'created_at': createdAt.millisecondsSinceEpoch,
      'data': data,
    };
  }

  factory FavoriteItem.fromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      id: map['id'],
      type: map['type'],
      title: map['title'],
      imageUrl: map['image_url'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      data: Map<String, dynamic>.from(map['data']),
    );
  }
}

// Book-specific favorite
class FavoriteBook extends FavoriteItem {
  FavoriteBook({
    int? id,
    required String title,
    required String imageUrl,
    required String author,
    required String about,
    required List<String> subjects,
    required String key,
    DateTime? createdAt,
  }) : super(
          id: id,
          type: 'book',
          title: title,
          imageUrl: imageUrl,
          createdAt: createdAt ?? DateTime.now(),
          data: {
            'author': author,
            'about': about,
            'subjects': subjects,
            'key': key,
          },
        );

  String get author => data['author'] as String;
  String get about => data['about'] as String;
  List<String> get subjects => List<String>.from(data['subjects'] as List);
  String get key => data['key'] as String;
}

// Podcast-specific favorite
class FavoritePodcast extends FavoriteItem {
  FavoritePodcast({
    int? id,
    required String title,
    required String imageUrl,
    required String content,
    required String category,
    required String pageUrl,
    required String duration,
    DateTime? createdAt,
  }) : super(
          id: id,
          type: 'podcast',
          title: title,
          imageUrl: imageUrl,
          createdAt: createdAt ?? DateTime.now(),
          data: {
            'content': content,
            'category': category,
            'page_url': pageUrl,
            'duration': duration,
          },
        );

  String get content => data['content'] as String;
  String get category => data['category'] as String;
  String get pageUrl => data['page_url'] as String;
  String get duration => data['duration'] as String;
}

// Space image-specific favorite
class FavoriteSpaceImage extends FavoriteItem {
  FavoriteSpaceImage({
    int? id,
    required String title,
    required String imageUrl,
    required String content,
    required String detail,
    required String source,
    required String date,
    required String type,
    required String quality,
    DateTime? createdAt,
  }) : super(
          id: id,
          type: 'space',
          title: title,
          imageUrl: imageUrl,
          createdAt: createdAt ?? DateTime.now(),
          data: {
            'content': content,
            'detail': detail,
            'source': source,
            'date': date,
            'image_type': type,
            'quality': quality,
          },
        );

  String get content => data['content'] as String;
  String get detail => data['detail'] as String;
  String get source => data['source'] as String;
  String get date => data['date'] as String;
  String get imageType => data['image_type'] as String;
  String get quality => data['quality'] as String;
}

// Music-specific favorite
class FavoriteMusic extends FavoriteItem {
  FavoriteMusic({
    int? id,
    required String title,
    required String imageUrl,
    required String artist,
    required String composer,
    required String musicUrl,
    DateTime? createdAt,
  }) : super(
          id: id,
          type: 'music',
          title: title,
          imageUrl: imageUrl,
          createdAt: createdAt ?? DateTime.now(),
          data: {
            'artist': artist,
            'composer': composer,
            'musicUrl': musicUrl,
          },
        );

  String get artist => data['artist'] as String;
  String get composer => data['composer'] as String;
  String get musicUrl => data['musicUrl'] as String;
  DateTime get savedDate => createdAt; // Use createdAt as savedDate

  factory FavoriteMusic.fromJson(Map<String, dynamic> json) {
    return FavoriteMusic(
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      composer: json['composer'] ?? '',
      musicUrl: json['musicUrl'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      createdAt: DateTime.parse(json['savedDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'composer': composer,
      'musicUrl': musicUrl,
      'imageUrl': imageUrl,
      'savedDate': createdAt.toIso8601String(),
    };
  }
}
