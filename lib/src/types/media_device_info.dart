// lib/src/types/media_device_info.dart
import 'enums.dart';

/// Information about a media device (microphone, camera, or speaker).
class MediaDeviceInfo {
  const MediaDeviceInfo({
    required this.id,
    required this.label,
    required this.type,
  });

  final String id;
  final String label;
  final MediaDeviceType type;

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'type': type.name,
  };

  factory MediaDeviceInfo.fromMap(Map<String, dynamic> map) => MediaDeviceInfo(
    id: map['id'] as String,
    label: map['label'] as String,
    type: MediaDeviceType.fromString(map['type'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaDeviceInfo && other.id == id && other.label == label && other.type == type;

  @override
  int get hashCode => Object.hash(id, label, type);

  @override
  String toString() => 'MediaDeviceInfo(id: $id, label: $label, type: $type)';
}
