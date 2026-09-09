import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/tokens.dart';
import '../features/profile/data/user_profile.dart';
import '../features/profile/presentation/profile_provider.dart';
import 'today_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  final _weightCtrl = TextEditingController(text: '88.7');
  final _targetCtrl = TextEditingController(text: '80.0');
  final _heightCtrl = TextEditingController(text: '175');
  final _ageCtrl = TextEditingController(text: '28');
  String _gender = 'M';
  String _goal = 'perder';
  String _pace = 'moderado';

  void _next() {
    if (_step < 3) { setState(() => _step++); _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease); }
    else { _save(); }
  }

  Future<void> _save() async {
    final p = UserProfile(
      weight: double.tryParse(_weightCtrl.text.replaceAll(',', '.')) ?? 88.7,
      targetWeight: double.tryParse(_targetCtrl.text.replaceAll(',', '.')) ?? 80.0,
      height: double.tryParse(_heightCtrl.text) ?? 175,
      age: int.tryParse(_ageCtrl.text) ?? 28,
      gender: _gender,
      goal: _goal,
      pace: _pace,
    );
    await ref.read(profileProvider.notifier).save(p);
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TodayScreen()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(backgroundColor: AppColors.bg, elevation: 0, leading: _step > 0 ? IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textDark), onPressed: () { setState(() => _step--); _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease); }) : null, title: LinearProgressIndicator(value: (_step + 1) / 4, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.primary))),
        body: PageView(
          controller: _pageCtrl,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _step1(),
            _step2(),
            _step3(),
            _step4(),
          ],
        ),
        bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _next, child: Text(_step == 3 ? 'Concluir' : 'Próximo', style: const TextStyle(fontWeight: FontWeight.w800))))),
      );

  Widget _step1() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Dados Básicos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const Text('Essenciais para cálculo preciso', style: AppText.small),
          const SizedBox(height: 16),
          TextField(controller: _weightCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Peso atual (kg)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          TextField(controller: _heightCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Altura (cm)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: TextField(controller: _ageCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Idade', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))), const SizedBox(width: 12), Expanded(child: DropdownButtonFormField<String>(value: _gender, decoration: InputDecoration(labelText: 'Gênero', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), items: const [DropdownMenuItem(value: 'M', child: Text('Masculino')), DropdownMenuItem(value: 'F', child: Text('Feminino'))], onChanged: (v) => setState(() => _gender = v!)))]),
        ]),
      );

  Widget _step2() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Meta Principal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...['perder', 'manter', 'ganhar'].map((g) => Padding(padding: const EdgeInsets.only(bottom: 8), child: ChoiceChip(label: Text(g == 'perder' ? 'Perder peso' : g == 'manter' ? 'Manter peso' : 'Ganhar massa'), selected: _goal == g, onSelected: (_) => setState(() => _goal = g), selectedColor: AppColors.primary.withOpacity(0.15)))),
        ]),
      );

  Widget _step3() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Meta de Peso', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const Text('Peso final desejado', style: AppText.small),
          const SizedBox(height: 16),
          TextField(controller: _targetCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Meta (kg) ex: 80,0', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        ]),
      );

  Widget _step4() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ritmo Desejado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const Text('Opcional, mas útil', style: AppText.small),
          const SizedBox(height: 16),
          ...['leve', 'moderado', 'intenso'].map((p) => Padding(padding: const EdgeInsets.only(bottom: 8), child: ChoiceChip(label: Text(p == 'leve' ? 'Leve (-0,25kg/sem)' : p == 'moderado' ? 'Moderado (-0,5kg/sem)' : 'Intenso (-1kg/sem)'), selected: _pace == p, onSelected: (_) => setState(() => _pace = p), selectedColor: AppColors.primary.withOpacity(0.15)))),
        ]),
      );
}
