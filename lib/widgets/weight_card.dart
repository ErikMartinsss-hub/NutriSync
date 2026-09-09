import 'package:flutter/material.dart';
import '../design/tokens.dart';

class WeightCard extends StatelessWidget {
  const WeightCard({super.key, required this.current, required this.target, required this.onTap});
  final double current, target;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final diff = (current - target).abs();
    final double progress = (1 - (diff / current).clamp(0, 1)).clamp(0.0, 1.0).toDouble();
    final isPerder = current > target;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.monitor_weight_rounded, size: 16, color: AppColors.primary)), const SizedBox(width: 8), const Text('Peso', style: TextStyle(fontWeight: FontWeight.w700))]),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMid),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Atual', style: AppText.small), Text('${current.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textDark))])),
            Container(width: 1, height: 36, color: AppColors.border),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [const Text('Meta', style: AppText.small), Text('${target.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary))])),
            Container(width: 1, height: 36, color: AppColors.border),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(isPerder ? 'Faltam' : 'Ganhar', style: AppText.small), Text('${diff.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))])),
          ]),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: AppColors.bg, valueColor: AlwaysStoppedAnimation(isPerder ? AppColors.primary : Colors.green))),
          const SizedBox(height: 6),
          Text('${(progress * 100).toStringAsFixed(0)}% concluído', style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
        ]),
      ),
    );
  }
}
