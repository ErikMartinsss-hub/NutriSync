import 'package:flutter/material.dart';
import '../design/tokens.dart';

class CalorieCard extends StatelessWidget {
  const CalorieCard({super.key, required this.consumed, required this.goal, this.burned = 0});
  final int consumed, goal, burned;
  @override
  Widget build(BuildContext context) {
    final available = goal + burned;
    final pct = (consumed / available).clamp(0.0, 1.0);
    final restantes = available - consumed;
    final saved = restantes > 0 ? restantes : 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          RichText(text: TextSpan(children: [
            TextSpan(text: '$consumed', style: AppText.value.copyWith(fontSize: 20)),
            TextSpan(text: ' cal / $available', style: AppText.label.copyWith(fontSize: 13)),
          ])),
          Text('$restantes restantes', style: AppText.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: AppColors.bg, valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
        ),
        if (burned > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('🔥 Exercício: +$burned kcal na cota', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.orange)),
          ),
        ],
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Economizadas hoje', style: AppText.small),
          Text('$saved kcal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: saved > 0 ? AppColors.primary : AppColors.textMid)),
        ]),
      ]),
    );
  }
}