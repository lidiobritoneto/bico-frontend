import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Você pode sobrescrever em runtime/build com:
  ///   flutter run --dart-define=API_BASE_URL=https://SUA_API
  ///   flutter build windows --release --dart-define=API_BASE_URL=https://SUA_API
  ///
  /// Em RELEASE, por padrão usamos a API do Render.
  /// Em DEBUG, por padrão usamos localhost.
  static const String _defaultProd = 'https://bico-backend-ai99.onrender.com';
  static const String _defaultDev = 'http://localhost:3000';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kReleaseMode ? _defaultProd : _defaultDev,
  );
}
