/// Selects which native transport the [PipecatClient] uses.
///
/// Pass to the [PipecatClient.new] `transport:` argument. Cannot be
/// changed after construction — to switch transports, construct a new
/// client.
sealed class PipecatTransport {
  const PipecatTransport();
}

/// Daily.co transport. Pair with [DailyConnectParams] at connect time.
final class DailyTransport extends PipecatTransport {
  const DailyTransport();
}

/// Pipecat's lightweight SmallWebRTC transport. Pair with
/// [SmallWebRTCConnectParams] at connect time.
final class SmallWebRTCTransport extends PipecatTransport {
  const SmallWebRTCTransport();
}
