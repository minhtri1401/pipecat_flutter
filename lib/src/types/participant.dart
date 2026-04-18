// lib/src/types/participant.dart

/// A participant in a Pipecat session.
class Participant {
  const Participant({
    required this.id,
    this.name,
    required this.local,
  });

  final String id;
  final String? name;
  final bool local;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'local': local,
  };

  factory Participant.fromMap(Map<String, dynamic> map) => Participant(
    id: map['id'] as String,
    name: map['name'] as String?,
    local: map['local'] as bool,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Participant && other.id == id && other.name == name && other.local == local;

  @override
  int get hashCode => Object.hash(id, name, local);

  @override
  String toString() => 'Participant(id: $id, name: $name, local: $local)';
}
