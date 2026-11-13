// =============================================
// session.dart - Guarda o token de login no celular
// =============================================
// O token fica no armazenamento seguro do sistema (Keystore no Android,
// Keychain no iOS), nunca em texto simples nas preferências.
// =============================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStore {
  static const _tokenKey = 'session_token';
  static const _storage = FlutterSecureStorage();

  static Future<String?> loadToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      // Armazenamento indisponível ou corrompido: segue sem login.
      return null;
    }
  }

  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      // Sem armazenamento seguro a sessão vale só enquanto o app estiver aberto.
    }
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {
      // Nada a apagar.
    }
  }
}
