import 'package:hive_ce/hive.dart';
import 'meal.dart';

class MealRepository {
  final Box box;
  MealRepository(this.box);
  static const _key = 'meals_list';

  List<Meal> getAll() {
    final list = box.get(_key) as List?;
    if (list == null) return [];
    return list.map((e) => Meal.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _saveAll(List<Meal> meals) async {
    await box.put(_key, meals.map((e) => e.toJson()).toList());
  }

  Future<void> add(Meal m) async {
    final all = getAll();
    all.add(m);
    await _saveAll(all);
  }

  Future<void> update(Meal m) async {
    final all = getAll();
    final idx = all.indexWhere((e) => e.id == m.id);
    if (idx != -1) {
      all[idx] = m;
      await _saveAll(all);
    }
  }

  Future<void> delete(String id) async {
    final all = getAll()..removeWhere((e) => e.id == id);
    await _saveAll(all);
  }

  List<Meal> getByDate(String dateKey) =>
      getAll().where((m) => m.dateKey == dateKey).toList();

  int totalCaloriesForDate(String dateKey) =>
      getByDate(dateKey).fold(0, (sum, m) => sum + m.calories);

  Map<String, int> last7DaysTotals() {
    final now = DateTime.now();
    final map = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final k = Meal.dateKeyFrom(d);
      map[k] = totalCaloriesForDate(k);
    }
    return map;
  }
}
