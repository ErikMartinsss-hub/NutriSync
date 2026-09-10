import 'package:firebase_analytics/firebase_analytics.dart';

/// Wrapper para Firebase Analytics. Todas as chamadas sao protegidas:
/// em debug/test (sem plugin) ou sem rede, nunca crasham o app.
class AnalyticsService {
  static FirebaseAnalytics? _instance;

  static FirebaseAnalytics get _analytics => _instance ??= FirebaseAnalytics.instance;

  static Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
    } catch (_) {}
  }

  static Future<void> logScreen(String name) async {
    try {
      await _analytics.logScreenView(screenName: name);
    } catch (_) {}
  }

  static Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (_) {}
  }
}