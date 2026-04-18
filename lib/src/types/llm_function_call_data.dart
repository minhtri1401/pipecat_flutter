// lib/src/types/llm_function_call_data.dart
import 'value.dart';

/// Data for an LLM function call from the bot.
class LLMFunctionCallData {
  const LLMFunctionCallData({
    required this.functionName,
    required this.toolCallID,
    required this.args,
  });

  final String functionName;
  final String toolCallID;
  final Value args;

  Map<String, dynamic> toMap() => {
    'functionName': functionName,
    'toolCallID': toolCallID,
    'args': args.toJson(),
  };

  factory LLMFunctionCallData.fromMap(Map<String, dynamic> map) =>
      LLMFunctionCallData(
        functionName: map['functionName'] as String,
        toolCallID: map['toolCallID'] as String,
        args: Value.fromDynamic(map['args']) ?? const ValueObject({}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LLMFunctionCallData &&
          other.functionName == functionName &&
          other.toolCallID == toolCallID &&
          other.args == args;

  @override
  int get hashCode => Object.hash(functionName, toolCallID, args);
}
