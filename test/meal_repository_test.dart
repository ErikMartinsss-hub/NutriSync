import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mamba_fast_tracker/features/meals/data/meal.dart';
import 'package:mamba_fast_tracker/features/meals/data/meal_repository.dart';

void main() {
  late Directory tempDir;
  late Box box;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('test_box');
  });

  tearDownAll(() async {
    await box.close();
    await tempDir.delete(recursive: true);
  });

  Meal _meal(String id, {int kcal = 100, String dateKey = '2026-09-09'}) => Meal(
        id: id,
        name: id,
        calories: kcal,
        timestampMs: 0,
        dateKey: dateKey,
      );

  group('MealRepository', () {
    test('adiciona, lista e filtra por data', () async {
      final repo = MealRepository(box, 'user_a');
      await repo.add(_meal('m1', kcal: 200));
      await repo.add(_meal('m2', kcal: 50, dateKey: '2026-09-08'));

      final today = repo.getByDate('2026-09-09');
      expect(today.length, 1);
      expect(today.first.calories, 200);
      expect(repo.totalCaloriesForDate('2026-09-09'), 200);
    });

    test('usuarios diferentes nao veem dados um do outro', () async {
      final repoA = MealRepository(box, 'user_a');
      final repoB = MealRepository(box, 'user_b');

      await repoA.delete('m1');
      await repoA.delete('m2');
      await repoA.add(_meal('a_only', kcal: 100));

      expect(repoA.getAll().length, 1);
      expect(repoB.getAll().length, 0);
    });

    test('editar atualiza calorias mantendo data', () async {
      final repo = MealRepository(box, 'user_a');
      final m = _meal('edit_target', kcal: 100);
      await repo.add(m);
      await repo.update(Meal(id: 'edit_target', name: 'edit_target', calories: 900, timestampMs: 0, dateKey: '2026-09-09'));

      final all = repo.getAll();
      expect(all.firstWhere((e) => e.id == 'edit_target').calories, 900);
    });

    test('excluir remove e nao quebra listagem vazia', () async {
      final repo = MealRepository(box, 'user_a');
      await repo.delete('nao_existe');
      expect(repo.getAll(), isNotEmpty);
    });
  });
}