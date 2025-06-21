class BookSuggestion {
  final String title;
  final String author;
  final String coverUrl;
  final String key;

  BookSuggestion({
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.key,
  });

  factory BookSuggestion.fromJson(Map<String, dynamic> json) {
    return BookSuggestion(
      title: json['title'] ?? 'Unknown Title',
      author: (json['authors'] as List<dynamic>?)?.isNotEmpty == true 
          ? json['authors'][0]['name'] ?? 'Unknown Author'
          : 'Unknown Author',
      coverUrl: json['cover_id'] != null 
          ? 'https://covers.openlibrary.org/b/id/${json['cover_id']}-M.jpg'
          : '',
      key: json['key'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookSuggestion &&
        other.title == title &&
        other.author == author &&
        other.key == key;
  }

  @override
  int get hashCode {
    return title.hashCode ^ author.hashCode ^ key.hashCode;
  }
}
