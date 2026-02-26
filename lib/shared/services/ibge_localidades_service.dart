import 'dart:convert';
import 'package:http/http.dart' as http;

class IbgeUf {
  final int id;
  final String sigla;
  final String nome;

  IbgeUf({required this.id, required this.sigla, required this.nome});

  factory IbgeUf.fromJson(Map<String, dynamic> j) =>
      IbgeUf(id: j['id'], sigla: j['sigla'], nome: j['nome']);
}

class IbgeMunicipio {
  final int id;
  final String nome;

  IbgeMunicipio({required this.id, required this.nome});

  factory IbgeMunicipio.fromJson(Map<String, dynamic> j) =>
      IbgeMunicipio(id: j['id'], nome: j['nome']);
}

class IbgeLocalidadesService {
  static const _base = 'https://servicodados.ibge.gov.br/api/v1/localidades';

  Future<List<IbgeUf>> getUfs() async {
    final uri = Uri.parse('$_base/estados?orderBy=nome');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('IBGE UFs falhou: ${res.statusCode}');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list.map(IbgeUf.fromJson).toList();
  }

  Future<List<IbgeMunicipio>> getMunicipiosByUf(String ufSigla) async {
    final uri = Uri.parse('$_base/estados/$ufSigla/municipios?orderBy=nome');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('IBGE Municípios falhou: ${res.statusCode}');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list.map(IbgeMunicipio.fromJson).toList();
  }
}