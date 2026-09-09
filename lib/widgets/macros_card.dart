import 'package:flutter/material.dart';
import '../design/tokens.dart';

class MacrosCard extends StatelessWidget {
  const MacrosCard({super.key, required this.carb, required this.fat, required this.protein});
  final ({int cur, int goal}) carb, fat, protein;

  Widget _col(Color col, String label, int cur, int goal) => Expanded(
        child: Column(children: [
          Container(width: 48, height: 4, decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          Text(label, style: AppText.label),
          const SizedBox(height: 4),
          Text('$cur g / $goal', style: AppText.value.copyWith(fontSize: 13)),
        ]),
      );

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
        child: Row(children: [
          _col(AppColors.carb, 'Carb', carb.cur, carb.goal),
          Container(width: 1, height: 40, color: AppColors.border),
          _col(AppColors.fat, 'Gorduras', fat.cur, fat.goal),
          Container(width: 1, height: 40, color: AppColors.border),
          _col(AppColors.protein, 'Proteínas', protein.cur, protein.goal),
        ]),
      );
}
