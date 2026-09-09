import 'package:flutter/material.dart';
import '../design/tokens.dart';

class DaySelector extends StatefulWidget {
  const DaySelector({super.key, required this.onSelect, this.initial = 1});
  final ValueChanged<int> onSelect;
  final int initial;
  @override
  State<DaySelector> createState() => _DaySelectorState();
}

class _DaySelectorState extends State<DaySelector> {
  late int sel;
  @override
  void initState() { super.initState(); sel = widget.initial; }
  @override
  Widget build(BuildContext context) {
    final labs = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isSel = i == sel;
          return GestureDetector(
            onTap: () { setState(() => sel = i); widget.onSelect(i); },
            child: Container(
              width: 44,
              decoration: BoxDecoration(
                color: isSel ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSel ? AppShadows.card : [],
                border: Border.all(color: isSel ? Colors.transparent : AppColors.border),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(labs[i], style: TextStyle(color: isSel ? Colors.white : AppColors.textMid, fontWeight: FontWeight.w600, fontSize: 11)),
                const SizedBox(height: 2),
                Text('${15 + i}', style: TextStyle(color: isSel ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
          );
        },
      ),
    );
  }
}
