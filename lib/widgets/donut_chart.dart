import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../design/tokens.dart';

class MacroDonut extends StatelessWidget {
  const MacroDonut({super.key, required this.carbPct, required this.fatPct, required this.proteinPct});
  final double carbPct, fatPct, proteinPct;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 180,
        child: PieChart(PieChartData(centerSpaceRadius: 58, sectionsSpace: 2, sections: [
          PieChartSectionData(value: carbPct, color: AppColors.carb, title: '${carbPct.toStringAsFixed(0)}%', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11), radius: 36),
          PieChartSectionData(value: fatPct, color: AppColors.fat, title: '${fatPct.toStringAsFixed(0)}%', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11), radius: 36),
          PieChartSectionData(value: proteinPct, color: AppColors.protein, title: '${proteinPct.toStringAsFixed(0)}%', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11), radius: 36),
        ])),
      );
}

class MealDonut extends StatelessWidget {
  const MealDonut({super.key, required this.breakfast, required this.lunch, required this.dinner, required this.snack});
  final int breakfast, lunch, dinner, snack;
  @override
  Widget build(BuildContext context) {
    final total = (breakfast + lunch + dinner + snack).toDouble();
    if (total == 0) return const SizedBox(height: 180, child: Center(child: Text('Sem dados', style: AppText.label)));
    return SizedBox(height: 180, child: PieChart(PieChartData(centerSpaceRadius: 58, sectionsSpace: 2, sections: [
      PieChartSectionData(value: breakfast / total * 100, color: AppColors.primary, title: 'Café'),
      PieChartSectionData(value: lunch / total * 100, color: AppColors.carb, title: 'Almoço'),
      PieChartSectionData(value: dinner / total * 100, color: AppColors.protein, title: 'Jantar'),
      PieChartSectionData(value: snack / total * 100, color: AppColors.fat, title: 'Lanches'),
    ])));
  }
}
