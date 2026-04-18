/// The state of the transport connection to the Pipecat server.
enum TransportState {
  disconnected,
  initializing,
  initialized,
  authenticating,
  authenticated,
  connecting,
  connected,
  ready,
  disconnecting,
  error;

  /// Parses a string into a [TransportState].
  ///
  /// Returns [TransportState.error] if the string does not match any known state.
  static TransportState fromString(String value) =>
      TransportState.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TransportState.error,
      );
}
