import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat/src/types/transport_state.dart';

void main() {
  group('TransportState', () {
    test('fromString parses all valid states', () {
      expect(TransportState.fromString('disconnected'), TransportState.disconnected);
      expect(TransportState.fromString('initializing'), TransportState.initializing);
      expect(TransportState.fromString('initialized'), TransportState.initialized);
      expect(TransportState.fromString('authenticating'), TransportState.authenticating);
      expect(TransportState.fromString('authenticated'), TransportState.authenticated);
      expect(TransportState.fromString('connecting'), TransportState.connecting);
      expect(TransportState.fromString('connected'), TransportState.connected);
      expect(TransportState.fromString('ready'), TransportState.ready);
      expect(TransportState.fromString('disconnecting'), TransportState.disconnecting);
      expect(TransportState.fromString('error'), TransportState.error);
    });

    test('fromString returns error for unknown string', () {
      expect(TransportState.fromString('garbage'), TransportState.error);
      expect(TransportState.fromString(''), TransportState.error);
      expect(TransportState.fromString('CONNECTED'), TransportState.error);
    });
  });
}
