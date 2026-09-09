import 'package:flutter/material.dart';
import '../design/tokens.dart';

class DiaryTile extends StatelessWidget {
  const DiaryTile({super.key, required this.icon, required this.title, required this.kcal, this.onTap});
  final IconData icon;
  final String title;
  final int kcal;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.primary, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppText.value.copyWith(fontSize: 13)),
            Text(kcal == 0 ? 'Nenhum alimento' : '$kcal cal', style: AppText.small),
          ])),
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Text('Registre', style: AppText.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      );
}
