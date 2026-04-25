import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat/src/types/pipecat_transport.dart';

void main() {
  group('PipecatTransport', () {
    test('DailyTransport extends PipecatTransport', () {
      const t = DailyTransport();
      expect(t, isA<PipecatTransport>());
    });

    test('SmallWebRTCTransport extends PipecatTransport', () {
      const t = SmallWebRTCTransport();
      expect(t, isA<PipecatTransport>());
    });

    test('exhaustive sealed switch compiles', () {
      const PipecatTransport t = DailyTransport();
      final name = switch (t) {
        DailyTransport() => 'daily',
        SmallWebRTCTransport() => 'smallWebRTC',
      };
      expect(name, 'daily');
    });
  });
}
