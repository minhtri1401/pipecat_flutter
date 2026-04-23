// test/pipecat_events_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat/pipecat.dart';
import 'package:pipecat/src/pipecat_api.g.dart' as pigeon;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PipecatClient Events', () {
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

    Future<void> sendCallback(String method, List<Object?> args) async {
      final channel = 'dev.flutter.pigeon.pipecat_flutter.PipecatClientCallbacks.$method';
      await messenger.handlePlatformMessage(
        channel,
        codec.encodeMessage(args),
        (ByteData? data) {},
      );
      await Future.delayed(Duration.zero);
    }

    test('onConnected fires', () async {
      final events = <void>[];
      client.onConnected.listen((e) => events.add(e));
      await sendCallback('onConnected', []);
      expect(events.length, 1);
    });

    test('onDisconnected fires', () async {
      final events = <void>[];
      client.onDisconnected.listen((e) => events.add(e));
      await sendCallback('onDisconnected', []);
      expect(events.length, 1);
    });

    test('onTransportStateChanged emits TransportState', () async {
      final states = <TransportState>[];
      client.onTransportStateChanged.listen((s) => states.add(s));
      await sendCallback('onTransportStateChanged', ['connected']);
      expect(states, [TransportState.connected]);
    });

    test('onTransportStateChanged maps unknown to error', () async {
      final states = <TransportState>[];
      client.onTransportStateChanged.listen((s) => states.add(s));
      await sendCallback('onTransportStateChanged', ['garbage']);
      expect(states, [TransportState.error]);
    });

    test('onUserTranscript maps to hand-written Transcript', () async {
      final transcripts = <Transcript>[];
      client.onUserTranscript.listen((t) => transcripts.add(t));

      final pigeonTranscript = pigeon.Transcript(
        text: 'hello',
        userId: 'u1',
        finalStatus: true,
      );
      await sendCallback('onUserTranscript', [pigeonTranscript]);

      expect(transcripts.length, 1);
      expect(transcripts.first.text, 'hello');
      expect(transcripts.first.userId, 'u1');
      expect(transcripts.first.finalStatus, true);
    });

    test('onBotReady maps BotReadyData with Value about', () async {
      final events = <BotReadyData>[];
      client.onBotReady.listen((e) => events.add(e));

      final pigeonData = pigeon.BotReadyData(version: '2.0', about: '{"name":"test"}');
      await sendCallback('onBotReady', [pigeonData]);

      expect(events.length, 1);
      expect(events.first.version, '2.0');
      expect(events.first.about, isA<ValueObject>());
    });

    test('onBotOutput maps correctly', () async {
      final events = <BotOutputData>[];
      client.onBotOutput.listen((e) => events.add(e));

      await sendCallback('onBotOutput', [pigeon.BotOutputData(text: 'hi', spoken: true, aggregatedBy: 'word')]);
      expect(events.first.text, 'hi');
      expect(events.first.spoken, true);
    });

    test('onParticipantJoined maps to hand-written Participant', () async {
      final participants = <Participant>[];
      client.onParticipantJoined.listen((p) => participants.add(p));

      await sendCallback('onParticipantJoined', [pigeon.Participant(id: 'p1', name: 'Alice', local: false)]);
      expect(participants.first.id, 'p1');
      expect(participants.first.name, 'Alice');
    });

    test('onTracksUpdated maps to hand-written Tracks', () async {
      final tracks = <Tracks>[];
      client.onTracksUpdated.listen((t) => tracks.add(t));

      await sendCallback('onTracksUpdated', [
        pigeon.Tracks(
          local: pigeon.ParticipantTracks(
            audio: pigeon.MediaStreamTrack(id: 'a1', kind: 'audio', enabled: true),
          ),
        ),
      ]);
      expect(tracks.first.local.audio!.id, 'a1');
      expect(tracks.first.local.audio!.kind, TrackKind.audio);
    });

    test('onServerMessage parses JSON into Value', () async {
      final messages = <Value>[];
      client.onServerMessage.listen((m) => messages.add(m));

      await sendCallback('onServerMessage', ['{"action":"ping"}']);
      expect(messages.first, isA<ValueObject>());
    });

    test('onBotLLMSearchResponse maps correctly', () async {
      final responses = <BotLLMSearchResponseData>[];
      client.onBotLLMSearchResponse.listen((r) => responses.add(r));

      await sendCallback('onBotLLMSearchResponse', [
        pigeon.BotLLMSearchResponseData(query: 'test', results: ['result1']),
      ]);
      expect(responses.first.query, 'test');
      expect(responses.first.results, ['result1']);
    });

    test('void events fire correctly', () async {
      for (final entry in {
        'onBotStartedSpeaking': client.onBotStartedSpeaking,
        'onBotStoppedSpeaking': client.onBotStoppedSpeaking,
        'onUserStartedSpeaking': client.onUserStartedSpeaking,
        'onUserStoppedSpeaking': client.onUserStoppedSpeaking,
        'onBotLlmStarted': client.onBotLlmStarted,
        'onBotLlmStopped': client.onBotLlmStopped,
        'onBotTtsStarted': client.onBotTtsStarted,
        'onBotTtsStopped': client.onBotTtsStopped,
      }.entries) {
        var fired = false;
        final sub = entry.value.listen((_) => fired = true);
        await sendCallback(entry.key, []);
        expect(fired, true, reason: '${entry.key} did not fire');
        await sub.cancel();
      }
    });

    test('string events fire correctly', () async {
      for (final entry in {
        'onBackendError': client.onBackendError,
        'onBotTranscript': client.onBotTranscript,
        'onBotLlmText': client.onBotLlmText,
        'onBotTtsText': client.onBotTtsText,
        'onMessageError': client.onMessageError,
      }.entries) {
        final values = <String>[];
        final sub = entry.value.listen((v) => values.add(v));
        await sendCallback(entry.key, ['test-value']);
        expect(values, ['test-value'], reason: '${entry.key} mismatch');
        await sub.cancel();
      }
    });

    test('onLocalAudioLevel fires', () async {
      final levels = <double>[];
      client.onLocalAudioLevel.listen((l) => levels.add(l));
      await sendCallback('onLocalAudioLevel', [0.75]);
      expect(levels, [0.75]);
    });

    test('onRemoteAudioLevel fires with tuple', () async {
      final events = <(double, String)>[];
      client.onRemoteAudioLevel.listen((e) => events.add(e));
      await sendCallback('onRemoteAudioLevel', [0.5, 'p1']);
      expect(events.first, (0.5, 'p1'));
    });

    test('onServerMessage with invalid JSON emits to onMessageError', () async {
      final serverMessages = <Value>[];
      final errors = <String>[];
      client.onServerMessage.listen(serverMessages.add);
      client.onMessageError.listen(errors.add);

      await sendCallback('onServerMessage', ['{not json']);

      expect(serverMessages, isEmpty);
      expect(errors.length, 1);
      expect(errors.first.toLowerCase(), contains('parse'));
    });

    test('onServerMessage with valid JSON still emits to onServerMessage', () async {
      final serverMessages = <Value>[];
      final errors = <String>[];
      client.onServerMessage.listen(serverMessages.add);
      client.onMessageError.listen(errors.add);

      await sendCallback('onServerMessage', ['{"foo":42}']);

      expect(errors, isEmpty);
      expect(serverMessages.length, 1);
      expect(serverMessages.first, isA<ValueObject>());
    });

    test('callbacks after dispose do not throw', () async {
      // Build a client with a unique suffix so we can exercise dispose in
      // isolation from the shared `client` created in setUp. The test
      // framework will fail the test if sendCallback throws post-dispose.
      final localClient =
          PipecatClient(messageChannelSuffix: '.dispose-race');
      final events = <void>[];
      localClient.onConnected.listen(events.add);

      localClient.dispose();

      // Simulate a native callback landing after dispose.
      final channel =
          'dev.flutter.pigeon.pipecat_flutter.PipecatClientCallbacks.onConnected.dispose-race';
      await messenger.handlePlatformMessage(
        channel,
        codec.encodeMessage(<Object?>[]),
        (ByteData? data) {},
      );
      await Future.delayed(Duration.zero);

      expect(events, isEmpty); // handler torn down, no dispatch
    });
  });

  group('New Task 8 Events', () {
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

    Future<void> sendCallback(String method, List<Object?> args) async {
      final channel = 'dev.flutter.pigeon.pipecat_flutter.PipecatClientCallbacks.$method';
      await messenger.handlePlatformMessage(
        channel,
        codec.encodeMessage(args),
        (ByteData? data) {},
      );
      await Future.delayed(Duration.zero);
    }

    test('onBotConnected emits Participant', () async {
      final events = <Participant>[];
      client.onBotConnected.listen((e) => events.add(e));
      await sendCallback('onBotConnected', [pigeon.Participant(id: 'bot-1', name: 'Bot', local: false)]);
      expect(events.length, 1);
      expect(events.first.id, 'bot-1');
      expect(events.first.name, 'Bot');
      expect(events.first.local, false);
    });

    test('onBotDisconnected emits Participant', () async {
      final events = <Participant>[];
      client.onBotDisconnected.listen((e) => events.add(e));
      await sendCallback('onBotDisconnected', [pigeon.Participant(id: 'bot-1', name: 'Bot', local: false)]);
      expect(events.length, 1);
      expect(events.first.id, 'bot-1');
    });

    test('onBotStarted emits Value? from JSON string', () async {
      final events = <Value?>[];
      client.onBotStarted.listen((e) => events.add(e));
      await sendCallback('onBotStarted', ['{"ready":true}']);
      expect(events.length, 1);
      expect(events.first, isA<ValueObject>());
    });

    test('onTrackStarted emits (String, Participant) tuple', () async {
      final events = <(String, Participant)>[];
      client.onTrackStarted.listen((e) => events.add(e));
      await sendCallback('onTrackStarted', ['track-1', pigeon.Participant(id: 'p1', name: 'Alice', local: false)]);
      expect(events.length, 1);
      expect(events.first.$1, 'track-1');
      expect(events.first.$2.id, 'p1');
    });

    test('onTrackStopped emits (String, Participant) tuple', () async {
      final events = <(String, Participant)>[];
      client.onTrackStopped.listen((e) => events.add(e));
      await sendCallback('onTrackStopped', ['track-1', pigeon.Participant(id: 'p1', name: 'Alice', local: false)]);
      expect(events.length, 1);
      expect(events.first.$1, 'track-1');
      expect(events.first.$2.id, 'p1');
    });

    test('onScreenTrackStarted emits (String, Participant) tuple', () async {
      final events = <(String, Participant)>[];
      client.onScreenTrackStarted.listen((e) => events.add(e));
      await sendCallback('onScreenTrackStarted', ['track-1', pigeon.Participant(id: 'p1', name: 'Alice', local: false)]);
      expect(events.length, 1);
      expect(events.first.$1, 'track-1');
      expect(events.first.$2.id, 'p1');
    });

    test('onScreenTrackStopped emits (String, Participant) tuple', () async {
      final events = <(String, Participant)>[];
      client.onScreenTrackStopped.listen((e) => events.add(e));
      await sendCallback('onScreenTrackStopped', ['track-1', pigeon.Participant(id: 'p1', name: 'Alice', local: false)]);
      expect(events.length, 1);
      expect(events.first.$1, 'track-1');
      expect(events.first.$2.id, 'p1');
    });

    test('onScreenShareError emits String', () async {
      final events = <String>[];
      client.onScreenShareError.listen((e) => events.add(e));
      await sendCallback('onScreenShareError', ['screen share failed']);
      expect(events.length, 1);
      expect(events.first, 'screen share failed');
    });

    test('onInputsUpdated emits named record with camera and mic', () async {
      final events = <({bool camera, bool mic})>[];
      client.onInputsUpdated.listen((e) => events.add(e));
      await sendCallback('onInputsUpdated', [true, false]);
      expect(events.length, 1);
      expect(events.first.camera, true);
      expect(events.first.mic, false);
    });

    test('onMetrics emits PipecatMetrics', () async {
      final events = <PipecatMetrics>[];
      client.onMetrics.listen((e) => events.add(e));
      await sendCallback('onMetrics', [
        pigeon.PipecatMetrics(
          processing: [pigeon.PipecatMetricsData(processor: 'llm', value: 0.42)],
          ttfb: null,
          characters: null,
        ),
      ]);
      expect(events.length, 1);
      expect(events.first, isA<PipecatMetrics>());
      expect(events.first.processing, isNotNull);
      expect(events.first.processing!.length, 1);
      expect(events.first.processing!.first.processor, 'llm');
    });

    test('onParticipantLeft emits Participant', () async {
      final events = <Participant>[];
      client.onParticipantLeft.listen((e) => events.add(e));
      await sendCallback('onParticipantLeft', [pigeon.Participant(id: 'p1', name: 'Alice', local: false)]);
      expect(events.length, 1);
      expect(events.first.id, 'p1');
    });

    test('onParticipantUpdated emits Participant', () async {
      final events = <Participant>[];
      client.onParticipantUpdated.listen((e) => events.add(e));
      await sendCallback('onParticipantUpdated', [pigeon.Participant(id: 'p2', name: 'Bob', local: true)]);
      expect(events.length, 1);
      expect(events.first.id, 'p2');
    });
  });
}
