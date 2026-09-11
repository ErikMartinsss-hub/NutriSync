import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/saved_credentials.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

class AuthState {
  final bool isLoggedIn;
  final String? email;
  final bool isLoading;
  final User? firebaseUser;
  const AuthState({this.isLoggedIn = false, this.email, this.isLoading = true, this.firebaseUser});

  String get userId => firebaseUser?.email ?? email ?? 'anon';
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _googleInitialized = false;

  Future<void> _ensureGoogleInit() async {
    if (_googleInitialized) return;
    try {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
    } catch (_) {}
  }

  AuthNotifier() : super(const AuthState()) {
    _load();
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        state = AuthState(isLoggedIn: true, email: user.email, isLoading: false, firebaseUser: user);
      }
    });
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logged = prefs.getBool('isLoggedIn') ?? false;
      final email = prefs.getString('email');
      User? fbUser;
      try {
        fbUser = _auth.currentUser;
      } catch (_) {}
      if (fbUser != null) {
        state = AuthState(isLoggedIn: true, email: fbUser.email, isLoading: false, firebaseUser: fbUser);
        return;
      }
      // offline/transição: mantém sessão local se já estava logado
      state = AuthState(isLoggedIn: logged, email: email, isLoading: false);
    } catch (_) {
      state = const AuthState(isLoggedIn: false, isLoading: false);
    }
  }

  Future<bool> login(String email, String password, {bool savePassword = false}) async {
    if (email.isEmpty || !email.contains('@') || password.length < 3) return false;
    try {
      log('[AUTH] Tentando login Firebase: $email');
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = _auth.currentUser;
      log('[AUTH] Login Firebase OK: ${user?.email}');
      state = AuthState(isLoggedIn: true, email: user?.email ?? email, isLoading: false, firebaseUser: user);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('email', email);
      AnalyticsService.setUserId(email);
      AnalyticsService.logEvent('login');
      if (savePassword) await SavedCredentials.save(email.trim(), password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      log('[AUTH] Login Firebase ERRO: ${e.code} - ${e.message}');
      throw Exception(_firebaseAuthError(e.code));
    } catch (e) {
      log('[AUTH] Login ERRO generico: $e');
      throw Exception('Sem conexão com a internet.');
    }
  }

  Future<bool> register(String email, String password) async {
    if (email.isEmpty || !email.contains('@') || password.length < 6) return false;
    try {
      log('[AUTH] Tentando registro Firebase: $email');
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = _auth.currentUser;
      log('[AUTH] Registro Firebase OK: ${user?.email}');
      state = AuthState(isLoggedIn: true, email: user?.email ?? email, isLoading: false, firebaseUser: user);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('email', email);
      AnalyticsService.setUserId(email);
      AnalyticsService.logEvent('sign_up');
      return true;
    } on FirebaseAuthException catch (e) {
      log('[AUTH] Registro Firebase ERRO: ${e.code} - ${e.message}');
      if (e.code == 'email-already-in-use') {
        return login(email, password);
      }
      throw Exception(_firebaseAuthError(e.code));
    } catch (e) {
      log('[AUTH] Registro ERRO generico: $e');
      if (e is Exception) rethrow;
      throw Exception('Sem conexão com a internet.');
    }
  }

  String _firebaseAuthError(String code) {
    switch (code) {
      case 'weak-password': return 'A senha deve ter pelo menos 6 caracteres.';
      case 'invalid-email': return 'E-mail inválido.';
      case 'operation-not-allowed': return 'Este método de cadastro não está disponível.';
      case 'network-request-failed': return 'Sem conexão com a internet.';
      default: return 'Erro ao criar conta ($code).';
    }
  }

  Future<bool> loginWithGoogle({bool savePassword = false}) async {
    try {
      await _ensureGoogleInit();
      final account = await GoogleSignIn.instance.authenticate();
      final auth = account.authentication;
      final cred = GoogleAuthProvider.credential(idToken: auth.idToken);
      final res = await _auth.signInWithCredential(cred);
      final user = res.user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('email', user?.email ?? account.email);
      AnalyticsService.setUserId(user?.email ?? account.email);
      AnalyticsService.logEvent('login_google');
      state = AuthState(isLoggedIn: true, email: user?.email ?? account.email, isLoading: false, firebaseUser: user);
      if (savePassword) await SavedCredentials.save((user?.email ?? account.email).trim());
      return true;
    } on GoogleSignInException catch (e) {
      log('[AUTH] GoogleSignIn ERRO code=${e.code} desc=${e.description} details=${e.details}');
      return false;
    } on FirebaseAuthException catch (e) {
      log('[AUTH] FirebaseAuth Google ERRO code=${e.code} message=${e.message}');
      return false;
    } catch (e) {
      log('[AUTH] Google login ERRO generico: $e');
      return false;
    }
  }

  bool get usesPasswordAuth => _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ?? false;

  Future<String?> sendPasswordReset(String email) async {
    try {
      log('[AUTH] Enviando reset de senha: $email');
      await _auth.sendPasswordResetEmail(email: email.trim());
      AnalyticsService.logEvent('password_reset_sent');
      return null;
    } on FirebaseAuthException catch (e) {
      log('[AUTH] Reset de senha ERRO: ${e.code} - ${e.message}');
      return _firebaseAuthError(e.code);
    } catch (e) {
      return 'Sem conexão com a internet.';
    }
  }

  Future<String?> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) return 'Você precisa estar logado.';
    final email = user.email;
    if (email == null) return 'Não foi possível identificar a conta.';
    try {
      final cred = EmailAuthProvider.credential(email: email, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      log('[AUTH] Senha alterada para: $email');
      AnalyticsService.logEvent('password_changed');
      final saved = await SavedCredentials.read();
      if (saved != null && saved.email == email) {
        await SavedCredentials.save(email, password: newPassword);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      log('[AUTH] Alterar senha ERRO: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'wrong-password':
          return 'Senha atual incorreta.';
        case 'weak-password':
          return 'A nova senha deve ter pelo menos 6 caracteres.';
        case 'requires-recent-login':
          return 'Faça login novamente para alterar a senha.';
        default:
          return _firebaseAuthError(e.code);
      }
    } catch (e) {
      return 'Sem conexão com a internet.';
    }
  }

  Future<String?> deleteAccount(String? currentPassword) async {
    final user = _auth.currentUser;
    if (user == null) return 'Você precisa estar logado.';
    final email = user.email;
    try {
      if (currentPassword != null && currentPassword.isNotEmpty && email != null) {
        await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: email, password: currentPassword));
      }
      await user.delete();
      log('[AUTH] Conta excluída: $email');
    } on FirebaseAuthException catch (e) {
      log('[AUTH] Excluir conta ERRO: ${e.code} - ${e.message}');
      if (e.code == 'requires-recent-login') {
        return 'Por segurança, faça logout e entre novamente antes de excluir a conta.';
      }
      if (e.code == 'wrong-password') return 'Senha atual incorreta.';
      return _firebaseAuthError(e.code);
    } catch (e) {
      return 'Sem conexão com a internet.';
    }
    try { await Hive.box('mamba_box').clear(); } catch (_) {}
    try { await Hive.box('mamba_settings').clear(); } catch (_) {}
    try { (await SharedPreferences.getInstance()).clear(); } catch (_) {}
    await SavedCredentials.clear();
    AnalyticsService.logEvent('account_deleted');
    AnalyticsService.setUserId(null);
    state = const AuthState(isLoggedIn: false, email: null, isLoading: false);
    return null;
  }

  Future<void> logout() async {
    try { await GoogleSignIn.instance.signOut(); } catch (_) {}
    try { await _auth.signOut(); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    AnalyticsService.logEvent('logout');
    AnalyticsService.setUserId(null);
    state = const AuthState(isLoggedIn: false, email: null, isLoading: false);
  }
}
