import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
import '../data/meal.dart';
import '../data/meal_repository.dart';

final mealRepoProvider = Provider<MealRepository>((ref) {
  final box = Hive.box('mamba_box');
  return MealRepository(box);
});

final mealsProvider = StateNotifierProvider<MealNotifier, List<Meal>>((ref) {
  final repo = ref.watch(mealRepoProvider);
  return MealNotifier(repo);
});

class MealNotifier extends StateNotifier<List<Meal>> {
  final MealRepository repo;
  MealNotifier(this.repo) : super(repo.getAll());

  void _refresh() => state = repo.getAll();

  Future<void> addMeal(String name, int calories, {DateTime? time}) async {
    final now = time ?? DateTime.now();
    final meal = Meal(
      id: const Uuid().v4(),
      name: name,
      calories: calories,
      timestampMs: now.millisecondsSinceEpoch,
      dateKey: Meal.dateKeyFrom(now),
    );
    await repo.add(meal);
    _refresh();
  }

  Future<void> updateMeal(String id, String name, int calories) async {
    final existing = state.firstWhere((m) => m.id == id);
    final updated = Meal(
      id: id,
      name: name,
      calories: calories,
      timestampMs: existing.timestampMs,
      dateKey: existing.dateKey,
    );
    await repo.update(updated);
    _refresh();
  }

  Future<void> deleteMeal(String id) async {
    await repo.delete(id);
    _refresh();
  }

  List<Meal> mealsForDate(String dateKey) => state.where((m) => m.dateKey == dateKey).toList();
  int totalForDate(String dateKey) => mealsForDate(dateKey).fold(0, (s, m) => s + m.calories);
}
