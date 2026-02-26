import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session extends ChangeNotifier {
  static const _kToken = 'bico_token';
  static const _kUserId = 'bico_user_id';
  static const _kRole = 'bico_role';
  static const _kName = 'bico_name';
  static const _kEmail = 'bico_email';

  bool _ready = false;

  String? token;
  String? userId;
  String? role; // client | provider
  String? name;
  String? email;

  bool get isReady => _ready;
  bool get isLoggedIn => token != null && token!.isNotEmpty;

  Future<void> load() async {
    // Never keep the app stuck on splash. If SharedPreferences fails to init
    // (common on misconfigured desktop builds), we still mark the session as
    // ready and fall back to "logged out".
    try {
      final sp = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      token = sp.getString(_kToken);
      userId = sp.getString(_kUserId);
      role = sp.getString(_kRole);
      name = sp.getString(_kName);
      email = sp.getString(_kEmail);
    } catch (e) {
      debugPrint('Session.load() failed: $e');
      // On Windows, SharedPreferences is backed by a JSON file. If it gets
      // corrupted, getInstance() can throw FormatException. We try to wipe the
      // store once and continue.
      try {
        await SharedPreferencesStorePlatform.instance.clear();
        final sp2 = await SharedPreferences.getInstance()
            .timeout(const Duration(seconds: 5));
        token = sp2.getString(_kToken);
        userId = sp2.getString(_kUserId);
        role = sp2.getString(_kRole);
        name = sp2.getString(_kName);
        email = sp2.getString(_kEmail);
      } catch (_) {
        token = null;
        userId = null;
        role = null;
        name = null;
        email = null;
      }
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> setAuth({
    required String tokenValue,
    required String userIdValue,
    required String roleValue,
    required String nameValue,
    required String emailValue,
  }) async {
    final sp = await SharedPreferences.getInstance();
    token = tokenValue;
    userId = userIdValue;
    role = roleValue;
    name = nameValue;
    email = emailValue;

    await sp.setString(_kToken, tokenValue);
    await sp.setString(_kUserId, userIdValue);
    await sp.setString(_kRole, roleValue);
    await sp.setString(_kName, nameValue);
    await sp.setString(_kEmail, emailValue);

    notifyListeners();
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kToken);
    await sp.remove(_kUserId);
    await sp.remove(_kRole);
    await sp.remove(_kName);
    await sp.remove(_kEmail);

    token = null;
    userId = null;
    role = null;
    name = null;
    email = null;

    notifyListeners();
  }
}