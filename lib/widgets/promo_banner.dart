import 'package:flutter/material.dart';
import '../design/tokens.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0066FF), Color(0xFF0050CC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Desbloqueie o Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Receitas e planos personalizados', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.premium, borderRadius: BorderRadius.circular(AppRadius.pill)), child: const Text('Ver planos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
        ]),
      );
}
