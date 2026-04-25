import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat/src/types/exceptions.dart';

class _A {}
class _B {}

void main() {
  group('PipecatTransportMismatchException', () {
    test('subclass of PipecatException', () {
      final ex = PipecatTransportMismatchException(_A, _B);
      expect(ex, isA<PipecatException>());
    });

    test('carries the two types', () {
      final ex = PipecatTransportMismatchException(_A, _B);
      expect(ex.transportType, _A);
      expect(ex.paramsType, _B);
    });

    test('code is transport-mismatch', () {
      final ex = PipecatTransportMismatchException(_A, _B);
      expect(ex.code, 'transport-mismatch');
    });

    test('message names both types', () {
      final ex = PipecatTransportMismatchException(_A, _B);
      expect(ex.message, contains('_A'));
      expect(ex.message, contains('_B'));
    });
  });
}
