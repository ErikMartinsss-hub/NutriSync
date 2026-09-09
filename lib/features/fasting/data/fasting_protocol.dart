class FastingProtocol {
  final String id;
  final String name;
  final int fastingHours;
  final int eatingHours;
  final String description;
  final bool isCustom;

  const FastingProtocol({
    required this.id,
    required this.name,
    required this.fastingHours,
    required this.eatingHours,
    required this.description,
    this.isCustom = false,
  });

  int get fastingMinutes => fastingHours * 60;

  static const List<FastingProtocol> predefined = [
    FastingProtocol(
      id: '12_12',
      name: '12:12',
      fastingHours: 12,
      eatingHours: 12,
      description: 'Iniciante - 12h jejum / 12h alimentação',
    ),
    FastingProtocol(
      id: '16_8',
      name: '16:8',
      fastingHours: 16,
      eatingHours: 8,
      description: 'Popular - 16h jejum / 8h alimentação',
    ),
    FastingProtocol(
      id: '18_6',
      name: '18:6',
      fastingHours: 18,
      eatingHours: 6,
      description: 'Avançado - 18h jejum / 6h alimentação',
    ),
  ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fastingHours': fastingHours,
        'eatingHours': eatingHours,
        'description': description,
        'isCustom': isCustom,
      };

  factory FastingProtocol.fromJson(Map j) => FastingProtocol(
        id: j['id'],
        name: j['name'],
        fastingHours: j['fastingHours'],
        eatingHours: j['eatingHours'],
        description: j['description'],
        isCustom: j['isCustom'] ?? false,
      );
}
