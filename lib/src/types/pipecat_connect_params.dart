import 'dart:convert';

/// Sealed parent for transport-specific connect-time parameters.
///
/// Pass an instance of one of the subclasses to [PipecatClient.connect].
/// The chosen subclass must pair with the transport selected at client
/// construction; mismatched pairs throw [PipecatTransportMismatchException].
sealed class PipecatConnectParams {
  const PipecatConnectParams();

  /// Internal. Serializes to the wire JSON shape consumed by the native
  /// plugin layer. The Dart side owns this schema.
  String toWireJson();
}

/// Connect parameters for [DailyTransport].
final class DailyConnectParams extends PipecatConnectParams {
  const DailyConnectParams({required this.roomUrl, this.token});

  final String roomUrl;
  final String? token;

  @override
  String toWireJson() => jsonEncode({
        'roomUrl': roomUrl,
        if (token != null) 'token': token,
      });
}

/// Connect parameters for [SmallWebRTCTransport].
final class SmallWebRTCConnectParams extends PipecatConnectParams {
  const SmallWebRTCConnectParams({required this.webrtcUrl, this.iceConfig});

  final String webrtcUrl;
  final IceConfig? iceConfig;

  @override
  String toWireJson() => jsonEncode({
        'webrtcUrl': webrtcUrl,
        if (iceConfig != null) 'iceConfig': iceConfig!.toMap(),
      });
}

/// Per-call WebRTC ICE configuration. Used by SmallWebRTC.
class IceConfig {
  const IceConfig({required this.iceServers});

  final List<String> iceServers;

  Map<String, dynamic> toMap() => {'iceServers': iceServers};
}
