import 'package:hive_flutter/hive_flutter.dart';

/// Feature flags com override local persistido em Hive.
/// Por padrao todas as flags sao habilitadas; desligar uma flag nao exige
/// mudanca de codigo, apenas `FeatureFlags.setEnabled('chave', false)`.
class FeatureFlags {
  static const Map<String, bool> defaults = {
    'taco_online_search': true,
  };

  static bool isEnabled(String key) {
    final override = _readOverride(key);
    if (override != null) return override;
    return defaults[key] ?? true;
  }

  static bool? _readOverride(String key) {
    try {
      return Hive.box('mamba_settings').get('flag_$key') as bool?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> setEnabled(String key, bool value) async {
    try {
      await Hive.box('mamba_settings').put('flag_$key', value);
    } catch (_) {}
  }

  static Future<void> reset(String key) async {
    try {
      await Hive.box('mamba_settings').delete('flag_$key');
    } catch (_) {}
  }
}