// test/types/data_classes_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat/src/types/enums.dart';
import 'package:pipecat/src/types/media_device_info.dart';
import 'package:pipecat/src/types/participant.dart';
import 'package:pipecat/src/types/transcript.dart';
import 'package:pipecat/src/types/bot_ready_data.dart';
import 'package:pipecat/src/types/bot_output_data.dart';
import 'package:pipecat/src/types/llm_function_call_data.dart';
import 'package:pipecat/src/types/api_request.dart';
import 'package:pipecat/src/types/pipecat_metrics.dart';
import 'package:pipecat/src/types/tracks.dart';
import 'package:pipecat/src/types/search_response.dart';
import 'package:pipecat/src/types/hardware_state.dart';
import 'package:pipecat/src/types/value.dart';

void main() {
  group('MediaDeviceInfo', () {
    test('fromMap/toMap round-trip', () {
      final info = MediaDeviceInfo(id: 'mic-1', label: 'Built-in', type: MediaDeviceType.microphone);
      final rebuilt = MediaDeviceInfo.fromMap(info.toMap());
      expect(rebuilt, info);
    });

    test('fromMap parses native bridge type strings', () {
      final info = MediaDeviceInfo.fromMap({'id': '1', 'label': 'Cam', 'type': 'cam'});
      expect(info.type, MediaDeviceType.camera);
    });
  });

  group('Participant', () {
    test('fromMap/toMap round-trip', () {
      final p = Participant(id: 'p-1', name: 'Alice', local: false);
      expect(Participant.fromMap(p.toMap()), p);
    });

    test('fromMap with null name', () {
      final p = Participant.fromMap({'id': 'p-1', 'name': null, 'local': true});
      expect(p.name, isNull);
      expect(p.local, isTrue);
    });
  });

  group('Transcript', () {
    test('fromMap/toMap round-trip', () {
      final t = Transcript(text: 'hello', finalStatus: true, timestamp: '123', userId: 'u1');
      expect(Transcript.fromMap(t.toMap()), t);
    });
  });

  group('BotReadyData', () {
    test('fromMap/toMap round-trip with Value about', () {
      final d = BotReadyData(version: '1.0', about: ValueString('test bot'));
      final rebuilt = BotReadyData.fromMap(d.toMap());
      expect(rebuilt.version, '1.0');
      expect(rebuilt.about, isA<ValueString>());
      expect((rebuilt.about as ValueString).value, 'test bot');
    });

    test('fromMap with null about', () {
      final d = BotReadyData.fromMap({'version': '1.0', 'about': null});
      expect(d.about, isNull);
    });
  });

  group('BotOutputData', () {
    test('fromMap/toMap round-trip', () {
      final d = BotOutputData(text: 'hi', spoken: true, aggregatedBy: 'word');
      expect(BotOutputData.fromMap(d.toMap()), d);
    });
  });

  group('LLMFunctionCallData', () {
    test('fromMap/toMap round-trip', () {
      final d = LLMFunctionCallData(
        functionName: 'get_weather',
        toolCallID: 'call-1',
        args: ValueObject({'city': const ValueString('Hanoi')}),
      );
      final rebuilt = LLMFunctionCallData.fromMap(d.toMap());
      expect(rebuilt.functionName, 'get_weather');
      expect(rebuilt.toolCallID, 'call-1');
      expect(rebuilt.args, isA<ValueObject>());
    });
  });

  group('ApiRequest', () {
    test('fromMap/toMap round-trip', () {
      final r = ApiRequest(endpoint: 'https://example.com', timeoutMs: 5000);
      final rebuilt = ApiRequest.fromMap(r.toMap());
      expect(rebuilt, r);
    });
  });

  group('PipecatMetrics', () {
    test('fromMap/toMap round-trip', () {
      final m = PipecatMetrics(
        processing: [PipecatMetricsData(processor: 'llm', value: 1.5)],
        ttfb: [PipecatMetricsData(processor: 'tts', value: 0.3)],
      );
      final rebuilt = PipecatMetrics.fromMap(m.toMap());
      expect(rebuilt.processing!.length, 1);
      expect(rebuilt.processing!.first.processor, 'llm');
      expect(rebuilt.ttfb!.first.value, 0.3);
    });
  });

  group('Tracks', () {
    test('fromMap/toMap round-trip', () {
      final t = Tracks(
        local: ParticipantTracks(
          audio: MediaStreamTrack(id: 'a1', kind: TrackKind.audio, enabled: true),
        ),
        bot: ParticipantTracks(
          video: MediaStreamTrack(id: 'v1', kind: TrackKind.video, enabled: false),
        ),
      );
      final rebuilt = Tracks.fromMap(t.toMap());
      expect(rebuilt.local.audio!.id, 'a1');
      expect(rebuilt.local.audio!.kind, TrackKind.audio);
      expect(rebuilt.bot!.video!.kind, TrackKind.video);
    });
  });

  group('BotLLMSearchResponseData', () {
    test('fromMap/toMap round-trip', () {
      final r = BotLLMSearchResponseData(query: 'test?', results: ['a', 'b']);
      final rebuilt = BotLLMSearchResponseData.fromMap(r.toMap());
      expect(rebuilt.query, 'test?');
      expect(rebuilt.results, ['a', 'b']);
    });
  });

  group('HardwareState', () {
    test('copyWith replaces non-nullable fields', () {
      final state = HardwareState(isMicEnabled: true);
      final updated = state.copyWith(isMicEnabled: false);
      expect(updated.isMicEnabled, false);
    });

    test('copyWith can set selectedMic to null', () {
      final mic = MediaDeviceInfo(id: '1', label: 'Mic', type: MediaDeviceType.microphone);
      final state = HardwareState(selectedMic: mic);
      final cleared = state.copyWith(selectedMic: () => null);
      expect(cleared.selectedMic, isNull);
    });

    test('copyWith preserves selectedMic when not passed', () {
      final mic = MediaDeviceInfo(id: '1', label: 'Mic', type: MediaDeviceType.microphone);
      final state = HardwareState(selectedMic: mic);
      final same = state.copyWith(isMicEnabled: true);
      expect(same.selectedMic, mic);
    });

    test('copyWith can set selectedMic to a new value', () {
      final mic = MediaDeviceInfo(id: '2', label: 'New Mic', type: MediaDeviceType.microphone);
      final state = HardwareState();
      final updated = state.copyWith(selectedMic: () => mic);
      expect(updated.selectedMic, mic);
    });
  });
}
