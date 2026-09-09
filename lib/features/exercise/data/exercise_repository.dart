import 'package:hive/hive.dart';
import 'exercise_entry.dart';

class ExerciseRepository {
  final Box box;
  final String userId;
  ExerciseRepository(this.box, this.userId);
  late final String _key = 'exercises_$userId';

  List<ExerciseEntry> getAll() {
    final list = box.get(_key) as List?;
    if (list == null) return [];
    try { return list.map((e) => ExerciseEntry.fromJson(Map<String, dynamic>.from(e as Map))).toList(); } catch (_) { return []; }
  }

  Future<void> _saveAll(List<ExerciseEntry> l) async => box.put(_key, l.map((e) => e.toJson()).toList());

  Future<void> add(ExerciseEntry e) async {
    final all = getAll()..add(e);
    await _saveAll(all);
  }

  Future<void> delete(String id) async {
    final all = getAll()..removeWhere((e) => e.id == id);
    await _saveAll(all);
  }

  List<ExerciseEntry> byDate(String dateKey) => getAll().where((e) => e.dateKey == dateKey).toList();
  int totalKcalFor(String dateKey) => byDate(dateKey).fold(0, (s, e) => s + e.kcal);
  int totalMinFor(String dateKey) => byDate(dateKey).fold(0, (s, e) => s + e.minutes);
}
