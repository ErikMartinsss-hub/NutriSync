import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/fasting_protocol.dart';
import '../data/fasting_repository.dart';
import '../data/fasting_session.dart';

final fastingRepoProvider = Provider<FastingRepository>((ref) {
  final box = Hive.box('mamba_box');
  final auth = ref.watch(authProvider);
  return FastingRepository(box, auth.userId);
});

final fastingProvider = StateNotifierProvider.autoDispose<FastingNotifier, FastingState>((ref) {
  final repo = ref.watch(fastingRepoProvider);
  return FastingNotifier(repo);
});

class FastingState {
  final FastingProtocol selectedProtocol;
  final List<FastingProtocol> customProtocols;
  final FastingSession? current;
  final List<FastingSession> history;
  final DateTime now; // tick

  const FastingState({
    required this.selectedProtocol,
    required this.customProtocols,
    this.current,
    required this.history,
    required this.now,
  });

  FastingState copyWith({
    FastingProtocol? selectedProtocol,
    List<FastingProtocol>? customProtocols,
    FastingSession? current,
    bool clearCurrent = false,
    List<FastingSession>? history,
    DateTime? now,
  }) =>
      FastingState(
        selectedProtocol: selectedProtocol ?? this.selectedProtocol,
        customProtocols: customProtocols ?? this.customProtocols,
        current: clearCurrent ? null : (current ?? this.current),
        history: history ?? this.history,
        now: now ?? this.now,
      );
}

class FastingNotifier extends StateNotifier<FastingState> {
  final FastingRepository repo;
  Timer? _ticker;

