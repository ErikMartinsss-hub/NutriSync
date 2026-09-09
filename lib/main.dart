import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('mamba_box');
  await Hive.openBox('mamba_settings');
  await NotificationService.init();
  await initializeDateFormatting('pt_BR', null);
  runApp(const ProviderScope(child: MambaApp()));
}
