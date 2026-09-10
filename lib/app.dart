import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'design/tokens.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/today_screen.dart';

class NutriSyncApp extends ConsumerWidget {
  const NutriSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final systemBrightness = MediaQuery.platformBrightnessOf(context);
    final resolvedBrightness = themeMode == ThemeMode.light
        ? Brightness.light
        : themeMode == ThemeMode.dark
            ? Brightness.dark
            : systemBrightness;
    AppColors.mode = resolvedBrightness;
    return MaterialApp(
      title: 'NutriSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (context, child) {
        // Captura erros de build e mostra aviso compacto — NUNCA loga o usuário fora
        ErrorWidget.builder = (details) => Material(
              color: AppColors.bg,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 32, color: Colors.orange),
                      const SizedBox(height: 8),
                      const Text('Algo deu errado ao exibir esta área', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('${details.exceptionAsString()}', textAlign: TextAlign.center, maxLines: 4, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: AppColors.textMid)),
                      const SizedBox(height: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6)),
                        onPressed: () => Navigator.maybePop(context),
                        child: const Text('Entendi', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ),
            );
        return child ?? const SizedBox.shrink();
      },
      home: auth.isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : auth.isLoggedIn
              ? const TodayScreen()
              : const LoginScreen(),
    );
  }
}
