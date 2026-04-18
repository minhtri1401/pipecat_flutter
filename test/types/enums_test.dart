// test/types/enums_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat/src/types/enums.dart';

void main() {
  group('MediaDeviceType', () {
    test('fromString parses primary names', () {
      expect(MediaDeviceType.fromString('microphone'), MediaDeviceType.microphone);
      expect(MediaDeviceType.fromString('camera'), MediaDeviceType.camera);
      expect(MediaDeviceType.fromString('speaker'), MediaDeviceType.speaker);
    });

    test('fromString parses native bridge aliases', () {
      expect(MediaDeviceType.fromString('mic'), MediaDeviceType.microphone);
      expect(MediaDeviceType.fromString('cam'), MediaDeviceType.camera);
      expect(MediaDeviceType.fromString('video'), MediaDeviceType.camera);
      expect(MediaDeviceType.fromString('output'), MediaDeviceType.speaker);
    });

    test('fromString defaults to microphone for unknown', () {
      expect(MediaDeviceType.fromString(''), MediaDeviceType.microphone);
      expect(MediaDeviceType.fromString('unknown'), MediaDeviceType.microphone);
    });
  });

  group('TrackKind', () {
    test('fromString parses all kinds', () {
      expect(TrackKind.fromString('audio'), TrackKind.audio);
      expect(TrackKind.fromString('video'), TrackKind.video);
      expect(TrackKind.fromString('screen'), TrackKind.screen);
    });

    test('fromString defaults to audio for unknown', () {
      expect(TrackKind.fromString(''), TrackKind.audio);
      expect(TrackKind.fromString('garbage'), TrackKind.audio);
    });
  });
}
