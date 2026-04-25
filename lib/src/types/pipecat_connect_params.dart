/// Per-call WebRTC ICE configuration. Used by SmallWebRTC.
class IceConfig {
  const IceConfig({required this.iceServers});

  final List<String> iceServers;

  Map<String, dynamic> toMap() => {'iceServers': iceServers};
}
