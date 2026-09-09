import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../fasting/data/fasting_protocol.dart';
import '../../fasting/data/fasting_session.dart';
import '../../fasting/presentation/fasting_provider.dart';
import '../../meals/data/meal.dart';
import '../../meals/presentation/meal_provider.dart';
import '../../history/presentation/history_page.dart';
import 'stats_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String _fmt(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fasting = ref.watch(fastingProvider);
    final fastingNotifier = ref.read(fastingProvider.notifier);
    final meals = ref.watch(mealsProvider);
    final todayKey = Meal.dateKeyFrom(DateTime.now());
    final todayMeals = meals.where((m) => m.dateKey == todayKey).toList();
    final totalCalories = todayMeals.fold<int>(0, (s, m) => s + m.calories);
    final c = fasting.current;
    final isActive = c?.status.name == 'active';
    final isPaused = c?.status.name == 'paused';
    final elapsed = c != null ? c.elapsedSeconds(fasting.now) : 0;
    final remaining = c != null ? c.remainingSeconds(fasting.now) : 0;
    final progress = c != null ? c.progress(fasting.now) : 0.0;
    final fastingToday = fastingNotifier.totalFastingToday();

    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.bolt_rounded, color: Color(0xFF0FA37A)),
          SizedBox(width: 8),
          Text('Mamba Fast', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsPage())),
          ),
          PopupMenuButton(
            itemBuilder: (_) => [
              PopupMenuItem(child: const Text('Sair'), onTap: () => ref.read(authProvider.notifier).logout()),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(fastingProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Protocol selector
              _ProtocolSelector(
                selected: fasting.selectedProtocol,
                custom: fasting.customProtocols,
                onSelect: (p) => fastingNotifier.selectProtocol(p),
                onCustom: (h1, h2) => fastingNotifier.addCustomProtocol(h1, h2),
                enabled: c == null || c.status == FastingStatus.completed || c.status == FastingStatus.cancelled,
              ),
              const SizedBox(height: 16),
              // Timer Card
              Card(
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(c == null ? 'Nenhum jejum ativo' : 'Protocolo ${c.protocolName}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.shade100
                                  : isPaused
                                      ? Colors.orange.shade100
                                      : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              c == null
                                  ? 'IDLE'
                                  : isActive
                                      ? 'ATIVO'
                                      : isPaused
                                          ? 'PAUSADO'
                                          : c.status.name.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? Colors.green.shade800 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CircularProgressIndicator(
                              value: c == null ? 0 : progress,
                              strokeWidth: 10,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(
                                isPaused ? Colors.orange : const Color(0xFF0FA37A),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Text(_fmt(elapsed), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 1)),
                              const SizedBox(height: 2),
                              Text(c == null ? '00:00:00 restante' : 'restante ${_fmt(remaining)}',
                                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
                              if (c != null)
                                Text('${(progress * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(color: Color(0xFF0FA37A), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (c == null)
                        FilledButton.icon(
                          onPressed: () => fastingNotifier.startFasting(),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Iniciar Jejum'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0FA37A),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      else if (isActive)
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => fastingNotifier.pauseFasting(),
                              icon: const Icon(Icons.pause_rounded),
                              label: const Text('Pausar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _confirmEnd(context, fastingNotifier),
                              icon: const Icon(Icons.stop_rounded),
                              label: const Text('Encerrar'),
                              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
                            ),
                          ),
                        ])
                      else if (isPaused)
                        Row(children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => fastingNotifier.resumeFasting(),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Retomar'),
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0FA37A)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmEnd(context, fastingNotifier),
                              icon: const Icon(Icons.stop_rounded),
                              label: const Text('Encerrar'),
                            ),
                          ),
                        ]),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatMini(label: 'Decorrido', value: _fmt(elapsed)),
                          _StatMini(label: 'Restante', value: _fmt(remaining)),
                          _StatMini(label: 'Meta', value: c == null ? '${fasting.selectedProtocol.fastingHours}h' : '${c.durationMinutes ~/ 60}h'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Daily summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Resumo de hoje', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _SummaryTile(icon: Icons.local_fire_department_rounded, color: Colors.orange, title: '$totalCalories kcal', subtitle: 'Calorias hoje', meta: totalCalories > 2000 ? 'Acima da meta' : totalCalories == 0 ? '—' : 'Dentro da meta')),
                      const SizedBox(width: 12),
                      Expanded(child: _SummaryTile(icon: Icons.timer_outlined, color: const Color(0xFF0FA37A), title: '${fastingToday.inHours}h ${fastingToday.inMinutes % 60}m', subtitle: 'Jejum hoje', meta: fastingToday.inHours >= fasting.selectedProtocol.fastingHours ? 'Meta batida 🎉' : 'Faltam ${(fasting.selectedProtocol.fastingHours - fastingToday.inHours).clamp(0, 24)}h')),
                    ]),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (totalCalories / 2200).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(totalCalories > 2200 ? Colors.red : const Color(0xFF0FA37A)),
                    ),
                    const SizedBox(height: 4),
                    Text('Meta calórica 2200 kcal • ${todayMeals.length} refeições', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              // Meals
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Refeições de hoje', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  FilledButton.icon(
                    onPressed: () => _showAddMeal(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar'),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0FA37A), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (todayMeals.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      Icon(Icons.restaurant_rounded, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text('Nenhuma refeição hoje', style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 4),
                      const Text('Toque em Adicionar para registrar', style: TextStyle(fontSize: 12, color: Colors.black38)),
                    ]),
                  ),
                )
              else
                ...todayMeals.reversed.map((m) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: const Color(0xFF0FA37A).withOpacity(0.15), child: const Icon(Icons.restaurant, color: Color(0xFF0FA37A))),
                        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${m.timeLabel} • ${m.dateKey}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('${m.calories} kcal', style: const TextStyle(fontWeight: FontWeight.w700)),
                          PopupMenuButton(
                            onSelected: (v) {
                              if (v == 'edit') _showEditMeal(context, ref, m);
                              if (v == 'delete') ref.read(mealsProvider.notifier).deleteMeal(m.id);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Editar')),
                              PopupMenuItem(value: 'delete', child: Text('Excluir')),
                            ],
                          ),
                        ]),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmEnd(BuildContext ctx, FastingNotifier n) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Encerrar jejum?'),
        content: const Text('Deseja encerrar o jejum atual? O progresso será salvo no histórico.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () { Navigator.pop(ctx); n.stopFasting(complete: false); }, child: const Text('Encerrar')),
        ],
      ),
    );
  }

  void _showAddMeal(BuildContext ctx, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Adicionar refeição', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Nome (ex: Omelete)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          TextField(
              controller: calCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Calorias (kcal)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: () async {
                      final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                      if (t != null && ctx.mounted) {
                        // use selected time today
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Horário selecionado: ${t.format(ctx)}')));
                      }
                    },
                    child: const Text('Horário'))),
          ]),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty || int.tryParse(calCtrl.text) == null) return;
              ref.read(mealsProvider.notifier).addMeal(nameCtrl.text, int.parse(calCtrl.text));
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0FA37A)),
            child: const Text('Salvar'),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _showEditMeal(BuildContext ctx, WidgetRef ref, Meal m) {
    final nameCtrl = TextEditingController(text: m.name);
    final calCtrl = TextEditingController(text: m.calories.toString());
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Editar refeição'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome')),
          TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calorias')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                ref.read(mealsProvider.notifier).updateMeal(m.id, nameCtrl.text, int.tryParse(calCtrl.text) ?? m.calories);
                Navigator.pop(ctx);
              },
              child: const Text('Salvar')),
        ],
      ),
    );
  }
}

