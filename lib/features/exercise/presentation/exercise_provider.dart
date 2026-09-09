import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/exercise_entry.dart';
import '../data/exercise_repository.dart';

final exerciseRepoProvider = Provider<ExerciseRepository>((ref) {
  final box = Hive.box('mamba_box');
  final auth = ref.watch(authProvider);
  return ExerciseRepository(box, auth.userId);
});

final exercisesProvider = StateNotifierProvider.autoDispose<ExerciseNotifier, List<ExerciseEntry>>((ref) {
  final repo = ref.watch(exerciseRepoProvider);
  return ExerciseNotifier(repo);
});

class ExerciseNotifier extends StateNotifier<List<ExerciseEntry>> {
  final ExerciseRepository repo;
  ExerciseNotifier(this.repo) : super(repo.getAll());

  void _refresh() => state = repo.getAll();

  Future<void> add({required String type, required String category, required String intensity, required int minutes, required int kcal}) async {
    final now = DateTime.now();
    final e = ExerciseEntry(
      id: const Uuid().v4(),
      type: type,
      category: category,
      intensity: intensity,
      minutes: minutes,
      kcal: kcal,
      timestampMs: now.millisecondsSinceEpoch,
      dateKey: ExerciseEntry.dateKeyFrom(now),
    );
    await repo.add(e);
    _refresh();
  }

  Future<void> remove(String id) async {
    await repo.delete(id);
    _refresh();
  }
}
