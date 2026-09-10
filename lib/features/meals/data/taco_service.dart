import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/feature_flags.dart';

class TacoFood {
  final int id;
  final String codigo;
  final String nome;
  final String categoria;
  final String descricaoPreparacao;
  final String energiaKcalRaw;
  final String proteinaGRaw;
  final String carboGRaw;
  final String lipideosGRaw;
  final String fibraGRaw;

  TacoFood({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.categoria,
    required this.descricaoPreparacao,
    required this.energiaKcalRaw,
    required this.proteinaGRaw,
    required this.carboGRaw,
    required this.lipideosGRaw,
    required this.fibraGRaw,
  });

  double _parse(String v) {
    if (v.trim() == '-' || v.trim().isEmpty) return 0;
    return double.tryParse(v.replaceAll(',', '.')) ?? 0;
  }

  double get kcalPer100g => _parse(energiaKcalRaw);
  double get proteinaPer100g => _parse(proteinaGRaw);
  double get carboPer100g => _parse(carboGRaw);
  double get lipideosPer100g => _parse(lipideosGRaw);

  int kcalFor(double gramas) => (kcalPer100g * gramas / 100).round();
  int kcalForUnidades(int unidades, {double gramasPorUnidade = 50}) => kcalFor(unidades * gramasPorUnidade);

  factory TacoFood.fromJson(Map<String, dynamic> j) => TacoFood(
        id: j['id'] ?? 0,
        codigo: j['Codigo']?.toString() ?? '',
        nome: (j['descricacao_do_alimento'] ?? j['descricao_do_alimento'] ?? '').toString(),
        categoria: (j['Categoria'] ?? '').toString(),
        descricaoPreparacao: (j['descricao_da_preparacao'] ?? '').toString(),
        energiaKcalRaw: (j['Energia_kcal'] ?? '0').toString(),
        proteinaGRaw: (j['Proteina_g'] ?? '0').toString(),
        carboGRaw: (j['Carboi_drato_g'] ?? j['Carboidrato_g'] ?? '0').toString(),
        lipideosGRaw: (j['Lipidios_totais_g'] ?? '0').toString(),
        fibraGRaw: (j['Fibra_alimentar_total_g'] ?? '0').toString(),
      );
}

class TacoService {
  static const _baseUrl = 'https://mamba-taco-api.onrender.com/api/alimentos/ibge';
  static const _fallbackUrl = 'http://10.0.2.2:8000/api/alimentos/ibge';

  static List<TacoFood>? _cache;
  static DateTime? _cacheTime;
  static bool _fetching = false;

  static final List<TacoFood> _mock = [
    TacoFood(id: 1, codigo: '1', nome: 'Pão francês', categoria: 'Panificados', descricaoPreparacao: 'Não se aplica', energiaKcalRaw: '300', proteinaGRaw: '8', carboGRaw: '58', lipideosGRaw: '3', fibraGRaw: '2'),
    TacoFood(id: 2, codigo: '2', nome: 'Ovo de galinha cozido', categoria: 'Ovos', descricaoPreparacao: 'Cozido', energiaKcalRaw: '146', proteinaGRaw: '13', carboGRaw: '1', lipideosGRaw: '9', fibraGRaw: '0'),
    TacoFood(id: 3, codigo: '3', nome: 'Arroz branco cozido', categoria: 'Cereais', descricaoPreparacao: 'Cozido', energiaKcalRaw: '128', proteinaGRaw: '2.5', carboGRaw: '28', lipideosGRaw: '0.2', fibraGRaw: '1.6'),
    TacoFood(id: 4, codigo: '4', nome: 'Feijão carioca cozido', categoria: 'Leguminosas', descricaoPreparacao: 'Cozido', energiaKcalRaw: '76', proteinaGRaw: '4.8', carboGRaw: '13', lipideosGRaw: '0.5', fibraGRaw: '8.5'),
    TacoFood(id: 5, codigo: '5', nome: 'Peito de frango grelhado', categoria: 'Carnes', descricaoPreparacao: 'Grelhado', energiaKcalRaw: '159', proteinaGRaw: '32', carboGRaw: '0', lipideosGRaw: '3', fibraGRaw: '0'),
  ];

  /// Pre-aquece o cache em background — chamar no startup do app.
  static void preload() {
    if (_cache != null || _fetching) return;
    fetchAll();
  }

  static Future<List<TacoFood>> fetchAll() async {
    if (_cache != null && _cacheTime != null && DateTime.now().difference(_cacheTime!).inMinutes < 10) {
      return _cache!;
    }
    if (!FeatureFlags.isEnabled('taco_online_search')) {
      return _mock;
    }
    if (_fetching) return _mock;
    _fetching = true;
    try {
      final res = await http.get(Uri.parse(_baseUrl)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body) as List;
        final list = data.map((e) => TacoFood.fromJson(e as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) {
          _cache = list;
          _cacheTime = DateTime.now();
          return list;
        }
      }
      final res2 = await http.get(Uri.parse(_fallbackUrl)).timeout(const Duration(seconds: 2));
      if (res2.statusCode == 200) {
        final List data2 = jsonDecode(res2.body) as List;
        final list2 = data2.map((e) => TacoFood.fromJson(e as Map<String, dynamic>)).toList();
        if (list2.isNotEmpty) {
          _cache = list2;
          _cacheTime = DateTime.now();
          return list2;
        }
      }
      return _mock;
    } catch (_) {
      return _mock;
    } finally {
      _fetching = false;
    }
  }

  static Future<List<TacoFood>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final all = await fetchAll();
    final q = query.toLowerCase();
    final filtered = all.where((f) => f.nome.toLowerCase().contains(q) || f.categoria.toLowerCase().contains(q)).toList();
    filtered.sort((a, b) {
      final aStarts = a.nome.toLowerCase().startsWith(q) ? 0 : 1;
      final bStarts = b.nome.toLowerCase().startsWith(q) ? 0 : 1;
      if (aStarts != bStarts) return aStarts - bStarts;
      return a.nome.compareTo(b.nome);
    });
    return filtered.take(20).toList();
  }
}