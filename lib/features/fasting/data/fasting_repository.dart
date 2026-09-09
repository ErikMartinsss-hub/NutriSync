import 'package:hive/hive.dart';
import 'fasting_protocol.dart';
import 'fasting_session.dart';

class FastingRepository {
  final Box box;
  final String userId;
  FastingRepository(this.box, this.userId);

  late final String _currentKey = 'fasting_current_$userId';
  late final String _historyKey = 'fasting_history_$userId';
  late final String _protocolKey = 'fasting_protocol_$userId';
  late final String _customProtocolsKey = 'fasting_custom_protocols_$userId';

  FastingProtocol getSelectedProtocol() {
    try {
      final j = box.get(_protocolKey);
      if (j != null) return FastingProtocol.fromJson(Map<String, dynamic>.from(j as Map));
    } catch (_) {}
    return FastingProtocol.predefined[1]; // 16:8 default
  }

  Future<void> setSelectedProtocol(FastingProtocol p) async {
    await box.put(_protocolKey, p.toJson());
  }

  List<FastingProtocol> getCustomProtocols() {
    try {
      final list = box.get(_customProtocolsKey) as List?;
      if (list == null) return [];
      return list.map((e) => FastingProtocol.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addCustomProtocol(FastingProtocol p) async {
    final current = getCustomProtocols();
    current.add(p);
    await box.put(_customProtocolsKey, current.map((e) => e.toJson()).toList());
  }

  FastingSession? getCurrentSession() {
    try {
      final j = box.get(_currentKey);
      if (j == null) return null;
      return FastingSession.fromJson(Map<String, dynamic>.from(j as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCurrentSession(FastingSession? s) async {
    if (s == null) {
      await box.delete(_currentKey);
    } else {
      await box.put(_currentKey, s.toJson());
    }
  }

  List<FastingSession> getHistory() {
    try {
      final list = box.get(_historyKey) as List?;
      if (list == null) return [];
      return list.map((e) => FastingSession.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addToHistory(FastingSession s) async {
    final h = getHistory();
    h.insert(0, s);
    await box.put(_historyKey, h.map((e) => e.toJson()).toList());
  }

  Future<void> updateHistory(List<FastingSession> list) async {
    await box.put(_historyKey, list.map((e) => e.toJson()).toList());
  }
}
