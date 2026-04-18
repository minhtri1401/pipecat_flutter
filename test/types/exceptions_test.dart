// test/types/exceptions_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat/src/types/exceptions.dart';

void main() {
  group('PipecatException', () {
    test('has message and optional code', () {
      const e = PipecatException('test error', code: 'E001');
      expect(e.message, 'test error');
      expect(e.code, 'E001');
    });

    test('code is optional', () {
      const e = PipecatException('test error');
      expect(e.code, isNull);
    });

    test('toString includes message and code', () {
      const e = PipecatException('msg', code: 'C');
      expect(e.toString(), contains('msg'));
      expect(e.toString(), contains('C'));
    });

    test('toString with no code omits code', () {
      const e = PipecatException('msg');
      expect(e.toString(), contains('msg'));
      expect(e.toString(), isNot(contains('code:')));
    });
  });

  group('PipecatConnectionException', () {
    test('is a PipecatException', () {
      const e = PipecatConnectionException('conn failed');
      expect(e, isA<PipecatException>());
      expect(e.message, 'conn failed');
    });
  });

  group('PipecatFunctionCallException', () {
    test('is a PipecatException', () {
      const e = PipecatFunctionCallException('fn failed');
      expect(e, isA<PipecatException>());
      expect(e.message, 'fn failed');
    });
  });
}
