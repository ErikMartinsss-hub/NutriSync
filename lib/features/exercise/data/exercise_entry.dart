import 'package:intl/intl.dart';

class ExerciseEntry {
  final String id;
  final String type; // ex: Corrida moderada
  final String category; // Cardio / Musculação
  final String intensity; // Leve/Moderada/Intensa
  final int minutes;
  final int kcal;
  final int timestampMs;
  final String dateKey;

  ExerciseEntry({
    required this.id,
    required this.type,
    required this.category,
    required this.intensity,
    required this.minutes,
    required this.kcal,
    required this.timestampMs,
    required this.dateKey,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'category': category,
        'intensity': intensity,
        'minutes': minutes,
        'kcal': kcal,
        'timestampMs': timestampMs,
        'dateKey': dateKey,
      };
  factory ExerciseEntry.fromJson(Map j) => ExerciseEntry(
        id: j['id'],
        type: j['type'],
        category: j['category'],
        intensity: j['intensity'] ?? '',
        minutes: j['minutes'],
        kcal: j['kcal'],
        timestampMs: j['timestampMs'],
        dateKey: j['dateKey'],
      );
  static String dateKeyFrom(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
