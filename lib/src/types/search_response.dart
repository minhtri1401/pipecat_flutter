// lib/src/types/search_response.dart

/// Response data from a bot LLM search operation.
class BotLLMSearchResponseData {
  const BotLLMSearchResponseData({
    required this.query,
    required this.results,
  });

  final String query;
  final List<String> results;

  Map<String, dynamic> toMap() => {
    'query': query,
    'results': results,
  };

  factory BotLLMSearchResponseData.fromMap(Map<String, dynamic> map) =>
      BotLLMSearchResponseData(
        query: map['query'] as String,
        results: (map['results'] as List<dynamic>).cast<String>(),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BotLLMSearchResponseData) return false;
    if (other.query != query) return false;
    if (other.results.length != results.length) return false;
    for (var i = 0; i < results.length; i++) {
      if (other.results[i] != results[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(query, Object.hashAll(results));
}
