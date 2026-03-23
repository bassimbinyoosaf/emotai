class EmotionScore {
  final String emotion;
  final double score;

  EmotionScore({required this.emotion, required this.score});

  factory EmotionScore.fromJson(Map<String, dynamic> json) {
    return EmotionScore(
      emotion: json['emotion'],
      score: (json['score'] as num).toDouble(),
    );
  }
}

class EmotionResult {
  final String emotion;
  final double confidence;
  final List<EmotionScore> topEmotions;

  EmotionResult({
    required this.emotion,
    required this.confidence,
    required this.topEmotions,
  });
 
  factory EmotionResult.fromJson(Map<String, dynamic> json) {
    return EmotionResult(
      emotion: json['emotion'],
      confidence: (json['confidence'] as num).toDouble(),
      topEmotions: (json['top_emotions'] as List)
          .map((e) => EmotionScore.fromJson(e))
          .toList(),
    );
  }
}
