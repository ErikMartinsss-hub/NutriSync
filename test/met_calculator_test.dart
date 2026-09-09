import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_fast_tracker/features/exercise/data/met_calculator.dart';

void main() {
  group('MetCalculator', () {
    test('MET de caminhada é 3.8', () {
      expect(MetCalculator.metFor(category: 'Cardio', type: 'Caminhada rápida (5 km/h)'), 3.8);
    });

    test('MET de corrida é 8.0', () {
      expect(MetCalculator.metFor(category: 'Cardio', type: 'Corrida moderada (8 km/h)'), 8.0);
    });

    test('MET padrão de cardio desconhecido é 5.0', () {
      expect(MetCalculator.metFor(category: 'Cardio', type: 'Zumba'), 5.0);
    });

    test('MET de musculação intensa é 6.0', () {
      expect(MetCalculator.metFor(category: 'Musculação', intensity: 'Intensa'), 6.0);
    });

    test('kcal = MET x peso x horas (30 min, 80kg, corrida)', () {
      final kcal = MetCalculator.kcals(8.0, 80, 30);
      expect(kcal, (8.0 * 80 * 0.5).round());
      expect(kcal, 320);
    });

    test('kcal com 60 min = MET x peso', () {
      final kcal = MetCalculator.kcals(3.8, 70, 60);
      expect(kcal, 266);
    });
  });
}