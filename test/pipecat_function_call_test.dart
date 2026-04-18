// test/pipecat_function_call_test.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat/pipecat.dart';
import 'package:pipecat/src/pipecat_api.g.dart' as pigeon;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LLM Function Call Handling', () {
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

    test('handler receives typed LLMFunctionCallData and returns Value', () async {
      client.registerFunctionHandler('get_weather', (data) async {
        expect(data.functionName, 'get_weather');
        expect(data.toolCallID, 'call-1');
        expect(data.args, isA<ValueObject>());
        final city = ((data.args as ValueObject).properties['city'] as ValueString).value;
        return ValueObject({'weather': ValueString('sunny in $city')});
      });

      const channel = 'dev.flutter.pigeon.pipecat_flutter.PipecatClientCallbacks.onLlmFunctionCall';
      final functionCallData = pigeon.LLMFunctionCallData(
        functionName: 'get_weather',
        toolCallID: 'call-1',
        args: '{"city":"Hanoi"}',
      );

      ByteData? response;
      await messenger.handlePlatformMessage(
        channel,
        codec.encodeMessage([functionCallData]),
        (ByteData? data) { response = data; },
      );

      expect(response, isNotNull);
      final decoded = codec.decodeMessage(response!) as List<Object?>;
      final resultJson = jsonDecode(decoded[0] as String) as Map<String, dynamic>;
      expect(resultJson['weather'], 'sunny in Hanoi');
    });

    test('returns null when no handler registered', () async {
      const channel = 'dev.flutter.pigeon.pipecat_flutter.PipecatClientCallbacks.onLlmFunctionCall';
      final functionCallData = pigeon.LLMFunctionCallData(
        functionName: 'unknown_func',
        toolCallID: 'call-2',
        args: '{}',
      );

      ByteData? response;
      await messenger.handlePlatformMessage(
        channel,
        codec.encodeMessage([functionCallData]),
        (ByteData? data) { response = data; },
      );

      expect(response, isNotNull);
      final decoded = codec.decodeMessage(response!) as List<Object?>;
      expect(decoded[0], isNull);
    });

    test('emits PipecatFunctionCallException on handler error', () async {
      client.registerFunctionHandler('bad_func', (data) async {
        throw Exception('handler crashed');
      });

      final errors = <PipecatException>[];
      client.onError.listen((e) => errors.add(e));

      const channel = 'dev.flutter.pigeon.pipecat_flutter.PipecatClientCallbacks.onLlmFunctionCall';
      await messenger.handlePlatformMessage(
        channel,
        codec.encodeMessage([pigeon.LLMFunctionCallData(
          functionName: 'bad_func',
          toolCallID: 'call-3',
          args: '{}',
        )]),
        (ByteData? data) {},
      );

      await Future.delayed(Duration.zero);
      expect(errors.length, 1);
      expect(errors.first, isA<PipecatFunctionCallException>());
    });
  });
}
