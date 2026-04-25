// test/pipecat_request_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat/pipecat.dart';
import 'package:pipecat/src/pipecat_api.g.dart' as pigeon;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sendClientRequest response handling', () {
    late PipecatClient client;
    late TestDefaultBinaryMessenger messenger;
    const codec = pigeon.PipecatClientApi.pigeonChannelCodec;
    const channel =
        'dev.flutter.pigeon.pipecat_flutter.PipecatClientApi.sendClientRequest';

    setUp(() {
      client = PipecatClient(transport: const DailyTransport());
      messenger = ServicesBinding.instance.defaultBinaryMessenger
          as TestDefaultBinaryMessenger;
    });

    tearDown(() {
      messenger.setMockMessageHandler(channel, null);
      client.dispose();
    });

    void mockResponse(String response) {
      messenger.setMockMessageHandler(channel, (ByteData? message) async {
        return codec.encodeMessage(<Object?>[response]);
      });
    }

    test('returns parsed Value on valid JSON', () async {
      mockResponse('{"ok":true}');
      final result = await client.sendClientRequest('ping', null);
      expect(result, isA<ValueObject>());
      expect(
        ((result as ValueObject).properties['ok'] as ValueBool).value,
        true,
      );
    });

    test('throws PipecatException on empty response', () async {
      mockResponse('');
      expect(
        () => client.sendClientRequest('ping', null),
        throwsA(isA<PipecatException>()),
      );
    });

    test('throws PipecatException on malformed response', () async {
      mockResponse('{not json');
      expect(
        () => client.sendClientRequest('ping', null),
        throwsA(isA<PipecatException>()),
      );
    });
  });
}
