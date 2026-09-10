import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/tokens.dart';
import '../features/auth/presentation/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure1 = true, _obscure2 = true, _loading = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = _current.text;
    final newPass = _newPass.text;
    if (current.isEmpty) {
      setState(() => _error = 'Informe sua senha atual.');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _error = 'A nova senha deve ter pelo menos 6 caracteres.');
      return;
    }
    if (newPass != _confirm.text) {
      setState(() => _error = 'As senhas não conferem.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(authProvider.notifier).changePassword(current, newPass);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha alterada com sucesso!')));
    Navigator.pop(context);
  }

  Widget _field(TextEditingController c, String hint, bool obscure, ValueChanged<bool> onToggle, IconData icon) => TextFormField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textMid, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textMid, size: 20), onPressed: () => onToggle(!obscure)),
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.15))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.2)),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(backgroundColor: AppColors.bg, elevation: 0, title: const Text('Alterar senha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        body: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.bg, AppColors.card])),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
                  child: Column(children: [
                    Icon(Icons.password_rounded, size: 40, color: AppColors.primary),
                    const SizedBox(height: 12),
                    Text('Defina uma nova senha para a sua conta.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textMid)),
                  ]),
                ),
                const SizedBox(height: 20),
                _field(_current, 'Senha atual', _obscure1, (v) => setState(() => _obscure1 = v), Icons.lock_outline_rounded),
                const SizedBox(height: 12),
                _field(_newPass, 'Nova senha (mín. 6 caracteres)', _obscure2, (v) => setState(() => _obscure2 = v), Icons.lock_reset_rounded),
                const SizedBox(height: 12),
                _field(_confirm, 'Confirmar nova senha', _obscure1, (v) => setState(() => _obscure1 = v), Icons.verified_user_outlined),
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
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                      child: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('SALVAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}