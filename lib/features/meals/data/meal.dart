import 'package:intl/intl.dart';

class Meal {
  final String id;
  final String name;
  final int calories;
  final int timestampMs;
  final String dateKey; // yyyy-MM-dd

  Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.timestampMs,
    required this.dateKey,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestampMs);
  String get timeLabel => DateFormat('HH:mm').format(dateTime);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'timestampMs': timestampMs,
        'dateKey': dateKey,
      };

  factory Meal.fromJson(Map j) => Meal(
        id: j['id'],
        name: j['name'],
        calories: j['calories'],
        timestampMs: j['timestampMs'],
        dateKey: j['dateKey'],
      );

  static String dateKeyFrom(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
