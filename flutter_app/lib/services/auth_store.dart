import 'dart:convert';

import '../models/service_models.dart';
import 'secure_storage.dart';

abstract interface class AuthStore {
  Future<AuthSession?> loadSession();

  Future<void> saveSession(AuthSession session);

  Future<void> clearSession();
}

class SecureAuthStore implements AuthStore {
  static const _sessionKey = 'new_energy_auth_session_v1';

  @override
  Future<AuthSession?> loadSession() async {
    final raw = await appSecureStorage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final session = AuthSession.fromJson(decoded);
      if (session.token.isEmpty || session.user.id <= 0) return null;
      return session;
    } on FormatException {
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> saveSession(AuthSession session) {
    return appSecureStorage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  @override
  Future<void> clearSession() {
    return appSecureStorage.delete(key: _sessionKey);
  }
}

class MemoryAuthStore implements AuthStore {
  MemoryAuthStore([this.session]);

  AuthSession? session;

  @override
  Future<AuthSession?> loadSession() async => session;

  @override
  Future<void> saveSession(AuthSession session) async {
    this.session = session;
  }

  @override
  Future<void> clearSession() async {
    session = null;
  }
}
