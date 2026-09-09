import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_fast_tracker/features/meals/data/meal.dart';

void main() {
  group('Meal', () {
    test('dateKeyFrom gera yyyy-MM-dd', () {
      final d = DateTime(2026, 9, 9);
      expect(Meal.dateKeyFrom(d), '2026-09-09');
    });

    test('timeLabel formata HH:mm', () {
      final m = Meal(
        id: '1',
        name: 'Arroz',
        calories: 200,
        timestampMs: DateTime(2026, 9, 9, 13, 30).millisecondsSinceEpoch,
        dateKey: '2026-09-09',
      );
      expect(m.timeLabel, '13:30');
    });

    test('mealType default é almoco', () {
      final m = Meal(
        id: '1',
        name: 'X',
        calories: 1,
        timestampMs: 0,
        dateKey: '2026-09-09',
      );
      expect(m.mealType, 'almoco');
    });

    test('round-trip json preserva campos', () {
      final m = Meal(
        id: '1',
        name: 'Pão',
        calories: 150,
        timestampMs: 0,
        dateKey: '2026-09-09',
        mealType: 'cafe',
      );
      final back = Meal.fromJson(m.toJson());
      expect(back.id, '1');
      expect(back.name, 'Pão');
      expect(back.calories, 150);
      expect(back.mealType, 'cafe');
    });
  });
}