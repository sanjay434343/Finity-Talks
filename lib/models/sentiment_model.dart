class SentimentModel {
  final String text;
  final SentimentType type;
  final double score;
  final double confidence;

  const SentimentModel({
    required this.text,
    required this.type,
    required this.score,
    required this.confidence,
  });

  factory SentimentModel.fromAnalysis(String text, double score) {
    SentimentType type;
    if (score > 0.1) {
      type = SentimentType.positive;
    } else if (score < -0.1) {
      type = SentimentType.negative;
    } else {
      type = SentimentType.moderate;
    }

    return SentimentModel(
      text: text,
      type: type,
      score: score,
      confidence: (score.abs() * 100).clamp(0, 100),
    );
  }

  @override
  String toString() {
    return 'SentimentModel(type: $type, score: $score, confidence: $confidence)';
  }
}

enum SentimentType {
  positive,
  negative,
  moderate;

  String get displayName {
    switch (this) {
      case SentimentType.positive:
        return 'Positive';
      case SentimentType.negative:
        return 'Negative';
      case SentimentType.moderate:
        return 'Moderate';
    }
  }

  String get emoji {
    switch (this) {
      case SentimentType.positive:
        return '😊';
      case SentimentType.negative:
        return '😔';
      case SentimentType.moderate:
        return '😐';
    }
  }
}
