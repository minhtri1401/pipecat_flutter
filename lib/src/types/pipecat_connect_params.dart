import 'dart:convert';

/// Sealed parent for transport-specific connect-time parameters.
///
/// Pass an instance of one of the subclasses to [PipecatClient.connect].
/// The chosen subclass must pair with the transport selected at client
/// construction; mismatched pairs throw [PipecatTransportMismatchException].
sealed class PipecatConnectParams {
  const PipecatConnectParams();

  /// Wire schema (owned by Dart, consumed by the native plugin).
  Map<String, dynamic> toMap();

  String toWireJson() => jsonEncode(toMap());
}

/// Connect parameters for [DailyTransport].
final class DailyConnectParams extends PipecatConnectParams {
  const DailyConnectParams({required this.roomUrl, this.token});

  final String roomUrl;
  final String? token;

  @override
  Map<String, dynamic> toMap() => {
        'roomUrl': roomUrl,
        if (token != null) 'token': token,
      };
}

/// Connect parameters for [SmallWebRTCTransport].
final class SmallWebRTCConnectParams extends PipecatConnectParams {
  const SmallWebRTCConnectParams({required this.webrtcUrl, this.iceConfig});

  final String webrtcUrl;
  final IceConfig? iceConfig;

  @override
  Map<String, dynamic> toMap() => {
        'webrtcUrl': webrtcUrl,
        if (iceConfig != null) 'iceConfig': iceConfig!.toMap(),
      };
}

/// Per-call WebRTC ICE configuration. Used by SmallWebRTC.
final class IceConfig {
  const IceConfig({required this.iceServers});

  final List<String> iceServers;

  Map<String, dynamic> toMap() => {'iceServers': iceServers};
}
