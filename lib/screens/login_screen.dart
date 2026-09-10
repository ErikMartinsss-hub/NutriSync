import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/saved_credentials.dart';
import '../design/tokens.dart';
import '../features/auth/presentation/auth_provider.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _obscure = true, _loading = false, _savePass = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final creds = await SavedCredentials.read();
    if (mounted && creds != null) {
      _email.text = creds.email;
      if (creds.password.isNotEmpty) _pass.text = creds.password;
    }
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).login(_email.text.trim(), _pass.text, savePassword: _savePass);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loginGoogle() async {
    setState(() => _loading = true);
    final ok = await ref.read(authProvider.notifier).loginWithGoogle(savePassword: _savePass);
    setState(() => _loading = false);
    if (!ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Sign-In cancelado ou falhou')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.bg, AppColors.card])),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
                  child: Stack(alignment: Alignment.center, children: [
                    Positioned(left: 20, top: 30, child: _blob(60, AppColors.carb.withOpacity(0.15), Icons.eco_rounded)),
                    Positioned(right: 30, top: 20, child: _blob(80, AppColors.protein.withOpacity(0.15), Icons.directions_run_rounded)),
                    Positioned(left: 40, bottom: 30, child: _blob(70, AppColors.fat.withOpacity(0.15), Icons.local_dining_rounded)),
                    const Icon(Icons.health_and_safety_rounded, size: 72, color: AppColors.primary),
                  ]),
                ),
                const SizedBox(height: 24),
                Text('Bem-vindo de volta', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 6),
                Text('Faça login para continuar sua jornada', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textMid)),
                const SizedBox(height: 24),
                Form(
                  key: _form,
                  child: Column(children: [
                    _input(controller: _email, hint: 'Digite seu Email', icon: Icons.mail_outline_rounded, validator: (v) => v != null && v.contains('@') ? null : 'E-mail inválido'),
                    const SizedBox(height: 12),
                    _input(controller: _pass, hint: 'Digite a sua senha', icon: Icons.lock_outline_rounded, obscure: _obscure, suffix: IconButton(icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textMid), onPressed: () => setState(() => _obscure = !_obscure)), validator: (v) => v != null && v.length >= 3 ? null : 'Mín 3 caracteres'),
                    const SizedBox(height: 8),
                    Row(children: [
                      TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())), child: const Text('Esqueceu a senha?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12))),
                      const Spacer(),
                      Text('Salvar senha no app', style: TextStyle(fontSize: 12, color: AppColors.textMid, fontWeight: FontWeight.w600)),
                      Switch(value: _savePass, onChanged: (v) => setState(() => _savePass = v), activeTrackColor: AppColors.primary, activeThumbColor: Colors.white, inactiveThumbColor: AppColors.textMid),
                    ]),
                    if (_error != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF9900), Color(0xFF00BFA5)]), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: const Color(0xFFFF9900).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                          child: _loading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('ENTRAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1)),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('ou entrar com', style: AppText.small)),
                  Expanded(child: Divider(color: AppColors.border))
                ]),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: InkWell(onTap: _loginGoogle, child: _social('G', 'Google', const Color(0xFF4285F4)))),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Não tem uma conta? ', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
                  GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('Cadastre-se aqui', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700))),
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

  Widget _blob(double s, Color c, IconData ic) => Container(width: s, height: s, decoration: BoxDecoration(color: c, shape: BoxShape.circle), child: Icon(ic, color: c.withOpacity(0.9)));
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
