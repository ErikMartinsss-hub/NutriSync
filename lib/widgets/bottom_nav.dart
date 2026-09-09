import 'package:flutter/material.dart';
import '../design/tokens.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;
  Widget _item(IconData ic, String lb, int i) => InkWell(
        onTap: () => onTap(i),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(ic, size: 22, color: index == i ? AppColors.primary : AppColors.textMid),
          const SizedBox(height: 2),
          Text(lb, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: index == i ? AppColors.primary : AppColors.textMid)),
        ]),
      );
  @override
  Widget build(BuildContext context) => BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: AppColors.card,
        elevation: 8,
        child: SizedBox(
          height: 56,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _item(Icons.home_rounded, 'Hoje', 0),
            _item(Icons.show_chart_rounded, 'Progresso', 1),
            const SizedBox(width: 48),
            _item(Icons.more_horiz_rounded, 'Mais', 2),
          ]),
        ),
      );
}
