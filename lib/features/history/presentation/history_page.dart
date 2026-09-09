import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../fasting/presentation/fasting_provider.dart';
import '../../fasting/data/fasting_session.dart';
import '../../meals/data/meal.dart';
import '../../meals/presentation/meal_provider.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  String _statusPt(FastingStatus s) {
    switch (s) {
      case FastingStatus.active: return 'Ativo';
      case FastingStatus.paused: return 'Pausado';
      case FastingStatus.completed: return 'Concluído';
      case FastingStatus.cancelled: return 'Cancelado';
      case FastingStatus.idle: return 'Inativo';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fasting = ref.watch(fastingProvider);
    final meals = ref.watch(mealsProvider);
    // group by date
    final dates = <String>{};
    for (final h in fasting.history) {
      dates.add(DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(h.createdAtMs)));
    }
    for (final m in meals) {
      dates.add(m.dateKey);
    }
    final sorted = dates.toList()..sort((a, b) => b.compareTo(a));
    // ensure today exists
    final today = Meal.dateKeyFrom(DateTime.now());
    if (!sorted.contains(today)) sorted.insert(0, today);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico', style: TextStyle(fontWeight: FontWeight.w700))),
      body: sorted.isEmpty
          ? const Center(child: Text('Nenhum dado ainda'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              itemBuilder: (_, i) {
                final dateKey = sorted[i];
                final d = DateFormat('yyyy-MM-dd').parse(dateKey);
                final dayMeals = meals.where((m) => m.dateKey == dateKey).toList();
                final totalCal = dayMeals.fold<int>(0, (s, m) => s + m.calories);
                final dayFasts = fasting.history.where((h) => DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(h.createdAtMs)) == dateKey).toList();
                final totalFastSec = dayFasts.fold<int>(0, (s, h) {
                  if (h.status == FastingStatus.completed) return s + h.durationSeconds;
                  return s + (h.elapsedSecondsOnPause > 0 ? h.elapsedSecondsOnPause : ((h.endTimeMs ?? h.startTimeMs) - h.startTimeMs) ~/ 1000);
                });
                // include current if today
                int curSec = 0;
                if (dateKey == today && fasting.current != null) {
                  curSec = fasting.current!.elapsedSeconds(fasting.now);
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(DateFormat('dd/MM/yyyy').format(d), style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('$totalCal kcal • ${(totalFastSec + curSec) ~/ 3600}h ${(totalFastSec + curSec) % 3600 ~/ 60}min jejum • ${dayMeals.length} refeições'),
                    children: [
                      if (dayFasts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Jejuns', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              ...dayFasts.map((h) => ListTile(
                                    dense: true,
                                    leading: Icon(
                                      h.status == FastingStatus.completed ? Icons.check_circle : Icons.cancel,
                                      color: h.status == FastingStatus.completed ? Colors.green : Colors.orange,
                                      size: 18,
                                    ),
                                    title: Text('${h.protocolName} — ${h.durationMinutes ~/ 60}h'),
                                    subtitle: Text('${DateFormat('HH:mm', 'pt_BR').format(DateTime.fromMillisecondsSinceEpoch(h.startTimeMs))} • ${_statusPt(h.status)}'),
                                    trailing: Text('${(h.durationSeconds ~/ 60)} min'),
                                  )),
                            ],
                          ),
                        ),
                      if (dayMeals.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Refeições', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ...dayMeals.map((m) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.restaurant, size: 18),
                                  title: Text(m.name),
                                  subtitle: Text(m.timeLabel),
                                  trailing: Text('${m.calories} kcal', style: const TextStyle(fontWeight: FontWeight.w700)),
                                )),
                          ]),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
