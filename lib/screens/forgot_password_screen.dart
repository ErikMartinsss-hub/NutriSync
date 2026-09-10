import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/tokens.dart';
import '../features/auth/presentation/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Informe um e-mail válido.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(authProvider.notifier).sendPasswordReset(email);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enviamos um link de redefinição para o seu e-mail.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(backgroundColor: AppColors.bg, elevation: 0, title: const Text('Esqueceu a senha?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        body: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.bg, AppColors.card])),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
                  child: Column(children: [
                    Icon(Icons.mark_email_read_rounded, size: 40, color: AppColors.primary),
                    const SizedBox(height: 12),
                    const Text('Digite o e-mail da sua conta', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Vamos enviar um link para você redefinir sua senha.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textMid)),
                  ]),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Digite seu Email',
                    hintStyle: TextStyle(color: AppColors.textMid, fontSize: 13),
                    prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.primary, size: 20),
                    filled: true,
                    fillColor: AppColors.card,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.15))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.2)),
                  ),
                ),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 12))),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF9900), Color(0xFF00BFA5)]),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: const Color(0xFFFF9900).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: ElevatedButton(
                      onPressed: _loading ? null : _send,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                      child: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('ENVIAR LINK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}