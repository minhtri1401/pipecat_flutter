// lib/src/types/enums.dart

/// The type of a media device.
enum MediaDeviceType {
  microphone,
  camera,
  speaker;

  /// Parses a string into a [MediaDeviceType].
  ///
  /// Accepts both the enum name ("microphone") and the short aliases
  /// used by the native bridge ("mic", "cam", "speaker").
  static MediaDeviceType fromString(String value) {
    switch (value) {
      case 'mic' || 'microphone':
        return MediaDeviceType.microphone;
      case 'cam' || 'camera' || 'video':
        return MediaDeviceType.camera;
      case 'speaker' || 'output':
        return MediaDeviceType.speaker;
      default:
        return MediaDeviceType.microphone;
    }
  }
}

/// The kind of a media stream track.
enum TrackKind {
  audio,
  video,
  screen;

  /// Parses a string into a [TrackKind].
  static TrackKind fromString(String value) {
    switch (value) {
      case 'audio':
        return TrackKind.audio;
      case 'video':
        return TrackKind.video;
      case 'screen':
        return TrackKind.screen;
      default:
        return TrackKind.audio;
    }
  }
}
