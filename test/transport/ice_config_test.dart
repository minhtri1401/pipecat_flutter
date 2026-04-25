import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat/src/types/pipecat_connect_params.dart';

void main() {
  group('IceConfig', () {
    test('toMap produces { iceServers: [...] }', () {
      const config = IceConfig(iceServers: ['stun:stun.l.google.com:19302']);
      expect(config.toMap(), {
        'iceServers': ['stun:stun.l.google.com:19302'],
      });
    });

    test('toMap with empty list', () {
      const config = IceConfig(iceServers: []);
      expect(config.toMap(), {'iceServers': <String>[]});
    });
  });
}
