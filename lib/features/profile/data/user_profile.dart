class UserProfile {
  final double weight; // kg atual
  final double targetWeight;
  final double height; // cm
  final int age;
  final String gender; // M/F
  final String goal; // perder/manter/ganhar
  final String pace; // leve/moderado/intenso
  final String? name;

  const UserProfile({
    required this.weight,
    required this.targetWeight,
    required this.height,
    required this.age,
    required this.gender,
    required this.goal,
    required this.pace,
    this.name,
  });

  double get progress {
    if (weight == targetWeight) return 1;
    // para perder: progresso = (inicial - atual)/(inicial - meta) -> sem inicial, usa simples
    return ((weight - targetWeight).abs() / weight).clamp(0, 1);
  }

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'targetWeight': targetWeight,
        'height': height,
        'age': age,
        'gender': gender,
        'goal': goal,
        'pace': pace,
        'name': name,
      };
  factory UserProfile.fromJson(Map j) => UserProfile(
        weight: (j['weight'] as num?)?.toDouble() ?? 88.7,
        targetWeight: (j['targetWeight'] as num?)?.toDouble() ?? 80.0,
        height: (j['height'] as num?)?.toDouble() ?? 170,
        age: j['age'] ?? 28,
        gender: j['gender'] ?? 'M',
        goal: j['goal'] ?? 'perder',
        pace: j['pace'] ?? 'moderado',
        name: j['name'],
      );

  UserProfile copyWith({double? weight, double? targetWeight, double? height, int? age, String? gender, String? goal, String? pace, String? name}) => UserProfile(
        weight: weight ?? this.weight,
        targetWeight: targetWeight ?? this.targetWeight,
        height: height ?? this.height,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        goal: goal ?? this.goal,
        pace: pace ?? this.pace,
        name: name ?? this.name,
      );
}
