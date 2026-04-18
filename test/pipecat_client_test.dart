// test/pipecat_client_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat/pipecat.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PipecatClient', () {
    late PipecatClient client;

    setUp(() {
      client = PipecatClient();
    });

    tearDown(() {
      client.dispose();
    });

    test('can be created', () {
      expect(client, isNotNull);
    });

    test('all existing streams are accessible', () {
      expect(client.onConnected, isA<Stream<void>>());
      expect(client.onDisconnected, isA<Stream<void>>());
      expect(client.onTransportStateChanged, isA<Stream<TransportState>>());
      expect(client.onBotReady, isA<Stream<BotReadyData>>());
      expect(client.onBackendError, isA<Stream<String>>());
      expect(client.onLocalAudioLevel, isA<Stream<double>>());
      expect(client.onRemoteAudioLevel, isA<Stream<(double, String)>>());
      expect(client.onBotStartedSpeaking, isA<Stream<void>>());
      expect(client.onBotStoppedSpeaking, isA<Stream<void>>());
      expect(client.onUserStartedSpeaking, isA<Stream<void>>());
      expect(client.onUserStoppedSpeaking, isA<Stream<void>>());
      expect(client.onUserTranscript, isA<Stream<Transcript>>());
      expect(client.onBotTranscript, isA<Stream<String>>());
      expect(client.onBotLlmText, isA<Stream<String>>());
      expect(client.onBotTtsText, isA<Stream<String>>());
      expect(client.onBotOutput, isA<Stream<BotOutputData>>());
      expect(client.onMetrics, isA<Stream<PipecatMetrics>>());
      expect(client.onServerMessage, isA<Stream<Value>>());
      expect(client.onParticipantJoined, isA<Stream<Participant>>());
      expect(client.onParticipantLeft, isA<Stream<Participant>>());
      expect(client.onParticipantUpdated, isA<Stream<Participant>>());
      expect(client.onTracksUpdated, isA<Stream<Tracks>>());
    });

    test('all new streams are accessible', () {
      expect(client.onBotConnected, isA<Stream<Participant>>());
      expect(client.onBotDisconnected, isA<Stream<Participant>>());
      expect(client.onBotStarted, isA<Stream<Value?>>());
      expect(client.onTrackStarted, isA<Stream<(String, Participant)>>());
      expect(client.onTrackStopped, isA<Stream<(String, Participant)>>());
      expect(client.onScreenTrackStarted, isA<Stream<(String, Participant)>>());
      expect(client.onScreenTrackStopped, isA<Stream<(String, Participant)>>());
      expect(client.onScreenShareError, isA<Stream<String>>());
      expect(client.onInputsUpdated, isA<Stream<({bool camera, bool mic})>>());
      expect(client.onError, isA<Stream<PipecatException>>());
    });

    test('hardwareState starts with defaults', () {
      final state = client.hardwareState.value;
      expect(state.availableMics, isEmpty);
      expect(state.availableCams, isEmpty);
      expect(state.availableSpeakers, isEmpty);
      expect(state.selectedMic, isNull);
      expect(state.selectedCam, isNull);
      expect(state.selectedSpeaker, isNull);
      expect(state.isMicEnabled, false);
      expect(state.isCamEnabled, false);
    });

    test('registerFunctionHandler and unregister', () {
      client.registerFunctionHandler('test', (data) async => const ValueNull());
      client.unregisterFunctionHandler('test');
      // Should not throw
    });

    test('unregisterAllFunctionCallHandlers clears all', () {
      client.registerFunctionHandler('a', (data) async => const ValueNull());
      client.registerFunctionHandler('b', (data) async => const ValueNull());
      client.unregisterAllFunctionCallHandlers();
      // Should not throw
    });

    test('dispose can be called once', () {
      client.dispose();
      // Create a fresh one for tearDown
      client = PipecatClient();
    });
  });
}