class _ProtocolSelector extends StatelessWidget {
  final FastingProtocol selected;
  final List<FastingProtocol> custom;
  final Function(FastingProtocol) onSelect;
  final Function(int, int) onCustom;
  final bool enabled;
  const _ProtocolSelector({required this.selected, required this.custom, required this.onSelect, required this.onCustom, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final all = [...FastingProtocol.predefined, ...custom];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Protocolo', style: TextStyle(fontWeight: FontWeight.w700)),
            if (enabled)
              TextButton.icon(
                onPressed: () => _showCustomDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Custom'),
              ),
          ]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: all.map((p) {
              final isSel = p.id == selected.id;
              return ChoiceChip(
                label: Text(p.name),
                selected: isSel,
                onSelected: enabled ? (_) => onSelect(p) : null,
                selectedColor: const Color(0xFF0FA37A).withOpacity(0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Text(selected.description, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          if (!enabled) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Finalize o jejum atual para trocar protocolo', style: TextStyle(fontSize: 11, color: Colors.orange))),
        ]),
      ),
    );
  }

  void _showCustomDialog(BuildContext ctx) {
    final fCtrl = TextEditingController(text: '20');
    final eCtrl = TextEditingController(text: '4');
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Protocolo customizado'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: fCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Horas jejum (1-23)')),
          TextField(controller: eCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Horas alimentação (1-23)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final f = int.tryParse(fCtrl.text) ?? 0;
              final e = int.tryParse(eCtrl.text) ?? 0;
              if (f >= 1 && f <= 23 && e >= 1 && e <= 23 && f + e == 24) {
                onCustom(f, e);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Jejum + alimentação deve somar 24h (ex: 20:4)')));
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label, value;
  const _StatMini({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ]);
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle, meta;
  const _SummaryTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.meta});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.15))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(meta, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}


