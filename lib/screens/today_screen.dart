import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/tokens.dart';
import '../widgets/day_selector.dart';
import '../widgets/calorie_card.dart';
import '../widgets/macros_card.dart';
import '../widgets/diary_tile.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/meals/data/meal.dart';
import '../features/meals/data/taco_service.dart';
import '../features/meals/presentation/meal_provider.dart';
import '../features/fasting/data/fasting_protocol.dart';
import '../features/fasting/data/fasting_session.dart';
import '../features/fasting/presentation/fasting_provider.dart';
import '../features/profile/presentation/profile_provider.dart';
import '../features/exercise/presentation/exercise_provider.dart';
import '../core/theme/theme_provider.dart';
import '../screens/onboarding_screen.dart';
import '../screens/exercise_log_screen.dart';
import '../widgets/weight_card.dart';
import '../widgets/exercise_card.dart';
import 'add_meal_screen.dart';
import 'change_password_screen.dart';
import '../screens/nutrition_screen.dart';
import '../screens/fasting_history_screen.dart';
import '../features/history/presentation/history_page.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});
  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  int _nav = 0;

  @override
  Widget build(BuildContext context) {
    final meals = ref.watch(mealsProvider);
    final fasting = ref.watch(fastingProvider);
    final auth = ref.watch(authProvider);
    final profile = ref.watch(profileProvider);
    final exercises = ref.watch(exercisesProvider);
    final userName = (auth.email ?? 'Usuário').split('@').first;
    final todayKey = Meal.dateKeyFrom(DateTime.now());
    final todayMeals = meals.where((m) => m.dateKey == todayKey).toList();
    final totalKcal = todayMeals.fold<int>(0, (s, m) => s + m.calories);
    final todayEx = exercises.where((e) => e.dateKey == todayKey).toList();
    final exKcal = todayEx.fold<int>(0, (s, e) => s + e.kcal);
    final exMin = todayEx.fold<int>(0, (s, e) => s + e.minutes);
    // meta diária calculada a partir do perfil (Mifflin-St Jeor basal)
    // perder: abaixo do basal; ganhar: acima do basal; manter: no basal
    var dailyGoal = 2458;
    var protGoal = 123;
    if (profile != null) {
      final bmr = profile.gender == 'M'
          ? (10 * profile.weight + 6.25 * profile.height - 5 * profile.age + 5)
          : (10 * profile.weight + 6.25 * profile.height - 5 * profile.age - 161);
      final adj = switch (profile.pace) {
        'leve' => 275,
        'moderado' => 550,
        _ => 1100,
      };
      switch (profile.goal) {
        case 'perder':
          dailyGoal = (bmr - adj).clamp(1200, 5000).toInt();
        case 'ganhar':
          dailyGoal = (bmr + adj).clamp(1200, 5000).toInt();
        default:
          dailyGoal = bmr.round();
      }
      protGoal = switch (profile.goal) {
        'ganhar' => (profile.weight * 2.0).round(),
        'perder' => (profile.weight * 1.8).round(),
        _ => (profile.weight * 1.6).round(),
      };
    }
    final fatGoal = (dailyGoal * 0.25 / 9).round();
    final carbGoal = ((dailyGoal - protGoal * 4 - fatGoal * 9) / 4).round();
    // macros consumidas (50% carb, 25% prot, 25% gordura)
    final carbG = (totalKcal * 0.5 / 4).round();
    final protG = (totalKcal * 0.25 / 4).round();
    final fatG = (totalKcal * 0.25 / 9).round();

    int kcalBy(String type) => todayMeals.where((m) => m.mealType == type).fold(0, (s, m) => s + m.calories);
    List<Meal> mealsBy(String type) => todayMeals.where((m) => m.mealType == type).toList();

    final c = fasting.current;
    final isActive = c?.status == FastingStatus.active;
    final isPaused = c?.status == FastingStatus.paused;
    final elapsed = c != null ? c.elapsedSeconds(fasting.now) : 0;
    final remaining = c != null ? c.remainingSeconds(fasting.now) : 0;
    final progress = c != null ? c.progress(fasting.now) : 0.0;

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Saudação + logout
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
          child: Row(children: [
            CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.12), child: Text(userName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Olá, $userName', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)), Text(auth.email ?? '', style: AppText.small)])),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showLogoutSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(20)),
                  child: Icon(Icons.more_vert_rounded, color: AppColors.textMid, size: 18),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        DaySelector(onSelect: (_) {}),
        const SizedBox(height: 12),
        _ProtocolSelector(
          selected: fasting.selectedProtocol,
          custom: fasting.customProtocols,
          onSelect: (p) => ref.read(fastingProvider.notifier).selectProtocol(p),
          onCustom: (h1, h2) => ref.read(fastingProvider.notifier).addCustomProtocol(h1, h2),
          enabled: c == null || c.status == FastingStatus.completed || c.status == FastingStatus.cancelled,
        ),
        const SizedBox(height: 12),
        Builder(builder: (ctx) {
          return Column(children:[
            if (profile == null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.monitor_weight_rounded, size: 16, color: AppColors.primary)),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Defina seu peso e meta para acompanhamento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  FilledButton(onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const OnboardingScreen())), style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)), child: const Text('Configurar', style: TextStyle(fontSize: 11))),
                ]),
              )
            else
              WeightCard(current: profile.weight, target: profile.targetWeight, onTap: () => _showWeightSheet(ctx)),
            const SizedBox(height: 12),
            ExerciseCard(todayKcal: exKcal, todayMin: exMin, onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ExerciseLogScreen()))),
            if (todayEx.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Column(
                  children: todayEx.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Expanded(child: Text('${e.type} • ${e.minutes}min', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                          Text('${e.kcal} kcal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          IconButton(icon: const Icon(Icons.close_rounded, size: 16), onPressed: () => ref.read(exercisesProvider.notifier).remove(e.id)),
                        ]),
                      )).toList(),
                ),
              ),
          ]);
        }),
        const SizedBox(height: 12),
        _FastingCounterCard(c: c, isActive: isActive, isPaused: isPaused, elapsed: elapsed, remaining: remaining, progress: progress, onStart: () => ref.read(fastingProvider.notifier).startFasting(), onPause: () => ref.read(fastingProvider.notifier).pauseFasting(), onResume: () => ref.read(fastingProvider.notifier).resumeFasting(), onStop: () => ref.read(fastingProvider.notifier).stopFasting()),
        const SizedBox(height: 12),
        CalorieCard(consumed: totalKcal, goal: dailyGoal, burned: exKcal),
        const SizedBox(height: 12),
        MacrosCard(carb: (cur: carbG, goal: carbGoal), fat: (cur: fatG, goal: fatGoal), protein: (cur: protG, goal: protGoal)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Diário', style: AppText.value),
          Text('${todayMeals.length} itens', style: AppText.small),
        ]),
        const SizedBox(height: 8),
        DiaryTile(icon: Icons.free_breakfast_rounded, title: 'Café da manhã', kcal: kcalBy('cafe'), onTap: () => _showMealSheet(context, mealType: 'cafe')),
        if (mealsBy('cafe').isNotEmpty) _mealList(mealsBy('cafe')),
        DiaryTile(icon: Icons.lunch_dining_rounded, title: 'Almoço', kcal: kcalBy('almoco'), onTap: () => _showMealSheet(context, mealType: 'almoco')),
        if (mealsBy('almoco').isNotEmpty) _mealList(mealsBy('almoco')),
        DiaryTile(icon: Icons.dinner_dining_rounded, title: 'Jantar', kcal: kcalBy('jantar'), onTap: () => _showMealSheet(context, mealType: 'jantar')),
        if (mealsBy('jantar').isNotEmpty) _mealList(mealsBy('jantar')),
        DiaryTile(icon: Icons.fastfood_rounded, title: 'Lanches', kcal: kcalBy('lanche'), onTap: () => _showMealSheet(context, mealType: 'lanche')),
        if (mealsBy('lanche').isNotEmpty) _mealList(mealsBy('lanche')),
        if (todayMeals.isEmpty)
          Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(Icons.info_outline, size: 16, color: AppColors.textMid), const SizedBox(width: 8), Text('Toque em Registre para adicionar', style: AppText.small)])),
        const SizedBox(height: 16),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text('Hoje', style: AppText.title),
        actions: [
          Consumer(builder: (context, ref, _) {
            final mode = ref.watch(themeModeProvider);
            final isDark = mode == ThemeMode.dark || (mode == ThemeMode.system && AppColors.isDark);
            return IconButton(
              tooltip: isDark ? 'Modo claro' : 'Modo escuro',
              icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: AppColors.textDark),
              onPressed: () => ref.read(themeModeProvider.notifier).set(isDark ? ThemeMode.light : ThemeMode.dark),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showLogoutSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
                  child: Icon(Icons.more_vert_rounded, color: AppColors.textMid, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _nav == 0 ? body : _nav == 1 ? const NutritionScreen() : _nav == 2 ? const FastingHistoryScreen() : const HistoryPage(),
      floatingActionButton: FloatingActionButton(onPressed: () => _showMealSheet(context, mealType: 'almoco'), backgroundColor: AppColors.primary, shape: const CircleBorder(), child: const Icon(Icons.add, color: Colors.white)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() => BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: AppColors.card,
        elevation: 8,
        child: SizedBox(
          height: 56,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _navItem(Icons.home_rounded, 'Hoje', 0),
            _navItem(Icons.show_chart_rounded, 'Nutrição', 1),
            const SizedBox(width: 48),
            _navItem(Icons.timer_outlined, 'Jejum', 2),
            InkWell(
              onTap: () => _showLogoutSheet(context),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.textMid),
                const SizedBox(height: 2),
                Text('Mais', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _nav == 3 ? AppColors.primary : AppColors.textMid)),
              ]),
            ),
          ]),
        ),
      );

  Widget _navItem(IconData ic, String lb, int i) => InkWell(
        onTap: () => setState(() => _nav = i),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(ic, size: 20, color: _nav == i ? AppColors.primary : AppColors.textMid),
          const SizedBox(height: 2),
          Text(lb, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _nav == i ? AppColors.primary : AppColors.textMid)),
        ]),
      );

  void _showLogoutSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(alignment: Alignment.centerLeft, child: Text('Tema', style: AppText.label)),
          ),
          const SizedBox(height: 4),
          Consumer(builder: (context, ref, _) {
            final mode = ref.watch(themeModeProvider);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                ChoiceChip(label: const Text('Claro'), selected: mode == ThemeMode.light, onSelected: (_) => ref.read(themeModeProvider.notifier).set(ThemeMode.light)),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Escuro'), selected: mode == ThemeMode.dark, onSelected: (_) => ref.read(themeModeProvider.notifier).set(ThemeMode.dark)),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Sistema'), selected: mode == ThemeMode.system, onSelected: (_) => ref.read(themeModeProvider.notifier).set(ThemeMode.system)),
              ]),
            );
          }),
          const SizedBox(height: 8),
          Consumer(builder: (context, ref, _) {
            final usesPwd = ref.read(authProvider.notifier).usesPasswordAuth;
            if (!usesPwd) return const SizedBox.shrink();
            return ListTile(leading: const Icon(Icons.lock_reset_rounded), title: const Text('Alterar senha'), onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())); });
          }),
          ListTile(leading: const Icon(Icons.history_rounded), title: const Text('Histórico'), onTap: () { Navigator.pop(ctx); setState(() => _nav = 3); }),
          ListTile(leading: const Icon(Icons.delete_forever_rounded, color: Colors.red), title: const Text('Excluir conta', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(ctx); _confirmDeleteAccount(ctx); }),
          ListTile(leading: const Icon(Icons.logout_rounded, color: Colors.red), title: const Text('Sair da conta', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(ctx); ref.read(authProvider.notifier).logout(); }),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext ctx) async {
    final usesPwd = ref.read(authProvider.notifier).usesPasswordAuth;
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Excluir conta?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Todos os dados deste aplicativo no aparelho serão apagados permanentemente. Essa ação não pode ser desfeita.', style: TextStyle(fontSize: 13)),
          if (usesPwd) ...[
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(hintText: 'Confirme sua senha', filled: true, fillColor: AppColors.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
            ),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true) {
      controller.dispose();
      return;
    }
    final err = await ref.read(authProvider.notifier).deleteAccount(usesPwd ? controller.text : null);
    controller.dispose();
    if (!ctx.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Widget _mealList(List<Meal> list) => Column(
        children: list.map((m) => Container(
              margin: const EdgeInsets.only(bottom: 6, left: 8, right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), Text('${m.timeLabel} • ${m.calories} kcal', style: AppText.small)])),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _showEditMeal(m);
                    if (v == 'delete') ref.read(mealsProvider.notifier).deleteMeal(m.id);
                  },
                  itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Editar')), PopupMenuItem(value: 'delete', child: Text('Excluir'))],
                ),
              ]),
            )).toList(),
      );

  void _showEditMeal(Meal m) {
    final nameCtrl = TextEditingController(text: m.name);
    final calCtrl = TextEditingController(text: m.calories.toString());
    String type = m.mealType;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
            title: const Text('Editar refeição'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome')),
              const SizedBox(height: 8),
              TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calorias')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'Refeição'), dropdownColor: AppColors.card, items: [DropdownMenuItem(value: 'cafe', child: Text('Café da manhã', style: TextStyle(color: AppColors.textDark))), DropdownMenuItem(value: 'almoco', child: Text('Almoço', style: TextStyle(color: AppColors.textDark))), DropdownMenuItem(value: 'jantar', child: Text('Jantar', style: TextStyle(color: AppColors.textDark))), DropdownMenuItem(value: 'lanche', child: Text('Lanches', style: TextStyle(color: AppColors.textDark)))], onChanged: (v) => setD(() => type = v ?? type)),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              FilledButton(onPressed: () { ref.read(mealsProvider.notifier).updateMeal(m.id, nameCtrl.text, int.tryParse(calCtrl.text) ?? m.calories, mealType: type); Navigator.pop(ctx); }, child: const Text('Salvar')),
            ],
          )),
    );
  }

  void _showMealSheet(BuildContext ctx, {String mealType = 'almoco'}) {
    final map = {'cafe': 'Café da manhã', 'almoco': 'Almoço', 'jantar': 'Jantar', 'lanche': 'Lanche da tarde'};
    final label = map[mealType] ?? 'Almoço';
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddMealScreen(initialType: label)));
  }

  void _showWeightSheet(BuildContext ctx) {
    final p = ref.read(profileProvider);
    if (p == null) { Navigator.push(ctx, MaterialPageRoute(builder: (_) => const OnboardingScreen())); return; }
    final wCtrl = TextEditingController(text: p.weight.toString());
    final tCtrl = TextEditingController(text: p.targetWeight.toString());
    showModalBottomSheet(context: ctx, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Atualizar Peso', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 12),
        TextField(controller: wCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Peso atual (kg)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 8),
        TextField(controller: tCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Meta (kg)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 12),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(48)), onPressed: () { final w=double.tryParse(wCtrl.text.replaceAll(',', '.')); final t=double.tryParse(tCtrl.text.replaceAll(',', '.')); if(w!=null) ref.read(profileProvider.notifier).updateWeight(w); if(t!=null) ref.read(profileProvider.notifier).updateTarget(t); Navigator.pop(ctx); }, child: const Text('Salvar')),
        const SizedBox(height: 16),
      ]),
    ));
  }
}

