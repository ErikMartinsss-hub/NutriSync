import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_fast_tracker/features/fasting/data/fasting_session.dart';

void main() {
  group('FastingSession', () {
    test('elapsedSeconds calcula corretamente ativo', () {
      final now = DateTime.now();
      final start = now.subtract(const Duration(hours: 2));
      final s = FastingSession(
        id: '1',
        protocolId: '16_8',
        protocolName: '16:8',
        durationMinutes: 16 * 60,
        startTimeMs: start.millisecondsSinceEpoch,
        status: FastingStatus.active,
        createdAtMs: start.millisecondsSinceEpoch,
      );
      final elapsed = s.elapsedSeconds(now);
      expect(elapsed, closeTo(7200, 2));
    });

    test('progress 50% em metade do tempo', () {
      final now = DateTime.now();
      final start = now.subtract(const Duration(hours: 8));
      final s = FastingSession(
        id: '1',
        protocolId: '16_8',
        protocolName: '16:8',
        durationMinutes: 960,
        startTimeMs: start.millisecondsSinceEpoch,
        status: FastingStatus.active,
        createdAtMs: start.millisecondsSinceEpoch,
      );
      expect(s.progress(now), closeTo(0.5, 0.01));
    });

    test('pausado retorna elapsedSecondsOnPause', () {
      final s = FastingSession(
        id: '1',
        protocolId: '16_8',
        protocolName: '16:8',
        durationMinutes: 960,
        startTimeMs: 0,
        status: FastingStatus.paused,
        elapsedSecondsOnPause: 3600,
        createdAtMs: 0,
      );
      expect(s.elapsedSeconds(DateTime.now()), 3600);
      expect(s.remainingSeconds(DateTime.now()), 960 * 60 - 3600);
    });

    test('remainingSeconds clampa em 0', () {
      final now = DateTime.now();
      final start = now.subtract(const Duration(hours: 20));
      final s = FastingSession(
        id: '1',
        protocolId: '16_8',
        protocolName: '16:8',
        durationMinutes: 960,
        startTimeMs: start.millisecondsSinceEpoch,
        status: FastingStatus.active,
        createdAtMs: start.millisecondsSinceEpoch,
      );
      expect(s.remainingSeconds(now), 0);
      expect(s.progress(now), 1.0);
    });
  });
}
