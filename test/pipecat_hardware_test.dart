// test/pipecat_hardware_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat/pipecat.dart';
import 'package:pipecat/src/pipecat_api.g.dart' as pigeon;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HardwareState Updates', () {
    late PipecatClient client;
    const codec = pigeon.PipecatClientCallbacks.pigeonChannelCodec;
    late TestDefaultBinaryMessenger messenger;

    setUp(() {
      client = PipecatClient(transport: const DailyTransport());
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

    test('onCamUpdated updates selectedCam', () async {
      expect(client.hardwareState.value.selectedCam, isNull);

      await sendCallback('onCamUpdated', [pigeon.MediaDeviceInfo(id: 'cam-1', label: 'FaceTime', type: 'cam')]);

      expect(client.hardwareState.value.selectedCam, isNotNull);
      expect(client.hardwareState.value.selectedCam!.id, 'cam-1');
      expect(client.hardwareState.value.selectedCam!.type, MediaDeviceType.camera);
    });

    test('onMicUpdated updates selectedMic', () async {
      await sendCallback('onMicUpdated', [pigeon.MediaDeviceInfo(id: 'mic-1', label: 'Built-in', type: 'mic')]);
      expect(client.hardwareState.value.selectedMic!.id, 'mic-1');
      expect(client.hardwareState.value.selectedMic!.type, MediaDeviceType.microphone);
    });

    test('onAvailableCamsUpdated updates list', () async {
      await sendCallback('onAvailableCamsUpdated', [
        [
          pigeon.MediaDeviceInfo(id: 'c1', label: 'Cam 1', type: 'cam'),
          pigeon.MediaDeviceInfo(id: 'c2', label: 'Cam 2', type: 'cam'),
        ],
      ]);
      expect(client.hardwareState.value.availableCams.length, 2);
    });

    test('onInputsUpdated updates mic/cam enabled state', () async {
      final events = <({bool camera, bool mic})>[];
      client.onInputsUpdated.listen((e) => events.add(e));

      await sendCallback('onInputsUpdated', [true, false]);

      expect(events.length, 1);
      expect(events.first.camera, true);
      expect(events.first.mic, false);
      expect(client.hardwareState.value.isCamEnabled, true);
      expect(client.hardwareState.value.isMicEnabled, false);
    });

    test('onAvailableMicsUpdated updates list', () async {
      await sendCallback('onAvailableMicsUpdated', [
        [
          pigeon.MediaDeviceInfo(id: 'm1', label: 'Mic 1', type: 'mic'),
        ],
      ]);
      expect(client.hardwareState.value.availableMics.length, 1);
    });

    test('onAvailableSpeakersUpdated updates list', () async {
      await sendCallback('onAvailableSpeakersUpdated', [
        [
          pigeon.MediaDeviceInfo(id: 's1', label: 'Speaker 1', type: 'output'),
        ],
      ]);
      expect(client.hardwareState.value.availableSpeakers.length, 1);
    });

    test('onSpeakerUpdated updates selectedSpeaker', () async {
      expect(client.hardwareState.value.selectedSpeaker, isNull);

      await sendCallback('onSpeakerUpdated', [pigeon.MediaDeviceInfo(id: 'spk-1', label: 'AirPods', type: 'output')]);

      expect(client.hardwareState.value.selectedSpeaker, isNotNull);
      expect(client.hardwareState.value.selectedSpeaker!.id, 'spk-1');
      expect(client.hardwareState.value.selectedSpeaker!.type, MediaDeviceType.speaker);
    });
  });

  group('HardwareState copyWith', () {
    test('can set selectedMic to null', () {
      final mic = MediaDeviceInfo(id: '1', label: 'Mic', type: MediaDeviceType.microphone);
      final state = HardwareState(selectedMic: mic);
      final cleared = state.copyWith(selectedMic: () => null);
      expect(cleared.selectedMic, isNull);
    });

    test('preserves selectedMic when not passed', () {
      final mic = MediaDeviceInfo(id: '1', label: 'Mic', type: MediaDeviceType.microphone);
      final state = HardwareState(selectedMic: mic);
      final same = state.copyWith(isMicEnabled: true);
      expect(same.selectedMic, mic);
    });
  });
}
