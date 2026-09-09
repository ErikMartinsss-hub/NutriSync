import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_fast_tracker/features/fasting/data/fasting_protocol.dart';

void main() {
  group('FastingProtocol', () {
    test('predefined tem os 3 protocolos exigidos', () {
      final names = FastingProtocol.predefined.map((p) => p.name).toList();
      expect(names, containsAll(['12:12', '16:8', '18:6']));
    });

    test('fastingMinutes converte horas em minutos', () {
      final p = FastingProtocol.predefined.firstWhere((p) => p.name == '16:8');
      expect(p.fastingMinutes, 16 * 60);
    });

    test('custom protocol é marcado isCustom', () {
      const p = FastingProtocol(
        id: 'custom_1',
        name: '20:4',
        fastingHours: 20,
        eatingHours: 4,
        description: 'custom',
        isCustom: true,
      );
      expect(p.isCustom, true);
    });

    test('round-trip json preserva os campos', () {
      const p = FastingProtocol(
        id: 'x',
        name: '18:6',
        fastingHours: 18,
        eatingHours: 6,
        description: 'desc',
        isCustom: true,
      );
      final back = FastingProtocol.fromJson(p.toJson());
      expect(back.id, 'x');
      expect(back.name, '18:6');
      expect(back.fastingHours, 18);
      expect(back.eatingHours, 6);
      expect(back.description, 'desc');
      expect(back.isCustom, true);
    });
  });
}