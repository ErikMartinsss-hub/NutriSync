import 'package:hive_ce/hive.dart';

class StorageService {
  static late Box _box;
  static late Box _settingsBox;

  static Future<void> init() async {
    _box = await Hive.openBox('mamba_box');
    _settingsBox = await Hive.openBox('mamba_settings');
  }

  static Box get box => _box;
  static Box get settingsBox => _settingsBox;

  static T? get<T>(String key) => _box.get(key) as T?;
  static Future<void> put(String key, dynamic value) => _box.put(key, value);
  static Future<void> delete(String key) => _box.delete(key);
}
