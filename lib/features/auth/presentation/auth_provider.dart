import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

class AuthState {
  final bool isLoggedIn;
  final String? email;
  final bool isLoading;
  const AuthState({this.isLoggedIn = false, this.email, this.isLoading = true});
  AuthState copyWith({bool? isLoggedIn, String? email, bool? isLoading}) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        email: email ?? this.email,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final logged = prefs.getBool('isLoggedIn') ?? false;
    final email = prefs.getString('email');
    state = AuthState(isLoggedIn: logged, email: email, isLoading: false);
  }

  Future<bool> login(String email, String password) async {
    if (email.isEmpty || !email.contains('@') || password.length < 3) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('email', email);
    state = AuthState(isLoggedIn: true, email: email, isLoading: false);
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const AuthState(isLoggedIn: false, email: null, isLoading: false);
  }
}