class _FastingCounterCard extends StatelessWidget {
  const _FastingCounterCard({required this.c, required this.isActive, required this.isPaused, required this.elapsed, required this.remaining, required this.progress, required this.onStart, required this.onPause, required this.onResume, required this.onStop});
  final dynamic c;
  final bool isActive, isPaused;
  final int elapsed, remaining;
  final double progress;
  final VoidCallback onStart, onPause, onResume, onStop;
  String _fmt(int s) { final h=s~/3600; final m=(s%3600)~/60; final sec=s%60; return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${sec.toString().padLeft(2,'0')}'; }
  @override
  Widget build(BuildContext context) {
    try {
      final safeProgress = progress.isNaN || progress.isInfinite ? 0.0 : progress.clamp(0.0, 1.0);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card, border: Border.all(color: isActive ? AppColors.primary.withOpacity(0.15) : Colors.transparent)),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(c == null ? 'Nenhum jejum ativo' : 'Jejum ${c.protocolName}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: c == null ? AppColors.bg : isActive ? AppColors.primary.withOpacity(0.12) : isPaused ? Colors.orange.withOpacity(0.12) : Colors.grey.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(c == null ? 'INATIVO' : isActive ? 'ATIVO' : isPaused ? 'PAUSADO' : 'IDLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isActive ? AppColors.primary : isPaused ? Colors.orange : AppColors.textDark)),
            ),
          ]),
          const SizedBox(height: 12),
          Stack(alignment: Alignment.center, children: [
            SizedBox(width: 140, height: 140, child: CircularProgressIndicator(value: safeProgress, strokeWidth: 8, backgroundColor: AppColors.bg, valueColor: AlwaysStoppedAnimation(isPaused ? Colors.orange : AppColors.primary))),
            Column(children: [Text(_fmt(elapsed), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)), Text('restante ${_fmt(remaining)}', style: TextStyle(fontSize: 11, color: AppColors.textDark)), if (c != null) Text('${(safeProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11))]),
          ]),
          const SizedBox(height: 12),
          if (c == null)
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onStart, icon: const Icon(Icons.play_arrow_rounded, size: 18), label: const Text('Iniciar Jejum'), style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))))
          else if (isActive)
            Row(children: [Expanded(child: OutlinedButton.icon(onPressed: onPause, icon: const Icon(Icons.pause_rounded, size: 16), label: const Text('Pausar'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: onStop, icon: const Icon(Icons.stop_rounded, size: 16), label: const Text('Encerrar'), style: FilledButton.styleFrom(backgroundColor: Colors.red)))] )
          else if (isPaused)
            Row(children: [Expanded(child: FilledButton.icon(onPressed: onResume, icon: const Icon(Icons.play_arrow_rounded, size: 16), label: const Text('Retomar'), style: FilledButton.styleFrom(backgroundColor: AppColors.primary))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: onStop, icon: const Icon(Icons.stop_rounded, size: 16), label: const Text('Encerrar')))] ),
        ]),
      );
    } catch (e) {
      return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)), child: Text('Erro jejum: $e', style: const TextStyle(color: Colors.red, fontSize: 11)));
    }
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Protocolo de Jejum', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          if (enabled) TextButton.icon(onPressed: () => _showCustom(context), icon: const Icon(Icons.add, size: 14), label: const Text('Custom', style: TextStyle(fontSize: 11))),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: all.map((p) {
          final isSel = p.id == selected.id;
          return ChoiceChip(label: Text(p.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSel ? Colors.white : AppColors.textDark)), selected: isSel, selectedColor: AppColors.primary, backgroundColor: AppColors.bg, onSelected: enabled ? (_) => onSelect(p) : null);
        }).toList()),
        const SizedBox(height: 6),
        Text(selected.description, style: TextStyle(fontSize: 11, color: AppColors.textMid)),
        if (!enabled) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Finalize o jejum atual para trocar protocolo', style: TextStyle(fontSize: 10, color: Colors.orange))),
      ]),
    );
  }
  void _showCustom(BuildContext ctx) {
    final fCtrl = TextEditingController(text: '20');
    final eCtrl = TextEditingController(text: '4');
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('Protocolo customizado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: fCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Horas jejum (1-23)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 8),
        TextField(controller: eCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Horas alimentação (1-23)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.primary), onPressed: () { final f=int.tryParse(fCtrl.text)??0; final e=int.tryParse(eCtrl.text)??0; if(f>=1&&f<=23&&e>=1&&e<=23&&f+e==24){ onCustom(f,e); Navigator.pop(ctx); } else { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Jejum + alimentação deve somar 24h (ex: 20:4)'))); } }, child: const Text('Criar')),
      ],
    ));
  }
}

