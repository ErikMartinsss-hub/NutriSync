import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/tokens.dart';
import '../features/exercise/data/met_calculator.dart';
import '../features/exercise/presentation/exercise_provider.dart';
import '../features/profile/presentation/profile_provider.dart';

class ExerciseLogScreen extends ConsumerStatefulWidget {
  const ExerciseLogScreen({super.key});
  @override
  ConsumerState<ExerciseLogScreen> createState() => _ExerciseLogScreenState();
}

class _ExerciseLogScreenState extends ConsumerState<ExerciseLogScreen> {
  String _category = 'Cardio';
  String _type = 'Caminhada rápida (5 km/h)';
  String _intensity = 'Moderada';
  final _minCtrl = TextEditingController(text: '30');

  double get _met => MetCalculator.metFor(category: _category, type: _type, intensity: _intensity);

  int _kcal(double weight) {
    final min = int.tryParse(_minCtrl.text) ?? 0;
    return MetCalculator.kcals(_met, weight, min);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final weight = profile?.weight ?? 88.7;
    final kcal = _kcal(weight);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.bg, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark), onPressed: () => Navigator.pop(context)), title: const Text('Registrar Exercício', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // categoria
          const Text('Tipo de Exercício', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: ChoiceChip(label: const Text('Cardiovascular'), selected: _category == 'Cardio', selectedColor: AppColors.primary.withOpacity(0.15), onSelected: (_) => setState(() => _category = 'Cardio'))),
            const SizedBox(width: 8),
            Expanded(child: ChoiceChip(label: const Text('Musculação'), selected: _category == 'Musculação', selectedColor: AppColors.primary.withOpacity(0.15), onSelected: (_) => setState(() => _category = 'Musculação'))),
          ]),
          const SizedBox(height: 12),
          if (_category == 'Cardio')
            DropdownButtonFormField<String>(value: _type, decoration: InputDecoration(labelText: 'Modalidade', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), items: const [DropdownMenuItem(value: 'Caminhada rápida (5 km/h)', child: Text('Caminhada rápida (5 km/h)')), DropdownMenuItem(value: 'Corrida moderada (8 km/h)', child: Text('Corrida moderada (8 km/h)')), DropdownMenuItem(value: 'Ciclismo moderado', child: Text('Ciclismo moderado')), DropdownMenuItem(value: 'Natação', child: Text('Natação'))], onChanged: (v) => setState(() => _type = v!))
          else
            DropdownButtonFormField<String>(value: _intensity, decoration: InputDecoration(labelText: 'Intensidade', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), items: const [DropdownMenuItem(value: 'Leve', child: Text('Leve')), DropdownMenuItem(value: 'Moderada', child: Text('Moderada')), DropdownMenuItem(value: 'Intensa', child: Text('Intensa (circuito)'))], onChanged: (v) => setState(() => _intensity = v!)),
          const SizedBox(height: 16),
          TextField(controller: _minCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Tempo (minutos)', hintText: 'ex: 45', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (_) => setState(() {})),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
            child: Column(children: [
              Text('MET $_met • Peso ${weight.toStringAsFixed(1)} kg', style: AppText.small),
              const SizedBox(height: 4),
              Text('$kcal kcal estimadas', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
              Text('${_minCtrl.text} min de $_type ${_category == 'Musculação' ? '($_intensity)' : ''}', style: AppText.small, textAlign: TextAlign.center),
            ]),
          ),
          const SizedBox(height: 16),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                final min = int.tryParse(_minCtrl.text) ?? 0;
                if (min <= 0) return;
                await ref.read(exercisesProvider.notifier).add(type: _type, category: _category, intensity: _intensity, minutes: min, kcal: kcal);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Salvar Exercício')),
          const SizedBox(height: 8),
          Center(child: Text('Fórmula: kcal = MET × peso × horas', style: AppText.small)),
        ]),
      ),
    );
  }
}
