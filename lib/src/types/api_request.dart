// lib/src/types/api_request.dart

/// Parameters for a bot API request.
class ApiRequest {
  const ApiRequest({
    required this.endpoint,
    this.headers = const {},
    this.requestData,
    this.timeoutMs = 30000,
  });

  final String endpoint;
  final Map<String, String> headers;
  final String? requestData;
  final int? timeoutMs;

  Map<String, dynamic> toMap() => {
    'endpoint': endpoint,
    'headers': headers,
    'requestData': requestData,
    'timeoutMs': timeoutMs,
  };

  factory ApiRequest.fromMap(Map<String, dynamic> map) => ApiRequest(
    endpoint: map['endpoint'] as String,
    headers: (map['headers'] as Map<String, dynamic>?)?.cast<String, String>() ?? {},
    requestData: map['requestData'] as String?,
    timeoutMs: map['timeoutMs'] as int?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiRequest &&
          other.endpoint == endpoint &&
          other.timeoutMs == timeoutMs;

  @override
  int get hashCode => Object.hash(endpoint, timeoutMs);
}
