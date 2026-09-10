import 'package:flutter/material.dart';
import '../design/tokens.dart';

class DaySelector extends StatefulWidget {
  const DaySelector({super.key, required this.onSelect, this.initial = 0});
  final ValueChanged<int> onSelect;
  final int initial;
  @override
  State<DaySelector> createState() => _DaySelectorState();
}

class _DaySelectorState extends State<DaySelector> {
  late int sel;
  static const _week = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  @override
  void initState() { super.initState(); sel = widget.initial; }
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final date = todayStart.add(Duration(days: i));
          final isToday = i == 0;
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
                Text(_week[date.weekday - 1], style: TextStyle(color: isSel ? Colors.white : AppColors.textMid, fontWeight: FontWeight.w600, fontSize: 11)),
                const SizedBox(height: 2),
                Text('${date.day}', style: TextStyle(color: isSel ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 13)),
                if (isToday)
                  Text('HOJE', style: TextStyle(color: isSel ? Colors.white70 : AppColors.primary, fontWeight: FontWeight.w800, fontSize: 7)),
              ]),
            ),
          );
        },
      ),
    );
  }
}
