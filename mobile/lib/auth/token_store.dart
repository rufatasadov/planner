import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../prefs.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore(preferences: ref.watch(sharedPreferencesProvider));
});

class TokenStore {
  TokenStore({FlutterSecureStorage? storage, SharedPreferences? preferences})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          ),
      _preferences = preferences;

  static const _tokenKey = 'token';
  static const _userKey = 'user';

  final FlutterSecureStorage _storage;
  final SharedPreferences? _preferences;

  Future<String?> readToken() async {
    final secure = await _readSecure(_tokenKey);
    if (secure != null && secure.isNotEmpty) return secure;
    final saved = _preferences?.getString(_tokenKey);
    return (saved == null || saved.isEmpty) ? null : saved;
  }

  Future<AppUser?> readUser() async {
    final raw =
        await _readSecure(_userKey) ?? _preferences?.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return AppUser.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String token, AppUser user) async {
    final encoded = jsonEncode(user.toJson());
    await _writeSecure(_tokenKey, token);
    await _writeSecure(_userKey, encoded);
    await _preferences?.setString(_tokenKey, token);
    await _preferences?.setString(_userKey, encoded);
  }

  Future<void> saveUser(AppUser user) async {
    final encoded = jsonEncode(user.toJson());
    await _writeSecure(_userKey, encoded);
    await _preferences?.setString(_userKey, encoded);
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    } on PlatformException {
      // The preference copy is cleared below.
    }
    await _preferences?.remove(_tokenKey);
    await _preferences?.remove(_userKey);
  }

  Future<String?> _readSecure(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException {
      return null;
    }
  }

  Future<void> _writeSecure(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException {
      // SharedPreferences keeps the session if the keychain write fails.
    }
  }
}
