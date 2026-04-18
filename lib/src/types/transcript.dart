// lib/src/types/transcript.dart

/// A speech transcript from a user or bot.
class Transcript {
  const Transcript({
    required this.text,
    this.finalStatus,
    this.timestamp,
    this.userId,
  });

  final String text;
  final bool? finalStatus;
  final String? timestamp;
  final String? userId;

  Map<String, dynamic> toMap() => {
    'text': text,
    'finalStatus': finalStatus,
    'timestamp': timestamp,
    'userId': userId,
  };

  factory Transcript.fromMap(Map<String, dynamic> map) => Transcript(
    text: map['text'] as String,
    finalStatus: map['finalStatus'] as bool?,
    timestamp: map['timestamp'] as String?,
    userId: map['userId'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transcript &&
          other.text == text &&
          other.finalStatus == finalStatus &&
          other.timestamp == timestamp &&
          other.userId == userId;

  @override
  int get hashCode => Object.hash(text, finalStatus, timestamp, userId);
}
