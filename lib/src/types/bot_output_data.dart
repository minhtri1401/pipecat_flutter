// lib/src/types/bot_output_data.dart

/// Aggregated bot output data.
class BotOutputData {
  const BotOutputData({
    required this.text,
    required this.spoken,
    required this.aggregatedBy,
  });

  final String text;
  final bool spoken;
  final String aggregatedBy;

  Map<String, dynamic> toMap() => {
    'text': text,
    'spoken': spoken,
    'aggregatedBy': aggregatedBy,
  };

  factory BotOutputData.fromMap(Map<String, dynamic> map) => BotOutputData(
    text: map['text'] as String,
    spoken: map['spoken'] as bool,
    aggregatedBy: map['aggregatedBy'] as String,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BotOutputData &&
          other.text == text &&
          other.spoken == spoken &&
          other.aggregatedBy == aggregatedBy;

  @override
  int get hashCode => Object.hash(text, spoken, aggregatedBy);
}
