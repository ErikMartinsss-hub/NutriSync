import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/tokens.dart';
import '../features/auth/presentation/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _obscure1 = true, _obscure2 = true, _loading = false;
  String? _error;

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).register(_email.text.trim(), _pass.text);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      log('[REGISTER_SCREEN] Erro: $e');
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loginGoogle() async {
    setState(() => _loading = true);
    final ok = await ref.read(authProvider.notifier).loginWithGoogle();
    setState(() => _loading = false);
    if (!ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Sign-In cancelado ou falhou')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.bg, AppColors.card])),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Align(alignment: Alignment.centerLeft, child: IconButton(icon: Icon(Icons.arrow_back_rounded, color: AppColors.textDark), onPressed: () => Navigator.pop(context))),
                const SizedBox(height: 4),
                Text('Criar Conta', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 6),
                Text('Comece sua jornada saudável hoje', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textMid)),
                const SizedBox(height: 24),
                Form(
                  key: _form,
                  child: Column(children: [
                    _input(controller: _name, hint: 'Nome completo', icon: Icons.person_outline_rounded, validator: (v) => v != null && v.trim().length >= 3 ? null : 'Informe seu nome'),
                    const SizedBox(height: 12),
                    _input(controller: _email, hint: 'E-mail', icon: Icons.mail_outline_rounded, validator: (v) => v != null && v.contains('@') ? null : 'E-mail inválido'),
                    const SizedBox(height: 12),
                    _input(controller: _pass, hint: 'Senha', icon: Icons.lock_outline_rounded, obscure: _obscure1, suffix: IconButton(icon: Icon(_obscure1 ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textMid), onPressed: () => setState(() => _obscure1 = !_obscure1)), validator: (v) => v != null && v.length >= 6 ? null : 'Mín 6 caracteres'),
                    const SizedBox(height: 12),
                    _input(controller: _confirm, hint: 'Confirmar senha', icon: Icons.lock_outline_rounded, obscure: _obscure2, suffix: IconButton(icon: Icon(_obscure2 ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textMid), onPressed: () => setState(() => _obscure2 = !_obscure2)), validator: (v) => v == _pass.text ? null : 'Senhas não conferem'),
                    if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF9900), Color(0xFF00BFA5)]), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: const Color(0xFFFF9900).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                          child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('CADASTRAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1)),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                Row(children: [Expanded(child: Divider(color: AppColors.border)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('ou cadastrar com', style: AppText.small)), Expanded(child: Divider(color: AppColors.border))]),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: InkWell(onTap: _loginGoogle, child: _social('G', 'Google', const Color(0xFF4285F4)))),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Já tem uma conta? ', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
                  GestureDetector(onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('Faça login', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 12),
              ]),
            ),
          ),
        ),
      );

  Widget _input({required TextEditingController controller, required String hint, required IconData icon, Widget? suffix, bool obscure = false, String? Function(String?)? validator}) => TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textMid, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.15))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.2)),
        ),
      );

  Widget _social(String letter, String label, Color col) => Container(
        height: 48,
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card, border: Border.all(color: AppColors.border)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 22, height: 22, decoration: BoxDecoration(color: col, shape: BoxShape.circle), child: Center(child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)))),
          const SizedBox(width: 8),
          Flexible(child: Text('Continuar com $label', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ]),
      );
}
