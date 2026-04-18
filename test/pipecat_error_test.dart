// test/pipecat_error_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat/pipecat.dart';
import 'package:pipecat/src/pipecat_api.g.dart' as pigeon;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Exception Types', () {
    test('PipecatException has message and code', () {
      const e = PipecatException('test error', code: 'E001');
      expect(e.message, 'test error');
      expect(e.code, 'E001');
      expect(e.toString(), contains('test error'));
    });

    test('PipecatConnectionException is a PipecatException', () {
      const e = PipecatConnectionException('connection failed');
      expect(e, isA<PipecatException>());
      expect(e.message, 'connection failed');
    });

    test('PipecatFunctionCallException is a PipecatException', () {
      const e = PipecatFunctionCallException('bad args');
      expect(e, isA<PipecatException>());
    });
  });

  group('onError stream', () {
    late PipecatClient client;
    const codec = pigeon.PipecatClientCallbacks.pigeonChannelCodec;
    late TestDefaultBinaryMessenger messenger;

    setUp(() {
      client = PipecatClient();
      messenger = ServicesBinding.instance.defaultBinaryMessenger as TestDefaultBinaryMessenger;
    });

    tearDown(() {
      client.dispose();
    });

    test('onGenericError callback emits to onError stream', () async {
      final errors = <PipecatException>[];
      client.onError.listen((e) => errors.add(e));

      const channel = 'dev.flutter.pigeon.pipecat_flutter.PipecatClientCallbacks.onGenericError';
      await messenger.handlePlatformMessage(
        channel,
        codec.encodeMessage(['something broke', 'E500']),
        (ByteData? data) {},
      );
      await Future.delayed(Duration.zero);

      expect(errors.length, 1);
      expect(errors.first.message, 'something broke');
      expect(errors.first.code, 'E500');
    });

    test('onGenericError with null code emits exception with null code', () async {
      final errors = <PipecatException>[];
      client.onError.listen((e) => errors.add(e));

      const channel = 'dev.flutter.pigeon.pipecat_flutter.PipecatClientCallbacks.onGenericError';
      await messenger.handlePlatformMessage(
        channel,
        codec.encodeMessage(['something broke', null]),
        (ByteData? data) {},
      );
      await Future.delayed(Duration.zero);

      expect(errors.length, 1);
      expect(errors.first.message, 'something broke');
      expect(errors.first.code, isNull);
    });
  });
}
