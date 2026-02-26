import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session/session.dart';
import 'api_config.dart';

class ApiClient {
  ApiClient(this.session);

  final Session session;

  Uri _u(String path, [Map<String, String>? q]) {
    final base = ApiConfig.baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: q);
  }

  Map<String, String> _headers({bool auth = false}) {
    final h = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (auth && session.token != null && session.token!.isNotEmpty) {
      h['Authorization'] = 'Bearer ${session.token}';
    }
    return h;
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool auth = false}) async {
    final res = await http.post(_u(path), headers: _headers(auth: auth), body: jsonEncode(body));
    return _handle(res);
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body, bool auth = false}) async {
    final res = await http.patch(_u(path), headers: _headers(auth: auth), body: body == null ? null : jsonEncode(body));
    return _handle(res);
  }

  Future<dynamic> get(String path, {Map<String, String>? query, bool auth = false}) async {
    final res = await http.get(_u(path, query), headers: _headers(auth: auth));
    return _handleAny(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    final any = _handleAny(res);
    if (any is Map<String, dynamic>) return any;
    throw ApiException(res.statusCode, 'Resposta inesperada');
  }

  dynamic _handleAny(http.Response res) {
    // Nem sempre a API devolve JSON (ex.: 404 "Cannot POST /...", HTML de proxy, etc.).
    // Se der FormatException, tratamos como texto para não quebrar a tela com erro de parse.
    final raw = utf8.decode(res.bodyBytes, allowMalformed: true);
    dynamic body;
    if (raw.trim().isEmpty) {
      body = null;
    } else {
      try {
        body = jsonDecode(raw);
      } on FormatException {
        body = raw;
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    final msg = (body is Map && body['message'] != null)
        ? (body['message'] is List ? (body['message'] as List).join(', ') : body['message'].toString())
        : (body is String && body.trim().isNotEmpty)
            ? _short(body)
            : 'Erro HTTP ${res.statusCode}';
    throw ApiException(res.statusCode, msg);
  }

  String _short(String s) {
    final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.length <= 200 ? t : '${t.substring(0, 200)}...';
  }
}

class ApiException implements Exception {
  ApiException(this.status, this.message);
  final int status;
  final String message;

  @override
  String toString() => 'ApiException($status): $message';
}