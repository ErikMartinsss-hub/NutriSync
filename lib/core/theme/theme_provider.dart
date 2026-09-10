import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = Hive.box('mamba_settings').get('theme_mode') as String?;
      if (saved != null) {
        state = saved == 'light' ? ThemeMode.light : saved == 'dark' ? ThemeMode.dark : ThemeMode.system;
      }
    } catch (_) {}
  }

  Future<void> set(ThemeMode m) async {
    state = m;
    try {
      await Hive.box('mamba_settings').put('theme_mode', m.name);
    } catch (_) {}
  }
}