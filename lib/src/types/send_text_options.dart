// lib/src/types/send_text_options.dart

/// Options for [PipecatClient.sendText].
class SendTextOptions {
  const SendTextOptions({
    this.runImmediately,
    this.audioResponse,
  });

  final bool? runImmediately;
  final bool? audioResponse;

  Map<String, dynamic> toMap() => {
    'runImmediately': runImmediately,
    'audioResponse': audioResponse,
  };

  factory SendTextOptions.fromMap(Map<String, dynamic> map) => SendTextOptions(
    runImmediately: map['runImmediately'] as bool?,
    audioResponse: map['audioResponse'] as bool?,
  );
}