class _TacoSheet extends StatefulWidget {
  final TextEditingController searchCtrl, manualNameCtrl, manualCalCtrl;
  final String initialMealType;
  final void Function(String, int, String) onSave;
  const _TacoSheet({required this.searchCtrl, required this.manualNameCtrl, required this.manualCalCtrl, required this.initialMealType, required this.onSave});
  @override
  State<_TacoSheet> createState() => _TacoSheetState();
}
class _TacoSheetState extends State<_TacoSheet> {
  List<TacoFood> _res = [];
  bool _loading = false;
  TacoFood? _sel;
  double _g = 100; int _un = 1; bool _isUn = false; double _gUn = 50;
  late String _mealType;
  Timer? _debounce;
  int _searchSeq = 0;
  @override
  void initState() { super.initState(); _mealType = widget.initialMealType; }
  @override
  void dispose() { _debounce?.cancel(); super.dispose(); }
  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.length < 2) { setState(() => _res = []); return; }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }
  Future<void> _search(String q) async {
    final seq = ++_searchSeq;
    setState(() { _loading = true; });
    final r = await TacoService.search(q);
    if (mounted && seq == _searchSeq) setState(() {
      _res = r;
      _loading = false;
    });
  }
  int get _kcal => _sel==null?0: _isUn ? _sel!.kcalForUnidades(_un, gramasPorUnidade: _gUn) : _sel!.kcalFor(_g);
  String get _mealLabel => {'cafe':'Café da manhã','almoco':'Almoço','jantar':'Jantar','lanche':'Lanches'}[_mealType] ?? _mealType;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children:[
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text('Adicionar refeição', style: TextStyle(fontWeight: FontWeight.w700)), Container(padding: const EdgeInsets.symmetric(horizontal:8,vertical:4), decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(20)), child: DropdownButton<String>(value: _mealType, underline: const SizedBox(), isDense:true, dropdownColor: AppColors.card, style: TextStyle(fontSize:12, color: AppColors.textDark, fontWeight: FontWeight.w600), items: [DropdownMenuItem(value:'cafe', child: Text('Café', style: TextStyle(color: AppColors.textDark))), DropdownMenuItem(value:'almoco', child: Text('Almoço', style: TextStyle(color: AppColors.textDark))), DropdownMenuItem(value:'jantar', child: Text('Jantar', style: TextStyle(color: AppColors.textDark))), DropdownMenuItem(value:'lanche', child: Text('Lanches', style: TextStyle(color: AppColors.textDark)))], onChanged:(v)=>setState(()=>_mealType=v??_mealType)))]),
      const SizedBox(height: 8),
      Text('Vai para: $_mealLabel', style: const TextStyle(fontSize:11, color: AppColors.primary, fontWeight: FontWeight.w600)), const SizedBox(height:8),
      TextField(controller: widget.searchCtrl, decoration: InputDecoration(labelText: 'Buscar (pão francês)', prefixIcon: const Icon(Icons.search), suffixIcon: _loading? const SizedBox(width:16,height:16, child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth:2))):null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: _onSearchChanged),
      if (_res.isNotEmpty) Container(margin: const EdgeInsets.only(top:8), constraints: const BoxConstraints(maxHeight:160), decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)), child: ListView.separated(shrinkWrap:true, itemCount:_res.length, separatorBuilder:(_,__)=>const Divider(height:1), itemBuilder:(_,i){final f=_res[i]; final sel=_sel?.id==f.id; return ListTile(dense:true, selected:sel, title: Text(f.nome, style: TextStyle(fontWeight: FontWeight.w600, color: sel? AppColors.primary:null)), subtitle: Text('${f.kcalPer100g.toStringAsFixed(0)} kcal/100g', style: const TextStyle(fontSize:11)), trailing: sel? const Icon(Icons.check_circle, color: AppColors.primary):null, onTap: ()=>setState(()=>_sel=f));})),
      if (_sel!=null) Container(margin: const EdgeInsets.only(top:12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text(_sel!.nome, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height:6),
        Row(children:[ChoiceChip(label: const Text('Gramas'), selected: !_isUn, onSelected:(v)=>setState(()=>_isUn=!v)), const SizedBox(width:8), ChoiceChip(label: const Text('Unidades'), selected: _isUn, onSelected:(v)=>setState(()=>_isUn=v))]),
        const SizedBox(height:8),
        if (!_isUn) Row(children:[IconButton(onPressed: ()=>setState(()=>_g=(_g-10).clamp(10,2000)), icon: const Icon(Icons.remove_circle_outline)), Expanded(child: Slider(value:_g, min:10, max:500, divisions:49, label:'${_g.toStringAsFixed(0)}g', onChanged:(v)=>setState(()=>_g=v))), IconButton(onPressed: ()=>setState(()=>_g=(_g+10).clamp(10,2000)), icon: const Icon(Icons.add_circle_outline))])
        else Row(children:[IconButton(onPressed: ()=>setState(()=>_un=(_un-1).clamp(1,20)), icon: const Icon(Icons.remove_circle_outline)), Expanded(child: Center(child: Text('$_un un'))), IconButton(onPressed: ()=>setState(()=>_un=(_un+1).clamp(1,20)), icon: const Icon(Icons.add_circle_outline))]),
        const SizedBox(height:6), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text('Total:'), Text('$_kcal kcal', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary))]),
      ])),
      const Divider(height:24), TextField(controller: widget.manualNameCtrl, decoration: InputDecoration(labelText: 'Ou nome manual', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), const SizedBox(height:8),
      TextField(controller: widget.manualCalCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Calorias manual', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height:12), FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.primary), onPressed: (){ if(_sel!=null){ widget.onSave('${_sel!.nome} (${_isUn?'$_un un':'${_g.toStringAsFixed(0)}g'})', _kcal, _mealType); } else if(widget.manualNameCtrl.text.isNotEmpty && int.tryParse(widget.manualCalCtrl.text)!=null){ widget.onSave(widget.manualNameCtrl.text, int.parse(widget.manualCalCtrl.text), _mealType); } }, child: Text(_sel!=null ? 'Salvar em $_mealLabel • $_kcal kcal' : 'Salvar em $_mealLabel')), const SizedBox(height:16),
    ])),
  );
}