  FastingNotifier(this.repo)
      : super(FastingState(
          selectedProtocol: repo.getSelectedProtocol(),
          customProtocols: repo.getCustomProtocols(),
          current: repo.getCurrentSession(),
          history: repo.getHistory(),
          now: DateTime.now(),
        )) {
    _startTicker();
    _checkCompletion();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(now: DateTime.now());
      _checkCompletion();
    });
  }

  void _checkCompletion() {
    final c = state.current;
    if (c != null && c.status == FastingStatus.active) {
      if (c.elapsedSeconds(state.now) >= c.durationSeconds) {
        // complete
        final completed = c.copyWith(
          status: FastingStatus.completed,
          endTimeMs: c.startTimeMs + c.durationSeconds * 1000,
        );
        repo.saveCurrentSession(null);
        repo.addToHistory(completed);
        NotificationService.showInstant(
          id: 999,
          title: 'Jejum concluído! 🎉',
          body: 'Seu jejum ${c.protocolName} terminou. Bom trabalho!',
        );
        NotificationService.cancel(c.hashCode);
        state = state.copyWith(clearCurrent: true, history: repo.getHistory());
      }
    }
  }

  Future<void> selectProtocol(FastingProtocol p) async {
    await repo.setSelectedProtocol(p);
    state = state.copyWith(selectedProtocol: p);
  }

  Future<void> addCustomProtocol(int fastingH, int eatingH) async {
    final p = FastingProtocol(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: '$fastingH:$eatingH',
      fastingHours: fastingH,
      eatingHours: eatingH,
      description: 'Custom - $fastingH h jejum / $eatingH h alimentação',
      isCustom: true,
    );
    await repo.addCustomProtocol(p);
    await repo.setSelectedProtocol(p);
    state = state.copyWith(
      selectedProtocol: p,
      customProtocols: repo.getCustomProtocols(),
    );
  }

  Future<void> startFasting() async {
    if (state.current != null && state.current!.status == FastingStatus.active) return;
    final protocol = state.selectedProtocol;
    final now = DateTime.now();
    final session = FastingSession(
      id: const Uuid().v4(),
      protocolId: protocol.id,
      protocolName: protocol.name,
      durationMinutes: protocol.fastingMinutes,
      startTimeMs: now.millisecondsSinceEpoch,
      status: FastingStatus.active,
      createdAtMs: now.millisecondsSinceEpoch,
    );
    await repo.saveCurrentSession(session);
    state = state.copyWith(current: session);

    await NotificationService.showInstant(
      id: 1001,
      title: 'Jejum iniciado ⏱️',
      body: 'Protocolo ${protocol.name} — ${protocol.fastingHours}h de foco!',
    );
    await NotificationService.scheduleFastingEnd(
      id: session.id.hashCode,
      title: 'Jejum concluído! 🎉',
      body: 'Seu jejum ${protocol.name} terminou.',
      scheduledDate: now.add(Duration(minutes: protocol.fastingMinutes)),
    );
  }

  Future<void> pauseFasting() async {
    final c = state.current;
    if (c == null || c.status != FastingStatus.active) return;
    final elapsed = c.elapsedSeconds(state.now);
    final paused = c.copyWith(status: FastingStatus.paused, elapsedSecondsOnPause: elapsed);
    await repo.saveCurrentSession(paused);
    try { await NotificationService.cancel(c.id.hashCode); } catch (_) {}
    // força rebuild imediato com now congelado para não continuar contando
    state = state.copyWith(current: paused, now: DateTime.now());
    // debug
    // ignore: avoid_print
    print('[MAMBA] pause: elapsed=$elapsed status=${paused.status}');
  }

  Future<void> resumeFasting() async {
    final c = state.current;
    if (c == null || c.status != FastingStatus.paused) return;
    final now = DateTime.now();
    final newStart = now.millisecondsSinceEpoch - c.elapsedSecondsOnPause * 1000;
    final resumed = c.copyWith(status: FastingStatus.active, startTimeMs: newStart);
    await repo.saveCurrentSession(resumed);
    state = state.copyWith(current: resumed, now: now);
    final remainingSec = resumed.durationSeconds - resumed.elapsedSeconds(now);
    try {
      await NotificationService.scheduleFastingEnd(
        id: resumed.id.hashCode,
        title: 'Jejum concluído! 🎉',
        body: 'Seu jejum ${resumed.protocolName} terminou.',
        scheduledDate: now.add(Duration(seconds: remainingSec)),
      );
    } catch (_) {}
    print('[MAMBA] resume: elapsedOnPause=${c.elapsedSecondsOnPause} newStart=$newStart');
  }

  Future<void> stopFasting({bool complete = false}) async {
    final c = state.current;
    if (c == null) return;
    await NotificationService.cancel(c.id.hashCode);
    if (complete) {
      final completed = c.copyWith(status: FastingStatus.completed, endTimeMs: DateTime.now().millisecondsSinceEpoch);
      await repo.addToHistory(completed);
    } else {
      final cancelled = c.copyWith(
        status: FastingStatus.cancelled,
        endTimeMs: DateTime.now().millisecondsSinceEpoch,
        elapsedSecondsOnPause: c.status == FastingStatus.paused ? c.elapsedSecondsOnPause : c.elapsedSeconds(state.now),
      );
      // only save to history if lasted > 1 min
      if (cancelled.elapsedSeconds(DateTime.now()) > 60) {
        await repo.addToHistory(cancelled);
      }
    }
    await repo.saveCurrentSession(null);
    state = state.copyWith(clearCurrent: true, history: repo.getHistory());
    if (complete) {
      await NotificationService.showInstant(id: 999, title: 'Jejum encerrado', body: 'Jejum finalizado com sucesso!');
    }
  }

  // For daily total fasting time
  Duration totalFastingToday() {
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    // sum from history + current elapsed if today
    int totalSec = 0;
    for (final h in state.history) {
      final d = DateTime.fromMillisecondsSinceEpoch(h.createdAtMs);
      final k = d.toIso8601String().substring(0, 10);
      if (k == todayKey) {
        // duration actually fasted
        if (h.status == FastingStatus.completed) totalSec += h.durationSeconds;
        else if (h.status == FastingStatus.cancelled) totalSec += h.elapsedSeconds(DateTime.fromMillisecondsSinceEpoch(h.endTimeMs ?? h.startTimeMs));
      }
    }
    final c = state.current;
    if (c != null) {
      final cd = DateTime.fromMillisecondsSinceEpoch(c.createdAtMs).toIso8601String().substring(0, 10);
      if (cd == todayKey) totalSec += c.elapsedSeconds(state.now);
    }
    return Duration(seconds: totalSec);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
