import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyToken = 'auth_token';
  static const _keyEmail = 'auth_email';
  static const _keySkipped = 'auth_skipped';

  String? _token;
  String? email;
  bool authSkipped = false;

  String? get token => _token;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get canUseApp => isLoggedIn || authSkipped;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString(_keyToken);
    email = p.getString(_keyEmail);
    authSkipped = p.getBool(_keySkipped) ?? false;
  }

  Future<void> skipLogin() async {
    authSkipped = true;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keySkipped, true);
  }

  Future<void> save(String token, String userEmail) async {
    _token = token;
    email = userEmail;
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyToken, token);
    await p.setString(_keyEmail, userEmail);
  }

  Future<void> clear() async {
    _token = null;
    email = null;
    authSkipped = false;
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyToken);
    await p.remove(_keyEmail);
    await p.remove(_keySkipped);
  }
}
