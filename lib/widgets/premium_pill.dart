import 'package:flutter/material.dart';
import '../design/tokens.dart';

class PremiumPill extends StatelessWidget {
  const PremiumPill({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppColors.premium, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.workspace_premium_rounded, size: 14, color: AppColors.textDark),
          const SizedBox(width: 4),
          Text('Seja Premium', style: AppText.label.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 11)),
        ]),
      );
}
