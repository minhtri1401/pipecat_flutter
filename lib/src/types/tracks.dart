// lib/src/types/tracks.dart
import 'enums.dart';

/// A single media stream track.
class MediaStreamTrack {
  const MediaStreamTrack({
    required this.id,
    required this.kind,
    required this.enabled,
  });

  final String id;
  final TrackKind kind;
  final bool enabled;

  Map<String, dynamic> toMap() => {
    'id': id,
    'kind': kind.name,
    'enabled': enabled,
  };

  factory MediaStreamTrack.fromMap(Map<String, dynamic> map) => MediaStreamTrack(
    id: map['id'] as String,
    kind: TrackKind.fromString(map['kind'] as String),
    enabled: map['enabled'] as bool,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaStreamTrack && other.id == id && other.kind == kind && other.enabled == enabled;

  @override
  int get hashCode => Object.hash(id, kind, enabled);
}

/// The set of tracks for a participant.
class ParticipantTracks {
  const ParticipantTracks({
    this.video,
    this.audio,
    this.screen,
  });

  final MediaStreamTrack? video;
  final MediaStreamTrack? audio;
  final MediaStreamTrack? screen;

  Map<String, dynamic> toMap() => {
    'video': video?.toMap(),
    'audio': audio?.toMap(),
    'screen': screen?.toMap(),
  };

  factory ParticipantTracks.fromMap(Map<String, dynamic> map) => ParticipantTracks(
    video: map['video'] != null ? MediaStreamTrack.fromMap(map['video'] as Map<String, dynamic>) : null,
    audio: map['audio'] != null ? MediaStreamTrack.fromMap(map['audio'] as Map<String, dynamic>) : null,
    screen: map['screen'] != null ? MediaStreamTrack.fromMap(map['screen'] as Map<String, dynamic>) : null,
  );
}

/// The local and bot tracks in a session.
class Tracks {
  const Tracks({
    required this.local,
    this.bot,
  });

  final ParticipantTracks local;
  final ParticipantTracks? bot;

  Map<String, dynamic> toMap() => {
    'local': local.toMap(),
    'bot': bot?.toMap(),
  };

  factory Tracks.fromMap(Map<String, dynamic> map) => Tracks(
    local: ParticipantTracks.fromMap(map['local'] as Map<String, dynamic>),
    bot: map['bot'] != null ? ParticipantTracks.fromMap(map['bot'] as Map<String, dynamic>) : null,
  );
}
