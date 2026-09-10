import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavedCredentials {
  static const _storage = FlutterSecureStorage();
  static const _kEmail = 'saved_email';
  static const _kPass = 'saved_password';

  static Future<void> save(String email, {String password = ''}) async {
    await _storage.write(key: _kEmail, value: email);
    await _storage.write(key: _kPass, value: password);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kPass);
  }

  static Future<bool> hasSaved() async {
    final email = await _storage.read(key: _kEmail);
    return email != null && email.isNotEmpty;
  }

  static Future<({String email, String password})?> read() async {
    final email = await _storage.read(key: _kEmail);
    final pass = await _storage.read(key: _kPass) ?? '';
    if (email == null || email.isEmpty) return null;
    return (email: email, password: pass);
  }
}