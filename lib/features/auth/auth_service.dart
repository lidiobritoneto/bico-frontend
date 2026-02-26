import '../../core/api/api_client.dart';
import '../../core/session/session.dart';

class AuthService {
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida do servidor (não é JSON).');
    }

    final token = data['token'];
    final user = data['user'] ?? data['me'];

    if (token is! String || token.isEmpty) {
      throw Exception('Servidor não retornou token.');
    }
    if (user is! Map<String, dynamic>) {
      throw Exception('Servidor não retornou usuário.');
    }

    await Session.save(newToken: token, newMe: user);
  }
}