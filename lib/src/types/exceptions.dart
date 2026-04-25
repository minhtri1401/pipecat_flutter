// lib/src/types/exceptions.dart

/// Base exception for all Pipecat plugin errors.
class PipecatException implements Exception {
  const PipecatException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'PipecatException($message${code != null ? ', code: $code' : ''})';
}

/// Exception thrown when a transport connection operation fails.
class PipecatConnectionException extends PipecatException {
  const PipecatConnectionException(super.message, {super.code});

  @override
  String toString() => 'PipecatConnectionException($message${code != null ? ', code: $code' : ''})';
}

/// Exception thrown when an LLM function call fails.
class PipecatFunctionCallException extends PipecatException {
  const PipecatFunctionCallException(super.message, {super.code});

  @override
  String toString() => 'PipecatFunctionCallException($message${code != null ? ', code: $code' : ''})';
}

/// Thrown when [PipecatConnectParams] passed to `connect()` doesn't pair
/// with the [PipecatTransport] chosen at client construction.
class PipecatTransportMismatchException extends PipecatException {
  PipecatTransportMismatchException(this.transportType, this.paramsType)
      : super(
          'Transport $transportType cannot accept params of type $paramsType',
          code: 'transport-mismatch',
        );

  final Type transportType;
  final Type paramsType;
}
