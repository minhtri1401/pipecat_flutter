import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat/src/types/pipecat_connect_params.dart';

void main() {
  group('DailyConnectParams', () {
    test('is a PipecatConnectParams', () {
      const params = DailyConnectParams(roomUrl: 'https://x.daily.co/y');
      expect(params, isA<PipecatConnectParams>());
    });

    test('toWireJson with token includes both keys', () {
      const params = DailyConnectParams(
        roomUrl: 'https://x.daily.co/y',
        token: 't',
      );
      final json = jsonDecode(params.toWireJson()) as Map<String, dynamic>;
      expect(json, {
        'roomUrl': 'https://x.daily.co/y',
        'token': 't',
      });
    });

    test('toWireJson without token omits the key', () {
      const params = DailyConnectParams(roomUrl: 'https://x.daily.co/y');
      final json = jsonDecode(params.toWireJson()) as Map<String, dynamic>;
      expect(json, {'roomUrl': 'https://x.daily.co/y'});
      expect(json.containsKey('token'), isFalse);
    });
  });

  group('SmallWebRTCConnectParams', () {
    test('is a PipecatConnectParams', () {
      const params = SmallWebRTCConnectParams(webrtcUrl: 'https://x/offer');
      expect(params, isA<PipecatConnectParams>());
    });

    test('toWireJson without iceConfig', () {
      const params = SmallWebRTCConnectParams(webrtcUrl: 'https://x/offer');
      final json = jsonDecode(params.toWireJson()) as Map<String, dynamic>;
      expect(json, {'webrtcUrl': 'https://x/offer'});
      expect(json.containsKey('iceConfig'), isFalse);
    });

    test('toWireJson with iceConfig', () {
      const params = SmallWebRTCConnectParams(
        webrtcUrl: 'https://x/offer',
        iceConfig: IceConfig(iceServers: ['stun:stun.l.google.com:19302']),
      );
      final json = jsonDecode(params.toWireJson()) as Map<String, dynamic>;
      expect(json['webrtcUrl'], 'https://x/offer');
      expect(json['iceConfig'], {
        'iceServers': ['stun:stun.l.google.com:19302'],
      });
    });
  });
}
