/// A single warm-up movement - deliberately simpler than Exercise (no
/// equipment/injury filtering needed, since warm-ups are always bodyweight
/// and low-intensity by design).
class WarmupExercise {
  final String name;
  final String instruction;
  final int durationSeconds;

  const WarmupExercise({
    required this.name,
    required this.instruction,
    required this.durationSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'instruction': instruction,
      'durationSeconds': durationSeconds,
    };
  }

  factory WarmupExercise.fromMap(Map<String, dynamic> map) {
    return WarmupExercise(
      name: map['name'] as String? ?? 'Warm-up',
      instruction: map['instruction'] as String? ?? '',
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 30,
    );
  }
}
