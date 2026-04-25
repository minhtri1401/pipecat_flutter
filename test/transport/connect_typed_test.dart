// ignore_for_file: non_constant_identifier_names
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat/pipecat.dart';
import 'package:pipecat/src/pipecat_api.g.dart' as pigeon;

/// A hand-rolled stub of [pigeon.PipecatClientApi] that captures the
/// arguments to [initialize] and [connect] so the test can assert on them.
class _StubApi implements pigeon.PipecatClientApi {
  pigeon.PipecatClientOptions? lastInitOptions;
  String? lastConnectJson;
  int connectCalls = 0;
  bool throwOnConnect = false;

  @override
  Future<void> initialize(pigeon.PipecatClientOptions options) async {
    lastInitOptions = options;
  }

  @override
  Future<void> connect(String transportParamsJson) async {
    connectCalls++;
    lastConnectJson = transportParamsJson;
    if (throwOnConnect) {
      throw PlatformException(code: 'native', message: 'boom');
    }
  }

  // The remaining surface is unused by these tests — `noSuchMethod` short-circuits.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');

  @override
  String get pigeonVar_messageChannelSuffix => '';

  @override
  BinaryMessenger? get pigeonVar_binaryMessenger => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('connect(transportParams:)', () {
    test('Daily client + Daily params calls api.connect with toWireJson',
        () async {
      final api = _StubApi();
      final client = PipecatClient.withApi(
        transport: const DailyTransport(),
        api: api,
      );
      await client.initialize();

      await client.connect(
        transportParams: const DailyConnectParams(
          roomUrl: 'https://x.daily.co/y',
          token: 't',
        ),
      );

      expect(api.connectCalls, 1);
      expect(api.lastConnectJson, contains('"roomUrl":"https://x.daily.co/y"'));
      expect(api.lastConnectJson, contains('"token":"t"'));
    });

    test(
        'Daily client + SmallWebRTC params throws PipecatTransportMismatchException',
        () async {
      final api = _StubApi();
      final client = PipecatClient.withApi(
        transport: const DailyTransport(),
        api: api,
      );
      await client.initialize();

      expect(
        () => client.connect(
          transportParams: const SmallWebRTCConnectParams(webrtcUrl: 'https://x'),
        ),
        throwsA(isA<PipecatTransportMismatchException>()),
      );
      expect(api.connectCalls, 0);
    });

    test('SmallWebRTC client + Daily params throws', () async {
      final api = _StubApi();
      final client = PipecatClient.withApi(
        transport: const SmallWebRTCTransport(),
        api: api,
      );
      await client.initialize();

      expect(
        () => client.connect(
          transportParams: const DailyConnectParams(roomUrl: 'https://x.daily.co/y'),
        ),
        throwsA(isA<PipecatTransportMismatchException>()),
      );
    });

    test('SmallWebRTC client + SmallWebRTC params calls api.connect', () async {
      final api = _StubApi();
      final client = PipecatClient.withApi(
        transport: const SmallWebRTCTransport(),
        api: api,
      );
      await client.initialize();

      await client.connect(
        transportParams: const SmallWebRTCConnectParams(webrtcUrl: 'https://x'),
      );

      expect(api.connectCalls, 1);
      expect(api.lastConnectJson, contains('"webrtcUrl":"https://x"'));
    });

    test('Daily client flows TransportKind.daily into initialize()', () async {
      final api = _StubApi();
      final client = PipecatClient.withApi(
        transport: const DailyTransport(),
        api: api,
      );
      await client.initialize();
      expect(api.lastInitOptions?.kind, pigeon.TransportKind.daily);
    });

    test('SmallWebRTC client flows TransportKind.smallWebRtc', () async {
      final api = _StubApi();
      final client = PipecatClient.withApi(
        transport: const SmallWebRTCTransport(),
        api: api,
      );
      await client.initialize();
      expect(api.lastInitOptions?.kind, pigeon.TransportKind.smallWebRtc);
    });

    test('PlatformException from native is wrapped as PipecatConnectionException',
        () async {
      final api = _StubApi()..throwOnConnect = true;
      final client = PipecatClient.withApi(
        transport: const DailyTransport(),
        api: api,
      );
      await client.initialize();

      expect(
        () => client.connect(
          transportParams: const DailyConnectParams(roomUrl: 'https://x.daily.co/y'),
        ),
        throwsA(isA<PipecatConnectionException>()),
      );
    });
  });
}
