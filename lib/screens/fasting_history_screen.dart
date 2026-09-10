import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../design/tokens.dart';
import '../features/fasting/data/fasting_session.dart';
import '../features/fasting/presentation/fasting_provider.dart';

class FastingHistoryScreen extends ConsumerStatefulWidget {
  const FastingHistoryScreen({super.key});
  @override
  ConsumerState<FastingHistoryScreen> createState() => _State();
}

class _State extends ConsumerState<FastingHistoryScreen> {
  String _filter = '7 dias'; // Hoje, 7 dias, 30 dias, Todos

  List<FastingSession> _filtered(List<FastingSession> all) {
    final now = DateTime.now();
    DateTime cutoff;
    switch (_filter) {
      case 'Hoje':
        cutoff = DateTime(now.year, now.month, now.day);
        break;
      case '7 dias':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case '30 dias':
        cutoff = now.subtract(const Duration(days: 30));
        break;
      default:
        return all;
    }
    return all.where((s) => DateTime.fromMillisecondsSinceEpoch(s.createdAtMs).isAfter(cutoff)).toList();
  }

  String _fmt(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    if (h > 0 && m > 0) return '${h}h ${m}min';
    if (h > 0) return '${h}h';
    if (m > 0) return '${m} min';
    return '${sec}s';
  }

  String _statusPt(FastingStatus s) {
    switch (s) {
      case FastingStatus.active:
        return 'Ativo';
      case FastingStatus.paused:
        return 'Pausado';
      case FastingStatus.completed:
        return 'Concluído';
      case FastingStatus.cancelled:
        return 'Cancelado';
      case FastingStatus.idle:
        return 'Inativo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fasting = ref.watch(fastingProvider);
    final all = fasting.history;
    final list = _filtered(all);
    final totalSec = list.fold<int>(0, (s, e) => s + (e.status == FastingStatus.completed ? e.durationSeconds : e.elapsedSecondsOnPause > 0 ? e.elapsedSecondsOnPause : ((e.endTimeMs ?? e.startTimeMs) - e.startTimeMs) ~/ 1000));
    // inclui atual se hoje
    int curSec = 0;
    if (fasting.current != null && _filter != 'Todos') {
      final cd = DateTime.fromMillisecondsSinceEpoch(fasting.current!.createdAtMs);
      final now = DateTime.now();
      bool include = false;
      if (_filter == 'Hoje') include = cd.year == now.year && cd.month == now.month && cd.day == now.day;
      else if (_filter == '7 dias') include = cd.isAfter(now.subtract(const Duration(days: 7)));
      else if (_filter == '30 dias') include = cd.isAfter(now.subtract(const Duration(days: 30)));
      if (include) curSec = fasting.current!.elapsedSeconds(fasting.now);
    }
    final totalWithCur = totalSec + curSec;
    final avgSec = list.isEmpty ? 0 : totalSec ~/ list.length;
    final best = list.isEmpty ? 0 : list.map((e) => e.status == FastingStatus.completed ? e.durationSeconds : e.elapsedSecondsOnPause).reduce((a, b) => a > b ? a : b);

    // agrupa por dia para gráfico
    final Map<String, int> perDay = {};
    for (final s in list) {
      final k = DateFormat('dd/MM').format(DateTime.fromMillisecondsSinceEpoch(s.createdAtMs));
      final sec = s.status == FastingStatus.completed ? s.durationSeconds : s.elapsedSecondsOnPause;
      perDay[k] = (perDay[k] ?? 0) + sec;
    }
    final days = perDay.keys.toList();
    final maxSec = perDay.values.isEmpty ? 1 : perDay.values.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.bg, elevation: 0, title: Text('Meu Jejum', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)), centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // filtros
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Hoje', '7 dias', '30 dias', 'Todos']
                .map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: _filter == f,
                        selectedColor: AppColors.primary.withOpacity(0.15),
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        // resumo
        Row(children: [
          Expanded(child: _stat('Jejuns', '${list.length}', Icons.check_circle_outline, AppColors.primary)),
          const SizedBox(width: 8),
          Expanded(child: _stat('Tempo total', _fmt(totalWithCur), Icons.timer_outlined, AppColors.carb)),
          const SizedBox(width: 8),
          Expanded(child: _stat('Média', _fmt(avgSec), Icons.analytics_outlined, AppColors.protein)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _stat('Maior jejum', _fmt(best), Icons.emoji_events_outlined, AppColors.fat)),
          const SizedBox(width: 8),
          Expanded(child: _stat('Hoje', _fmt(curSec), Icons.today_rounded, AppColors.primary)),
        ]),
        const SizedBox(height: 16),
        // gráfico evolução
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Evolução', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (perDay.isEmpty)
              SizedBox(height: 120, child: Center(child: Text('Sem dados no período', style: TextStyle(color: AppColors.textMid, fontSize: 12))))
            else
              SizedBox(
                height: 130,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: days.map((d) {
                    final sec = perDay[d] ?? 0;
                    final ratio = maxSec == 0 ? 0.0 : sec / maxSec;
                    final h = ratio.isFinite ? ratio * 80 : 0.0;
                    return SizedBox(
                      width: 48,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Text(_fmt(sec), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Container(height: h.clamp(6, 80).toDouble(), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6))),
                          const SizedBox(height: 4),
                          Text(d, style: TextStyle(fontSize: 8, color: AppColors.textMid)),
                        ]),
                      ),
                    );
                  }).toList()),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        // lista
        ...list.map((s) {
          final dt = DateTime.fromMillisecondsSinceEpoch(s.createdAtMs);
          final sec = s.status == FastingStatus.completed ? s.durationSeconds : s.elapsedSecondsOnPause;
          final isCompleted = s.status == FastingStatus.completed;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isCompleted ? AppColors.primary.withOpacity(0.12) : Colors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(isCompleted ? Icons.check_circle : Icons.pause_circle, size: 18, color: isCompleted ? AppColors.primary : Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(dt)} • ${s.protocolName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                Text('${_fmt(sec)} • ${_statusPt(s.status)}', style: TextStyle(fontSize: 11, color: AppColors.textMid)),
              ])),
              Text(_fmt(sec), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ]),
          );
        }),
        if (list.isEmpty) Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)), child: Column(children: [Icon(Icons.timer_off, color: AppColors.textMid), const SizedBox(height: 8), Text('Nenhum jejum no período', style: TextStyle(color: AppColors.textMid, fontSize: 12))])),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData ic, Color c) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
        child: Column(children: [
          Icon(ic, size: 16, color: c),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.textMid)),
        ]),
      );
}
