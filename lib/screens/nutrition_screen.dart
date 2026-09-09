import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/tokens.dart';
import '../widgets/donut_chart.dart';
import '../widgets/nutrient_table.dart';
import '../features/meals/data/meal.dart';
import '../features/meals/presentation/meal_provider.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});
  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _period = 'Hoje';
  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this, initialIndex: 2); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final meals = ref.watch(mealsProvider);
    final todayKey = Meal.dateKeyFrom(DateTime.now());
    final key = _period == 'Hoje' ? todayKey : Meal.dateKeyFrom(DateTime.now().subtract(const Duration(days: 1)));
    final dayMeals = meals.where((m) => m.dateKey == key).toList();
    final totalKcal = dayMeals.fold<int>(0, (s, m) => s + m.calories);
    final carbG = (totalKcal * 0.5 / 4).round();
    final fatG = (totalKcal * 0.25 / 9).round();
    final protG = (totalKcal * 0.25 / 4).round();
    final totalMacro = (carbG + fatG + protG).toDouble().clamp(1, 9999);
    final carbPct = carbG / totalMacro * 100;
    final fatPct = fatG / totalMacro * 100;
    final protPct = protG / totalMacro * 100;

    // para aba calorias: quebra por refeição
    int byHour(int start, int end) => dayMeals.where((m) { final h = DateTime.fromMillisecondsSinceEpoch(m.timestampMs).hour; return h >= start && h < end; }).fold(0, (s, m) => s + m.calories);
    final cafe = byHour(0, 11), almoco = byHour(11, 15), jantar = byHour(18, 24), lanche = byHour(15, 18);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark), onPressed: () => Navigator.maybePop(context)),
        title: const Text('Nutrição', style: AppText.title),
        centerTitle: true,
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMid,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          tabs: const [Tab(text: 'CALORIAS'), Tab(text: 'NUTRIENTES'), Tab(text: 'MACROS')],
        ),
      ),
      body: Column(children: [
        // seletor de período
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.pill), boxShadow: AppShadows.card),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(onPressed: () => setState(() => _period = _period == 'Hoje' ? 'Ontem' : 'Hoje'), icon: const Icon(Icons.chevron_left_rounded)),
              Column(children: [const Text('Visualização do dia', style: AppText.small), Text(_period, style: AppText.value.copyWith(fontSize: 14))]),
              IconButton(onPressed: () => setState(() => _period = _period == 'Hoje' ? 'Ontem' : 'Hoje'), icon: const Icon(Icons.chevron_right_rounded)),
            ]),
          ),
        ),
        Expanded(
          child: TabBarView(controller: _tab, children: [
            // CALORIAS
            ListView(padding: const EdgeInsets.all(16), children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card), child: MealDonut(breakfast: cafe, lunch: almoco, dinner: jantar, snack: lanche)),
              const SizedBox(height: 12),
              _summaryCard('Total de calorias', '$totalKcal cal'),
              _summaryCard('Saldo Calórico', '${2458 - totalKcal} cal'),
              _summaryCard('Meta', '2458 cal'),
            ]),
            // NUTRIENTES
            ListView(padding: const EdgeInsets.all(16), children: [
              NutrientTable(rows: [
                (name: 'Proteínas', total: protG, goal: 123),
                (name: 'Carboidratos', total: carbG, goal: 308),
                (name: 'Fibra', total: (carbG * 0.08).round(), goal: 25),
                (name: 'Açúcar', total: (carbG * 0.15).round(), goal: 50),
                (name: 'Gorduras Totais', total: fatG, goal: 82),
                (name: 'Saturadas', total: (fatG * 0.3).round(), goal: 20),
                (name: 'Trans', total: 0, goal: 2),
              ]),
            ]),
            // MACROS
            ListView(padding: const EdgeInsets.all(16), children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card), child: Column(children: [
                MacroDonut(carbPct: carbPct, fatPct: fatPct, proteinPct: protPct),
                const SizedBox(height: 12),
                _macroLegend('Carboidratos', AppColors.carb, carbPct, 50),
                _macroLegend('Gorduras', AppColors.fat, fatPct, 30),
                _macroLegend('Proteínas', AppColors.protein, protPct, 20),
              ])),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Alimentos com mais Carboidratos', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...dayMeals.take(3).map((m) => ListTile(dense: true, leading: const Icon(Icons.restaurant, size: 18, color: AppColors.carb), title: Text(m.name, style: const TextStyle(fontSize: 12)), trailing: Text('${m.calories} cal', style: AppText.label))),
                if (dayMeals.isEmpty) const Text('Nenhum alimento hoje', style: AppText.small),
              ])),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _summaryCard(String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: AppText.label), Text(value, style: AppText.value.copyWith(fontSize: 14))]),
      );

  Widget _macroLegend(String label, Color c, double pct, double meta) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
          Text('${pct.toStringAsFixed(0)}% (meta ${meta.toStringAsFixed(0)}%)', style: AppText.small),
        ]),
      );
}
