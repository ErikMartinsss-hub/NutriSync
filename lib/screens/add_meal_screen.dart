import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/tokens.dart';
import '../features/meals/data/taco_service.dart';
import '../features/meals/presentation/meal_provider.dart';

class AddMealScreen extends ConsumerStatefulWidget {
  const AddMealScreen({super.key, this.initialType = 'Almoço'});
  final String initialType;
  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  late String _mealType;
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  List<TacoFood> _results = [];
  bool _loading = false;
  TacoFood? _selected;
  double _gramas = 100;

  @override
  void initState() {
    super.initState();
    _mealType = widget.initialType;
  }

  String get _mealKey {
    switch (_mealType) {
      case 'Café da manhã': return 'cafe';
      case 'Lanche da tarde': return 'lanche';
      case 'Jantar': return 'jantar';
      default: return 'almoco';
    }
  }

  Future<void> _search(String q) async {
    if (q.length < 2) { setState(() => _results = []); return; }
    setState(() => _loading = true);
    final r = await TacoService.search(q);
    if (mounted) setState(() { _results = r; _loading = false; });
  }

  void _select(TacoFood f) {
    setState(() { _selected = f; _gramas = 100; _nameCtrl.text = f.nome; _kcalCtrl.text = f.kcalFor(_gramas).toString(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: const Text('Adicionar Refeição', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border), boxShadow: AppShadows.card),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _mealType,
                isDense: true,
                dropdownColor: Colors.white,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textMid),
                items: const [
                  DropdownMenuItem(value: 'Café da manhã', child: Text('Café da manhã', style: TextStyle(color: AppColors.textDark))),
                  DropdownMenuItem(value: 'Almoço', child: Text('Almoço', style: TextStyle(color: AppColors.textDark))),
                  DropdownMenuItem(value: 'Lanche da tarde', child: Text('Lanche da tarde', style: TextStyle(color: AppColors.textDark))),
                  DropdownMenuItem(value: 'Jantar', child: Text('Jantar', style: TextStyle(color: AppColors.textDark))),
                ],
                onChanged: (v) => setState(() => _mealType = v!),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Campo de busca
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Buscar por nome (ex: Pão francês)',
                hintStyle: const TextStyle(color: AppColors.textMid, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _loading ? const SizedBox(width: 16, height: 16, child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))) : null,
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final f = _results[i];
                  final sel = _selected?.id == f.id;
                  return ListTile(
                    dense: true,
                    selected: sel,
                    selectedTileColor: AppColors.primary.withOpacity(0.08),
                    title: Text(f.nome, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: sel ? AppColors.primary : AppColors.textDark)),
                    subtitle: Text('${f.categoria} • ${f.kcalPer100g.toStringAsFixed(0)} kcal/100g', style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                    trailing: sel ? const Icon(Icons.check_circle, color: AppColors.primary, size: 18) : null,
                    onTap: () => _select(f),
                  );
                },
              ),
            ),
          ],
          if (_selected != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.15))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_selected!.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Text('${_selected!.kcalPer100g.toStringAsFixed(0)} kcal / 100g • Proteína ${_selected!.proteinaPer100g.toStringAsFixed(1)}g', style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                const SizedBox(height: 8),
                Row(children: [
                  IconButton(onPressed: () => setState(() { _gramas = (_gramas - 10).clamp(10, 1000); _kcalCtrl.text = _selected!.kcalFor(_gramas).toString(); }), icon: const Icon(Icons.remove_circle_outline, size: 20)),
                  Expanded(child: Slider(value: _gramas, min: 10, max: 500, divisions: 49, label: '${_gramas.toStringAsFixed(0)}g', onChanged: (v) => setState(() { _gramas = v; _kcalCtrl.text = _selected!.kcalFor(_gramas).toString(); }))),
                  IconButton(onPressed: () => setState(() { _gramas = (_gramas + 10).clamp(10, 1000); _kcalCtrl.text = _selected!.kcalFor(_gramas).toString(); }), icon: const Icon(Icons.add_circle_outline, size: 20)),
                ]),
                Center(child: Text('${_gramas.toStringAsFixed(0)}g • ${_kcalCtrl.text} kcal', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary))),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          // Seção manual
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Adicionar Manualmente', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(hintText: 'ex: Pão francês', labelText: 'Nome do alimento', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.restaurant_rounded, size: 18, color: AppColors.textMid)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _kcalCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'ex: 135 kcal', labelText: 'Calorias (kcal)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.local_fire_department_rounded, size: 18, color: AppColors.textMid)),
              ),
            ]),
          ),
          const SizedBox(height: 80),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
              onPressed: () {
                final name = _nameCtrl.text.trim();
                final kcal = int.tryParse(_kcalCtrl.text);
                if (name.isEmpty || kcal == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha nome e calorias')));
                  return;
                }
                ref.read(mealsProvider.notifier).addMeal(name, kcal, mealType: _mealKey);
                Navigator.pop(context);
              },
              child: Text('Salvar em $_mealType', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
        ),
      ),
    );
  }
}
