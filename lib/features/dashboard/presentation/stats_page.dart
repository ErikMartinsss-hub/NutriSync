import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../fasting/presentation/fasting_provider.dart';
import '../../fasting/data/fasting_session.dart';
import '../../meals/data/meal.dart';
import '../../meals/presentation/meal_provider.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});
  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  bool showCalories = true;

  @override
  Widget build(BuildContext context) {
    final meals = ref.watch(mealsProvider);
    final fasting = ref.watch(fastingProvider);

    final days = List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));
    final keys = days.map((d) => Meal.dateKeyFrom(d)).toList();
    final labels = days.map((d) => DateFormat('dd/MM').format(d)).toList();

    final caloriesData = keys.map((k) => meals.where((m) => m.dateKey == k).fold<int>(0, (s, m) => s + m.calories)).toList();
    final fastingData = keys.map((k) {
      int sec = 0;
      for (final h in fasting.history) {
        final hk = DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(h.createdAtMs));
        if (hk == k) {
          if (h.status == FastingStatus.completed) {
            sec += h.durationSeconds;
          } else {
            final elapsed = h.elapsedSecondsOnPause > 0 ? h.elapsedSecondsOnPause : ((h.endTimeMs ?? h.startTimeMs) - h.startTimeMs) ~/ 1000;
            sec += elapsed;
          }
        }
      }
      if (k == Meal.dateKeyFrom(DateTime.now()) && fasting.current != null) {
        sec += fasting.current!.elapsedSeconds(fasting.now);
      }
      return sec / 3600;
    }).toList();

    final data = showCalories ? caloriesData.map((e) => e.toDouble()).toList() : fastingData;
    final maxVal = data.isEmpty ? 10.0 : data.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal == 0 ? 10.0 : maxVal * 1.3 + 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Evolução semanal', style: TextStyle(fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Calorias'), icon: Icon(Icons.local_fire_department)),
                ButtonSegment(value: false, label: Text('Jejum (h)'), icon: Icon(Icons.timer)),
              ],
              selected: {showCalories},
              onSelectionChanged: (s) => setState(() => showCalories = s.first),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 220,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final h = maxY == 0 ? 0.0 : (data[i] / maxY * 160).clamp(4.0, 160.0);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(showCalories ? '${data[i].toInt()}' : '${data[i].toStringAsFixed(1)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Container(
                                height: h,
                                decoration: BoxDecoration(
                                  color: showCalories ? const Color(0xFF0FA37A) : Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(labels[i], style: const TextStyle(fontSize: 10, color: Colors.black54)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(showCalories ? 'Resumo calorias' : 'Resumo jejum', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      showCalories
                          ? 'Média: ${(caloriesData.isEmpty ? 0 : caloriesData.reduce((a, b) => a + b) / 7).toStringAsFixed(0)} kcal/dia • Total 7d: ${caloriesData.fold(0, (a, b) => a + b)} kcal'
                          : 'Média: ${(fastingData.reduce((a, b) => a + b) / 7).toStringAsFixed(1)} h/dia • Total 7d: ${fastingData.fold(0.0, (a, b) => a + b).toStringAsFixed(1)} h',
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(
                      7,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(labels[i], style: const TextStyle(color: Colors.black54)),
                            Text(
                              showCalories ? '${caloriesData[i]} kcal' : '${fastingData[i].toStringAsFixed(1)} h',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
