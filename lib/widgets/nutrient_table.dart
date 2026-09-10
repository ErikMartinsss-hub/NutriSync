import 'package:flutter/material.dart';
import '../design/tokens.dart';

class NutrientTable extends StatelessWidget {
  const NutrientTable({super.key, required this.rows});
  final List<({String name, int total, int goal})> rows;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card))),
            child: Row(children: [
              Expanded(child: Text('Nutriente', style: AppText.label)),
              SizedBox(width: 60, child: Text('Total', style: AppText.label)),
              SizedBox(width: 60, child: Text('Meta', style: AppText.label)),
              SizedBox(width: 60, child: Text('Saldo', style: AppText.label)),
            ]),
          ),
          ...rows.map((r) {
            final saldo = (r.goal - r.total).clamp(0, 9999);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                Expanded(child: Text(r.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                SizedBox(width: 60, child: Text('${r.total}g', style: AppText.label.copyWith(color: AppColors.textDark))),
                SizedBox(width: 60, child: Text('${r.goal}g', style: AppText.label)),
                SizedBox(width: 60, child: Text('${saldo}g', style: AppText.label.copyWith(color: saldo == 0 ? Colors.green : AppColors.textMid))),
              ]),
            );
          }),
        ]),
      );
}
