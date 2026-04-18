// lib/src/types/value.dart
import 'dart:convert';

/// A type-safe representation of a JSON value.
///
/// Use [Value.fromDynamic] to parse decoded JSON and [toJson] to convert back.
/// Use [Value.fromJsonString] / [toJsonString] for raw JSON string conversion.
sealed class Value {
  const Value();

  /// Parses a decoded JSON value into a [Value].
  ///
  /// Returns `null` if [raw] is `null`. Inside arrays and objects,
  /// `null` entries become [ValueNull].
  static Value? fromDynamic(dynamic raw) {
    if (raw == null) return null;
    return _fromDynamicNonNull(raw);
  }

  /// Internal recursive parser that uses [ValueNull] for null entries.
  static Value _fromDynamicNonNull(dynamic raw) {
    if (raw == null) return const ValueNull();
    if (raw is bool) return ValueBool(raw);
    if (raw is num) return ValueNumber(raw);
    if (raw is String) return ValueString(raw);
    if (raw is List) {
      return ValueArray(raw.map(_fromDynamicNonNull).toList());
    }
    if (raw is Map) {
      return ValueObject(
        raw.map((k, v) => MapEntry(k.toString(), _fromDynamicNonNull(v))),
      );
    }
    return ValueString(raw.toString());
  }

  /// Parses a JSON string into a [Value].
  ///
  /// Returns `null` if [jsonString] is `null` or not valid JSON.
  static Value? fromJsonString(String? jsonString) {
    if (jsonString == null) return null;
    try {
      return fromDynamic(jsonDecode(jsonString));
    } catch (_) {
      return null;
    }
  }

  /// Converts this [Value] back to a JSON-compatible Dart object.
  dynamic toJson();

  /// Converts this [Value] to a JSON string.
  String toJsonString() => jsonEncode(toJson());
}

/// Represents a JSON `null` inside arrays or objects.
class ValueNull extends Value {
  const ValueNull();

  @override
  dynamic toJson() => null;

  @override
  bool operator ==(Object other) => other is ValueNull;

  @override
  int get hashCode => null.hashCode;
}

/// Represents a JSON boolean.
class ValueBool extends Value {
  const ValueBool(this.value);
  final bool value;

  @override
  dynamic toJson() => value;

  @override
  bool operator ==(Object other) => other is ValueBool && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Represents a JSON number (int or double).
class ValueNumber extends Value {
  const ValueNumber(this.value);
  final num value;

  @override
  dynamic toJson() => value;

  @override
  bool operator ==(Object other) =>
      other is ValueNumber && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Represents a JSON string.
class ValueString extends Value {
  const ValueString(this.value);
  final String value;

  @override
  dynamic toJson() => value;

  @override
  bool operator ==(Object other) =>
      other is ValueString && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Represents a JSON array.
class ValueArray extends Value {
  const ValueArray(this.items);
  final List<Value> items;

  @override
  dynamic toJson() => items.map((e) => e.toJson()).toList();

  @override
  bool operator ==(Object other) {
    if (other is! ValueArray || other.items.length != items.length) return false;
    for (var i = 0; i < items.length; i++) {
      if (items[i] != other.items[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(items);
}

/// Represents a JSON object.
class ValueObject extends Value {
  const ValueObject(this.properties);
  final Map<String, Value> properties;

  @override
  dynamic toJson() =>
      properties.map((k, v) => MapEntry(k, v.toJson()));

  @override
  bool operator ==(Object other) {
    if (other is! ValueObject ||
        other.properties.length != properties.length) {
      return false;
    }
    for (final key in properties.keys) {
      if (properties[key] != other.properties[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final sortedEntries = properties.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Object.hashAll(sortedEntries.map((e) => Object.hash(e.key, e.value)));
  }
}
