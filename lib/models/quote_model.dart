class QuoteModel {
  final String text;
  final String author;
  final String date; // YYYY-MM-DD format
  final DateTime fetchedAt;

  QuoteModel({
    required this.text,
    required this.author,
    required this.date,
    required this.fetchedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'author': author,
      'date': date,
      'fetchedAt': fetchedAt.toIso8601String(),
    };
  }

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      text: json['text'] ?? '',
      author: json['author'] ?? 'Unknown',
      date: json['date'] ?? '',
      fetchedAt: DateTime.parse(json['fetchedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  factory QuoteModel.fromApi(Map<String, dynamic> apiData) {
    return QuoteModel(
      text: apiData['q'] ?? '',
      author: apiData['a'] ?? 'Unknown',
      date: DateTime.now().toIso8601String().substring(0, 10),
      fetchedAt: DateTime.now(),
    );
  }
}
