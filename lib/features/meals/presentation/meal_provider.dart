import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/analytics_service.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/meal.dart';
import '../data/meal_repository.dart';

final mealRepoProvider = Provider<MealRepository>((ref) {
  final box = Hive.box('mamba_box');
  final auth = ref.watch(authProvider);
  return MealRepository(box, auth.userId);
});

final mealsProvider = StateNotifierProvider.autoDispose<MealNotifier, List<Meal>>((ref) {
  final repo = ref.watch(mealRepoProvider);
  return MealNotifier(repo);
});

class MealNotifier extends StateNotifier<List<Meal>> {
  final MealRepository repo;
  MealNotifier(this.repo) : super(repo.getAll());

  void _refresh() => state = repo.getAll();

  Future<void> addMeal(String name, int calories, {DateTime? time, String mealType = 'almoco'}) async {
    final now = time ?? DateTime.now();
    final meal = Meal(
      id: const Uuid().v4(),
      name: name,
      calories: calories,
      timestampMs: now.millisecondsSinceEpoch,
      dateKey: Meal.dateKeyFrom(now),
      mealType: mealType,
    );
    await repo.add(meal);
    _refresh();
    AnalyticsService.logEvent('meal_added', {'calories': calories, 'meal_type': mealType});
  }

  Future<void> updateMeal(String id, String name, int calories, {String? mealType}) async {
    final existing = state.firstWhere((m) => m.id == id);
    final updated = Meal(
      id: id,
      name: name,
      calories: calories,
      timestampMs: existing.timestampMs,
      dateKey: existing.dateKey,
      mealType: mealType ?? existing.mealType,
    );
    await repo.update(updated);
    _refresh();
    AnalyticsService.logEvent('meal_updated', {'calories': calories, 'meal_type': mealType ?? ''});
  }

  Future<void> deleteMeal(String id) async {
    await repo.delete(id);
    _refresh();
    AnalyticsService.logEvent('meal_deleted');
  }

  List<Meal> mealsForDate(String dateKey) => state.where((m) => m.dateKey == dateKey).toList();
  int totalForDate(String dateKey) => mealsForDate(dateKey).fold(0, (s, m) => s + m.calories);
}
