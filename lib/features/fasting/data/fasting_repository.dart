import 'package:hive_ce/hive.dart';
import 'fasting_protocol.dart';
import 'fasting_session.dart';

class FastingRepository {
  final Box box;
  FastingRepository(this.box);

  static const _currentKey = 'fasting_current';
  static const _historyKey = 'fasting_history';
  static const _protocolKey = 'fasting_protocol';
  static const _customProtocolsKey = 'fasting_custom_protocols';

  FastingProtocol getSelectedProtocol() {
    final j = box.get(_protocolKey);
    if (j != null) return FastingProtocol.fromJson(Map<String, dynamic>.from(j));
    return FastingProtocol.predefined[1]; // 16:8 default
  }

  Future<void> setSelectedProtocol(FastingProtocol p) async {
    await box.put(_protocolKey, p.toJson());
  }

  List<FastingProtocol> getCustomProtocols() {
    final list = box.get(_customProtocolsKey) as List?;
    if (list == null) return [];
    return list.map((e) => FastingProtocol.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> addCustomProtocol(FastingProtocol p) async {
    final current = getCustomProtocols();
    current.add(p);
    await box.put(_customProtocolsKey, current.map((e) => e.toJson()).toList());
  }

  FastingSession? getCurrentSession() {
    final j = box.get(_currentKey);
    if (j == null) return null;
    return FastingSession.fromJson(Map<String, dynamic>.from(j));
  }

  Future<void> saveCurrentSession(FastingSession? s) async {
    if (s == null) {
      await box.delete(_currentKey);
    } else {
      await box.put(_currentKey, s.toJson());
    }
  }

  List<FastingSession> getHistory() {
    final list = box.get(_historyKey) as List?;
    if (list == null) return [];
    return list.map((e) => FastingSession.fromJson(Map<String, dynamic>.from(e))).toList();
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
