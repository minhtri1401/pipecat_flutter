// test/types/value_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat/src/types/value.dart';

void main() {
  group('Value', () {
    group('fromDynamic', () {
      test('returns null for null input', () {
        expect(Value.fromDynamic(null), isNull);
      });

      test('parses bool', () {
        final value = Value.fromDynamic(true);
        expect(value, isA<ValueBool>());
        expect((value as ValueBool).value, true);
      });

      test('parses int', () {
        final value = Value.fromDynamic(42);
        expect(value, isA<ValueNumber>());
        expect((value as ValueNumber).value, 42);
      });

      test('parses double', () {
        final value = Value.fromDynamic(3.14);
        expect(value, isA<ValueNumber>());
        expect((value as ValueNumber).value, 3.14);
      });

      test('parses string', () {
        final value = Value.fromDynamic('hello');
        expect(value, isA<ValueString>());
        expect((value as ValueString).value, 'hello');
      });

      test('parses empty string', () {
        final value = Value.fromDynamic('');
        expect(value, isA<ValueString>());
        expect((value as ValueString).value, '');
      });

      test('parses list with mixed types', () {
        final value = Value.fromDynamic([1, 'two', true, null]);
        expect(value, isA<ValueArray>());
        final arr = (value as ValueArray).items;
        expect(arr.length, 4);
        expect(arr[0], isA<ValueNumber>());
        expect(arr[1], isA<ValueString>());
        expect(arr[2], isA<ValueBool>());
        expect(arr[3], isA<ValueNull>());
      });

      test('parses empty list', () {
        final value = Value.fromDynamic([]);
        expect(value, isA<ValueArray>());
        expect((value as ValueArray).items, isEmpty);
      });

      test('parses map', () {
        final value = Value.fromDynamic({'key': 'val', 'num': 1});
        expect(value, isA<ValueObject>());
        final obj = (value as ValueObject).properties;
        expect(obj['key'], isA<ValueString>());
        expect(obj['num'], isA<ValueNumber>());
      });

      test('parses empty map', () {
        final value = Value.fromDynamic({});
        expect(value, isA<ValueObject>());
        expect((value as ValueObject).properties, isEmpty);
      });

      test('parses nested structures', () {
        final value = Value.fromDynamic({
          'users': [
            {'name': 'Alice', 'age': 30},
            {'name': 'Bob', 'age': null},
          ],
        });
        expect(value, isA<ValueObject>());
        final users = ((value as ValueObject).properties['users'] as ValueArray).items;
        expect(users.length, 2);
        final bob = (users[1] as ValueObject).properties;
        expect(bob['age'], isA<ValueNull>());
      });
    });

    group('toJson', () {
      test('ValueNull returns null', () {
        expect(const ValueNull().toJson(), isNull);
      });

      test('ValueBool returns bool', () {
        expect(const ValueBool(true).toJson(), true);
      });

      test('ValueNumber returns num', () {
        expect(const ValueNumber(42).toJson(), 42);
        expect(const ValueNumber(3.14).toJson(), 3.14);
      });

      test('ValueString returns string', () {
        expect(const ValueString('hello').toJson(), 'hello');
      });

      test('ValueArray returns list', () {
        final arr = ValueArray([const ValueNumber(1), const ValueString('two')]);
        expect(arr.toJson(), [1, 'two']);
      });

      test('ValueObject returns map', () {
        final obj = ValueObject({'a': const ValueNumber(1)});
        expect(obj.toJson(), {'a': 1});
      });
    });

    group('round-trip', () {
      test('primitives survive round-trip', () {
        for (final input in [true, false, 0, 1, -1, 3.14, '', 'hello']) {
          final value = Value.fromDynamic(input)!;
          expect(value.toJson(), input);
        }
      });

      test('complex structure survives round-trip', () {
        final input = {
          'name': 'test',
          'count': 42,
          'active': true,
          'tags': ['a', 'b'],
          'meta': {'nested': true},
          'empty': <String, dynamic>{},
          'items': <dynamic>[],
        };
        final value = Value.fromDynamic(input)!;
        expect(value.toJson(), input);
      });
    });

    group('equality', () {
      test('ValueNull instances are equal', () {
        expect(const ValueNull(), const ValueNull());
      });

      test('ValueBool equality', () {
        expect(const ValueBool(true), const ValueBool(true));
        expect(const ValueBool(true), isNot(const ValueBool(false)));
      });

      test('ValueNumber equality', () {
        expect(const ValueNumber(42), const ValueNumber(42));
        expect(const ValueNumber(42), isNot(const ValueNumber(43)));
      });

      test('ValueString equality', () {
        expect(const ValueString('a'), const ValueString('a'));
        expect(const ValueString('a'), isNot(const ValueString('b')));
      });

      test('ValueArray equality', () {
        expect(ValueArray([const ValueNumber(1)]), ValueArray([const ValueNumber(1)]));
        expect(ValueArray([const ValueNumber(1)]), isNot(ValueArray([const ValueNumber(2)])));
      });

      test('ValueObject equality', () {
        expect(
          ValueObject({'a': const ValueNumber(1)}),
          ValueObject({'a': const ValueNumber(1)}),
        );
        expect(
          ValueObject({'a': const ValueNumber(1)}),
          isNot(ValueObject({'b': const ValueNumber(1)})),
        );
      });
    });

    group('fromJsonString / toJsonString', () {
      test('parses JSON string', () {
        final value = Value.fromJsonString('{"key": "val"}');
        expect(value, isA<ValueObject>());
      });

      test('returns null for null JSON string', () {
        expect(Value.fromJsonString(null), isNull);
      });

      test('returns null for invalid JSON string', () {
        expect(Value.fromJsonString('not json {{{'), isNull);
      });

      test('converts to JSON string', () {
        final value = ValueObject({'key': const ValueString('val')});
        expect(value.toJsonString(), '{"key":"val"}');
      });
    });

    group('tryFromJsonString', () {
      test('returns null for null input', () {
        expect(Value.tryFromJsonString(null), isNull);
      });

      test('parses valid JSON', () {
        final v = Value.tryFromJsonString('{"a":1}');
        expect(v, isA<ValueObject>());
        expect(((v as ValueObject).properties['a'] as ValueNumber).value, 1);
      });

      test('throws FormatException on empty string', () {
        expect(
          () => Value.tryFromJsonString(''),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException on malformed JSON', () {
        expect(
          () => Value.tryFromJsonString('{not json'),
          throwsA(isA<FormatException>()),
        );
      });
    });
  });
}
