// lib/src/types/bot_ready_data.dart
import 'value.dart';

/// Data received when the bot is ready.
class BotReadyData {
  const BotReadyData({
    required this.version,
    this.about,
  });

  final String version;
  final Value? about;

  Map<String, dynamic> toMap() => {
    'version': version,
    'about': about?.toJson(),
  };

  factory BotReadyData.fromMap(Map<String, dynamic> map) => BotReadyData(
    version: map['version'] as String,
    about: Value.fromDynamic(map['about']),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BotReadyData && other.version == version && other.about == about;

  @override
  int get hashCode => Object.hash(version, about);
}
