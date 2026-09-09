import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/today_screen.dart';

class NutriSyncApp extends ConsumerWidget {
  const NutriSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return MaterialApp(
      title: 'NutriSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        // Captura erros de build e mostra em vez de tela branca
        ErrorWidget.builder = (details) => Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
                      const SizedBox(height: 12),
                      Text('Erro: ${details.exception}', textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(details.stack.toString().substring(0, 600), style: const TextStyle(fontSize: 10)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: () => ref.read(authProvider.notifier).logout(), child: const Text('Voltar ao Login')),
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
