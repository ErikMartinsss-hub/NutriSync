import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mostrar erro na tela em vez de branco (release também)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  ErrorWidget.builder = (details) {
    return Material(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              const Text('Ops! Algo deu errado', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              Text(details.exceptionAsString(), style: const TextStyle(fontSize: 12, color: Colors.black87)),
              const SizedBox(height: 8),
              Text(details.stack.toString().substring(0, 800), style: const TextStyle(fontSize: 10, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  };

  // Firebase
  try {
    await Firebase.initializeApp();
  } catch (e, st) {
    debugPrint('Firebase init error: $e $st');
  }
  // Init robusto — nunca deve crashar o app
  try {
    await Hive.initFlutter();
    await Hive.openBox('mamba_box');
    await Hive.openBox('mamba_settings');
  } catch (e, st) {
    debugPrint('Hive init error: $e $st');
  }
  try {
    await NotificationService.init();
  } catch (e, st) {
    debugPrint('Notification init error: $e $st');
  }
  try {
    await initializeDateFormatting('pt_BR', null);
  } catch (e) {
    debugPrint('Intl init error: $e');
  }

  runZonedGuarded(() {
    runApp(const ProviderScope(child: NutriSyncApp()));
  }, (e, st) {
    debugPrint('Uncaught zone error: $e $st');
  });
}
