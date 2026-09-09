import 'package:flutter/material.dart';
import '../design/tokens.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({super.key, required this.onTap, this.todayKcal = 0, this.todayMin = 0});
  final VoidCallback onTap;
  final int todayKcal, todayMin;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.fitness_center_rounded, color: Colors.orange, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Exercício', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text(todayMin == 0 ? 'Toque para registrar' : '$todayMin min • $todayKcal kcal hoje', style: AppText.small),
            ])),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: Colors.white, size: 18)),
          ]),
        ),
      );
}
